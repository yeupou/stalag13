#!/usr/bin/perl
#
# Copyright (c) 2010 Mathieu Roy <yeupou--gnu.org>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#   USA

use strict "vars";
use Fcntl ':flock';
use POSIX qw(strftime);
use File::Basename;

my $watchdir = "/home/torrent/watch";
my $bin = "/usr/bin/transmission-remote";
my $debug = 0;

# ~/watch syntax :
#    $file.torrent = torrent to be added
#    $realfile.hash = being processed (delete it to remove the torrent) 
#    $realfile.hash- = to be paused
#    $realfile.hash+ = (supposedly) completed
#    all- = pause all 

# check if we are running with torrent user (not with getlogin() because
# su often mess it up)
die "This should not be started by ".(getpwuid($<))[0]." but torrent instead. Exit" unless ((getpwuid($<))[0] eq 'torrent');

# enter ~/watch
chdir($watchdir) or die "Unable to enter $watchdir. Exit";

# silently forbid concurrent runs
# (http://perl.plover.com/yak/flock/samples/slide006.html)
open(LOCK, "< $0") or die "Failed to ask lock. Exit";
flock(LOCK, LOCK_EX | LOCK_NB) or exit;

# open log
open(LOG, ">> $watchdir/log");

# check whether transmission-daemon is up
my $isup = 0;
opendir(PROC, "/proc");
while (defined(my $pid = readdir(PROC))) {
    # not a process if not a directory
    next unless -d "/proc/$pid";
    # not a process if not containing cmdline
    next unless -e "/proc/$pid/cmdline";
    # look out for transmission-daemon
    open(PID, "< /proc/$pid/cmdline");
    while (<PID>) {
	# with or without path
	next unless m/^transmission-daemon/ or m/^\/usr\/bin\/transmission-daemon/;
	$isup = 1;
	last;
    }
    close(PID);
}
closedir(PROC);
unless ($isup) {
    unless (-e "$watchdir/.down") {
	# send warning only once (dont want more than one mail to be sent)
	system("/usr/bin/touch", "$watchdir/.down");
	print LOG strftime "%c - transmission-daemon appears to be dead\n", localtime;
	die "transmission-daemon appears to be dead. Exit";
    }
    # otherwise, silently exit
    exit;
}
# warn if back online after failure to run
if (-e "$watchdir/.down") {
    print "transmission-daemon is back on line, resuming watch.\n";
    print LOG strftime "%c - transmission-daemon is back on line, resuming watch\n", localtime;
    unlink("$watchdir/.down");
}

# examine ~/watch
my $pause_all = 0;
my $readme_exists = 0;
my @to_be_added;
my %to_be_paused;
my %marked_as_being_processed;

opendir(WATCH, $watchdir);
while (defined(my $file = readdir(WATCH))) {
    next if ($file eq "." or
	     $file eq "..");
    
    # check whether README explaining watch syntax exists
    $readme_exists = 1 if $file eq "README";
    # check whether pause all is required
    $pause_all = 1 if $file eq "all-";

    next if ($file eq "README" or
	     $file eq "all-" or
	     $file eq "status" or
	     $file eq "log");

    # find out suffix, ignore file if none found
    my $suffix = 0;
    $suffix = $1 if $file =~ /^.*(\.[^.]*)$/;
    next unless $suffix;
    
    # new .torrent file
    if ($suffix eq ".torrent") {
	push(@to_be_added, $file);
	next;
    }

    # if we get here, we have .hash file that contains a hash
    my $hash;
    open(HASHFILE, "< $watchdir/$file");
    while(<HASHFILE>) {
	# should only contain one line
	$hash = $_;
	last;
    }
    close(HASHFILE);
    
    # marked as being processed
    if ($suffix eq ".hash") {
	$marked_as_being_processed{$hash} = $file;
	next;
    }
    # to be paused
    if ($suffix eq ".hash-") {
	$to_be_paused{$hash} = $file;
	next;
    }
}
closedir(WATCH);

