#!/usr/bin/perl
#
# Copyright (c) 2010-2011 Mathieu Roy <yeupou--gnu.org>
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

# Script for transmission 2.x.
# (for 1.x, the first version of the script is still available on my blog)

use strict "vars";
use Fcntl ':flock';
use POSIX qw(strftime);
use File::Basename;

my $user = "debian-transmission";
my $watchdir = "/server/torrent/watch";
my $bin = "/usr/bin/transmission-remote"; # Too noisy, so we cannot use system
my $debug = 0;

# ~/watch syntax :
#    $file.torrent = torrent to be added
#    $realfile.trs = being processed (delete it to remove the torrent) 
#    $realfile.trs- = to be paused
#    $realfile.trs+ = (supposedly) completed
#    all- = pause all 

# check if we are running with torrent user (not with getlogin() because
# su often mess it up)
die "This should not be started by ".(getpwuid($<))[0]." but $user instead. Exit" unless ((getpwuid($<))[0] eq $user);

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
    my $realfile;
    if ($file =~ /^(.*)(\.[^.]*)$/) { $suffix = $2; $realfile = $1; }
    next unless $suffix && $realfile;
    
    # new .torrent file
    if ($suffix eq ".torrent") {
	push(@to_be_added, $file);
	next;
    }

    # if we get here, we have a .trs file (contains infos about the torrent)
  
    # being processed or should be started
    if ($suffix eq ".trs") {
	$marked_as_being_processed{$realfile} = 1;
	next;
    }
    # to be paused
    if ($suffix eq ".trs-") {
	$to_be_paused{$realfile} = 1;
	next;
    }
}
closedir(WATCH);


# add new torrents
my %added;
foreach my $torrent (@to_be_added) {
    print "$bin --add $watchdir/$torrent --start\n" if $debug;
    `$bin --add $watchdir/$torrent --start >/dev/null`;

    # get the ID (should be the latest)
    my $id;
    open(LIST, "$bin --list |");
    while (<LIST>) {
	if (/^\s*(\d*)\*?\s*/) {
	    $id = $1 if $id < $1;
	}
    }
    $added{$id} = 1;
}
unlink(@to_be_added);

# update torrentsbeings processed,
#  start/pause/remove if need be
my %being_processed;
my $count;
open(LIST, "$bin --list |");
while (<LIST>) {

    # output format: 
    # ID  Done  Have  ETA  Up  Down  Ratio  Status  Name
    my ($id, $percent, $file);
    if (/^\s*(\d*)\*?\s*(\d*\%)\s*/) { $id = $1; $percent = $2; }
    if (/\s*([^\s]*)$/) { $file = $1; }
    print "ID:$id FILE:$file PERCENT:$percent => $_\n" if $debug;

    # skip if missing info
    next unless $id and $file;     
    
    # finished
    if ($percent eq "100%") {
	print "mv $file.hash $file.hash+\n" if $debug;
	print LOG strftime "%c - completed $file\n", localtime;
	# do not bother removing the torrent, done below
	rename("$watchdir/$file.trs",
	       "$watchdir/$file.trs+");
	
	# warn (it should send a mail, if cron is properly configured)
	print "Hello,\n\nI assume the following torrent was completed:\n\n" 
	    unless $count;
	print "$file (id: $id)\n";
	$count++;

    }


    # should be paused
    if (exists($to_be_paused{$file})) {
	print "$bin -t $id --stop\n" if $debug;
	print LOG strftime "%c - pause $file\n", localtime;
	`$bin --torrent $id --stop >/dev/null`;
	next;
    }
    
    # should be removed 
    unless (-e "$watchdir/$file.trs" or $added{$id}) {
	print "$bin -t $id --remove (no $file.trs)\n" if $debug;
	print LOG strftime "%c - remove $file\n", localtime;
	`$bin --torrent $id --remove >/dev/null`;
	next;
    }

    # any other case, ask to start it (dont log it, we do it everytime)
    print "$bin -t $id --start\n" if $debug and !$pause_all;
    `$bin --torrent $id --start >/dev/null` unless $pause_all;
    $being_processed{$file} = 1;

    # for any processed file, update the info file 
    open(TRSFILE, "> $watchdir/$file.trs");
    open(INFO, "$bin --torrent $id --info |");
    while (<INFO>) { last if /^PIECES/; print TRSFILE $_; }
    close(INFO);
    close(TRSFILE); 

}
close(LIST);

# update status info after everything was done
open(STATUSFILE, "> $watchdir/status");
print STATUSFILE "Last run: ", strftime "%c\n\n", localtime;
open(LIST, "$bin --list |");
while (<LIST>) { print STATUSFILE $_; }
close(LIST);
open(STATS, "$bin --session-stats |");
while (<STATS>) { last if /^TOTAL/; print STATUSFILE $_; }
close(STATS);
close(STATUSFILE);

unless ($readme_exists) {
    open(README, "> $watchdir/README");
    print README "watch syntax :\n \$file.torrent = to be added\n \$realfile.trs =  being processed (delete it to remove the torrent)\n \$realfile.trs- = to be paused\n \$realfile.trs+ = (supposedly) completed\n all- = pause all\n";
    close(README);
}


close(LOG);
# EOF
