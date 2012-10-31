#!/usr/bin/perl
#
# Copyright (c) 2010-2012 Mathieu Roy <yeupou--gnu.org>
#                   http://yeupou.wordpress.com
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
use Date::Parse;

my $user = "debian-transmission";
my $watchdir = "/home/torrent/watch";
my $bin = "/usr/bin/transmission-remote"; # Too noisy, so we cannot use system
my $debug = 1;

# ~/watch syntax :
#    $file.torrent = torrent to be added
#    $YMMDD-$id-$realfile.trs = being processed (delete it to remove the torrent) 
#    $YMMDD-$id-$realfile.trs- = to be paused
#    $YMMDD-$id-$realfile.trs+ = (supposedly) completed
#    all- = use alt-speed (even pause) 

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
        # update status info
	open(STATUSFILE, "> $watchdir/status");
	print STATUSFILE "transmission-daemon appeared to be dead starting ", strftime "%c\n\n", localtime;
	close(STATUSFILE);
	# die here, or silently exits if we have reason to believe we are
	# just doing the weekly blocklists upgrade
	exit if (-e "$watchdir/.upgradingblocklists");
	die "transmission-daemon appears to be dead. Exit";
    }
    # otherwise, silently exit
    exit;
}
# warn if back online after failure to run, keep it in mind because
# later well have to make sure that a .trs exists for any active torrent
# (despite ID changes)
my $justwokeup = 0;
if (-e "$watchdir/.down") {
    # stays silent if we are doing weekly blocklists upgrade
    print "transmission-daemon is back on line, resuming watch.\n"
	unless (-e "$watchdir/.upgradingblocklists");
    print LOG strftime "%c - transmission-daemon is back on line, resuming watch\n", localtime;
    unlink("$watchdir/.down", "$watchdir/.upgradingblocklists");
    $justwokeup = 1;
}


# examine ~/watch
my $pause_all = 0;
my $readme_exists = 0;
my @to_be_added;

opendir(WATCH, $watchdir);
while (defined(my $file = readdir(WATCH))) {
    next if ($file eq "." or
	     $file eq "..");
    
    # check whether README explaining watch syntax exists
    $readme_exists = 1 if $file eq "README";
    # check whether pause all is required
    $pause_all = 1 if $file eq "all-";

    # find out suffix, ignore file if none found
    my $suffix = 0;
    my $name;
    if ($file =~ /^(.*)(\.[^.]*)$/) { $suffix = $2; $name = $1; }
    next unless $suffix && $name;
    
    # new .torrent file
    if ($suffix eq ".torrent") {
	push(@to_be_added, $file);
	next;
    }

    # Note:
    # Previously, at this point,  we looked for .trs, .trs-, etc here to
    # determine what  we had to do later with. 
    # Actually, considering how basic this script is
    # it's faster to use simple tests below than filling hashes for a single
    # usage anyway.
}
closedir(WATCH);


# set to slowdown/pause (use --alt-speed or turtle speed)
if ($pause_all) {
    # set only once
    unless (-e "$watchdir/.slow") {
	print "$bin --alt-speed\n" if $debug;
	print LOG strftime "%c - use turtle speed from now on\n", localtime; 
	`$bin --alt-speed >/dev/null`;
	system("/usr/bin/touch", "$watchdir/.slow");
    }
} else {
    # reset only once
    if (-e "$watchdir/.slow") {
	print "$bin --no-alt-speed\n" if $debug;
	`$bin --no-alt-speed >/dev/null`;
	print LOG strftime "%c - back to normal speed from now on\n", localtime;
	unlink("$watchdir/.slow");
    }
}


# add new torrents
my %added;
foreach my $torrent (@to_be_added) {
    print "$bin --add $watchdir/$torrent --start\n" if $debug;
    `$bin --add "$watchdir/$torrent" --start >/dev/null`;

    # get the ID (should be the latest)
    my $id;
    open(LIST, "$bin --list |");
    while (<LIST>) {
	if (/^\s*(\d*)\*?\s*/) {
	    $id = $1 if $id < $1;
	}
    }
    $added{$id} = 1;
    print LOG strftime "%c - add $torrent (#$id)\n", localtime; 
}
unlink(@to_be_added);