# update hashes of torrent beings processed,
#  start/pause/remove if need be
my %being_processed;
open(INFO, "$bin --info |");
while (<INFO>) {
    # output format: $hash $file
    my ($hash, $file);
    if (/^([^\s]*)\s(.*)$/) { $hash = $1; $file = $2; }

    # should be paused
    if (exists($to_be_paused{$hash})) {
	print "$bin --stop $hash\n" if $debug;
	print LOG strftime "%c - pause $file\n", localtime;
	system($bin,
	       "--stop",
	       $hash);
	next;
    }
    
    # should be removed 
    unless (-e "$watchdir/$file.hash") {
	print "$bin --remove $hash\n" if $debug;
	print LOG strftime "%c - remove $file\n", localtime;
	system($bin,
	       "--remove",
	       $hash);
	next;
    }

    # any other case, ask to start it (dont log it, we do it everytime)
    print "$bin --start $hash\n" if $debug and !$pause_all;
    system($bin,
	   "--start",
	   $hash)
	unless $pause_all;
    $being_processed{$hash} = $file;
}
close(INFO);


# add new torrents
foreach my $torrent (@to_be_added) {
    print "$bin --add $watchdir/$torrent\n" if $debug;
    system($bin,
	   "--add",
	   "$watchdir/$torrent");
}
unlink(@to_be_added);
open(INFO, "$bin --info |");
while (<INFO>) {
    # output format: $hash $file
    my ($hash, $file);
    if (/^([^\s]*)\s(.*)$/) { $hash = $1; $file = $2; }

    # create the hashfile for the newly added torrents
    next if -e "$watchdir/$file.hash+";
    next if -e "$watchdir/$file.hash-";
    next if -e "$watchdir/$file.hash";
    print "echo $hash > $watchdir/$file.hash\n" if $debug;
    print LOG strftime "%c - add $file\n", localtime;
    open(HASHFILE, "> $watchdir/$file.hash");
    print HASHFILE $hash;
    close(HASHFILE); 

    # start them
    print "$bin --start $hash\n" if $debug and !$pause_all;
    print LOG strftime "%c - start $file\n", localtime;
    system($bin,
	   "--start",
	   $hash)
	unless $pause_all;
    $being_processed{$hash} = $file;
}
close(INFO);


# Update/check status, warn of finished jobs and add README if necessary
# (fix send mail when finished)
open(STATUS, "$bin --list |");
open(STATUSFILE, "> $watchdir/status");
print STATUSFILE "Last run: ", strftime "%c\n\n", localtime;
my $count = 0;
while (<STATUS>) {
    # check if completed at 100%
    my ($file, $percent);
    if (/^(.*)\s\(.*\s.?iB\)\s\-\s(\d*\%)\s/) { $file = $1 ; $percent = $2; } 

    if ($percent eq "100%") {
	print "mv $file.hash $file.hash+\n" if $debug;
	print LOG strftime "%c - completed $file\n", localtime;
	# do not bother removing the torrent, it will be done 
	# during next run
	rename("$watchdir/$file.hash",
	       "$watchdir/$file.hash+");
	
	# warn (it should send a mail, if cron is properly configured)
	print "Hello,\n\nI assume the following torrent was completed:\n\n" 
	    unless $count;
	print $_."\n";
	$count++;
    }

    # updated status file with an extra line break 
    print STATUSFILE $_."\n";
}
close(STATUS);
close(STATUSFILE);

unless ($readme_exists) {
    open(README, "> $watchdir/README");
    print README "watch syntax :\n \$file.torrent = to be added\n \$realfile.hash =  being processed (delete it to remove the torrent)\n \$realfile.hash- = to be paused\n \$realfile.hash+ = (supposedly) completed\n all- = pause all\n";
    close(README);
}





# cleanups
# (remove hashes of torrents removed by any other mean, etc)
while (my($hash, $file) = each (%marked_as_being_processed)) {
    next if exists($being_processed{$hash});
    print "rm $watchdir/$file\n" if $debug;
    print LOG strftime "%c - [cleanup] remove $file\n", localtime;
    unlink("$watchdir/$file");
}

close(LOG);
# EOF