# update torrents beings processed,
#  start/pause/remove if need be
my $count;
open(LIST, "$bin --list |");
while (<LIST>) {

    # output format: 
    # ID  Done  Have  ETA  Up  Down  Ratio  Status  Name
    my ($id, $percent, $name, $date);
    if (/^\s*(\d*)\*?\s*(\d*\%)\s*/) { $id = $1; $percent = $2; }

    # silently skip if missing info, 
    # it means it's an informative/blank line
    next unless $id;
    
    # obtain info that cannot be guessed
    open(INFO, "$bin --torrent $id --info |");
    while (<INFO>) { 
	if (/\s*Name\:\s*(.*)$/) { $name = $1; }
	if (/\s*Date added\:\s*(.*)$/) { $date = $1; }
    }
    close(INFO);

    print "ID:$id NAME:$name PERCENT:$percent DATE:$date\n" if $debug;

    # skip if still missing info
    unless ($name and $date) {
	print "we skipped #$id because we were unable to find the following: name = $name ; date = $date ;\n";
	print LOG strftime "%c - WARNING: we skipped #$id because we were unable to find the following: name = $name ; date = $date ;\n", localtime;
	next;
    }

    # convert the date to YMMDD
    my ($ss,$mm,$hh,$day,$month,$year,$zone) = strptime($date); 
    $date = substr((1900+$year),-1,1).($month+1).$day;

    # determine the trs filename 
    my $file = "$date-$id-$name";
    print "FILE:$file\n" if $debug;
    
    # finished
    if ($percent eq "100%") {
	print "mv $file.hash $file.hash+\n" if $debug;
	print LOG strftime "%c - completed $name (#$id)\n", localtime;
	# do not bother removing the torrent, done below
	rename("$watchdir/$file.trs",
	       "$watchdir/$file.trs+");
	
	# warn (it should send a mail, if cron is properly configured)
	print "Hello,\n\nI assume the following torrent was completed:\n\n" 
	    unless $count;
	print "$name (#$id)\n";
	$count++;

    }

    # should be paused
    if (-e "$watchdir/$file.trs+") {
	print "$bin -t $id --stop ($watchdir/$file.trs+ exists)\n" if $debug;
	print LOG strftime "%c - pause $name (#$id)\n", localtime;
	`$bin --torrent $id --stop >/dev/null`;
	next;
    }
    
    # should be removed 
    unless (-e "$watchdir/$file.trs" or $added{$id} or $justwokeup) {
	print "$bin -t $id --remove (no $watchdir/$file.trs)\n" if $debug;
	print LOG strftime "%c - remove $name (#$id)\n", localtime;
	`$bin --torrent $id --remove >/dev/null`;
	next;
    }

    # any other case, ask to start it (dont log it, we do it everytime)
    print "$bin -t $id --start\n" if $debug and !$pause_all;
    `$bin --torrent $id --start >/dev/null` unless $pause_all;

    # for any processed file, update the info file, starting with the files
    # list 
    print "> $file.trs\n" if $debug;
    open(TRSFILE, "> $watchdir/$file.trs");
    open(INFO, "$bin --torrent $id --files |");
    print TRSFILE "FILES\n";
    while (<INFO>) { print TRSFILE "  ".$_; }
    print TRSFILE "\n";
    close(INFO);
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
    print README "watch syntax :\n \$file.torrent = to be added\n \$YMMDD-\$id-\$realfile.trs =  being processed (delete it to remove the torrent)\n \$YMMDD-\$id-\$realfile.trs- = to be paused\n \$YMMDD-\$id-\$realfile.trs+ = (supposedly) completed\n all- = use alt-speed (to slowdown/pause)\n";
    close(README);
}


close(LOG);
# EOF
