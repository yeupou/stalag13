#!/usr/bin/perl
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
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
#
# requires debian packages libfile-homedir-perl libterm-readkey-perl

use strict;

use Getopt::Long;
use Time::Local;
use File::HomeDir;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
my ($columns) = GetTerminalSize();;
my $clear = `clear`;
use Text::Wrap qw(&wrap $columns);

## SETUP
# take into account user input
my $fallback = "/usr/share/sounds/KDE-Sys-Log-In-Long.ogg";
my $songs = File::HomeDir->my_home()."/.wakey";
my $player = "/usr/bin/mplayer";
my $mixer = "/usr/bin/amixer";
my $volume_max = "100";
my $dict = "/usr/share/dict/words";

my ($help, $getopt, $debug,
    $ignore_powersave,
    $timer,
    $hours, $minutes);


# get standard opts with getopt
eval {
    $getopt = GetOptions("help" => \$help,
			 "debug" => \$debug,
			 "timer" => \$timer,
			 "ignore-powersave" => \$ignore_powersave,
			 "volume-max=s" => \$volume_max);
};

# get hour/minute (others options should no longer be in ARGV thanks to
# getopt
for (@ARGV) { 
    # case HH:mm
    if (/(\d*)\:(\d*)/) {
	$hours = $1;
	$minutes = $2;
	last;
    }
    # case HHh
    if (/(\d*)h/i) {
	$hours = $1;
    }
    # case HHh
    if (/(\d*)m/i) {
	$minutes = $1;
    }      

    last if ($hours && $minutes);
}
print "$hours:$minutes\n" if $debug;

# die in case of weird HH:MM settings 
die "Hours setting is superior to 23, it makes no sense, exiting" if ($hours > 23);
die "Minutes setting is superior to 59, it makes no sense, exiting" if ($minutes > 59);


if ($help || (!$hours && !$minutes)) {
    print STDERR <<EOF;
Usage: $0 HHh MMm [OPTIONS] 
       $0 HH:MM [OPTIONS] 
    
Wakes you up at HH hours and MM minutes by playing (at increasing volume)
a song contained in ~\/.wakey that can be of any format the configured
player ($player) supports.

To manipulate volume, it expects $mixer to be properly set up, with
a 'Master' control.
Note that time cannot exceed 23 hours in the future.

  General:
  -t, --timer                Work as a timer (alike \`sleep\`).
      --ignore-powersave     Do not test whether the computer is using 
                             a powersave plan that may cause it to sleep
			     or hibernate.
      --volume-max=nn        Set maximum volume in percent, in case
                             $volume_max% is really too loud on your setup.

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

## CHECK UP
# make sure we will able to do expected job when the time will be up
# (and doing so, select the song about to be played later)

# check if we are not using a powersave plan that may cause the box to 
# sleep or hibernate
#TODO

# check if we can run the player
die "Unable to execute $player. Exiting" unless -x $player; 

# check if we can run the mixer
die "Unable to execute $mixer. Exiting" unless -x $mixer; 

# lists songs in ~/.wakey
my $song;
opendir(SONGS, $songs);
my @valid_songs;
while (defined(my $file = readdir(SONGS))) {
    # go thru the list of files
    next unless -f "$songs/$file";
    print "$file is a file...\n" if $debug;
    next unless -r "$songs/$file";
    print "$file is readable.\n" if $debug;
    push(@valid_songs, "$songs/$file");
}
closedir(SONGS);

# randomly pick a song
if (scalar(@valid_songs) > 0) {
    srand();
    $song = $valid_songs[rand @valid_songs];
    print "$song selected\n" if $debug;
}

# if still undefined, go with the fallback
unless ($song) {
    $song = $fallback;
    print "No valid file in $songs, use $fallback\n" if $debug;
    die "Fallback $fallback not readable, unable to find an appropriate song to play, dying" unless -r $fallback;
}

# same idea here, check if we can find a short word in $dict, if not, exit
my @words;
open(DICT, "< $dict");
while (<DICT>) {
    # list every word of 5 or less caracters, without accents
    next unless /^[a-zA-Z]{3,5}$/;
    push(@words, $_);    
}
close(DICT);
die "Unable to find words in $dict, dying" if scalar(@words) < 1;
my $word = $words[rand @words];
chomp($word);


## CHECK TIME 
# Every n secs, check the current time. This allows us to make sure to always
# work with the current time for the configured timezone, even if it changed
# overnight.
# If not reached yet, refresh the window with visual indicators
# (time remaining + ETA + progression bar)
# For timer mode, we could have simply made a sleep() call, but it is nicer
# to provide visual info.
my $wait = 3;
my $wait_count;

my $requested = 0;
my $elapsed = 0;

if ($timer) {
    # Quick computation for the timer
    $requested = ((($hours * 60) + $minutes) * 60);
} else {
    # Find out epoch request:
    # if asked for an hour smaller than the current one, assume we mean 
    # tomorrow, so we add 1day (86400s) to the request
    $requested = timelocal(0, $minutes, $hours, (localtime)[3,4,5]);
    $requested = ($requested + 86400) if ($hours < (localtime)[2]);
    $elapsed = timelocal(localtime());
}
my $delta = $requested - $elapsed;
print "initial delta $delta\n" if $debug;

# Timer: compared time elapsed to what was requested (duh!)
# Normal: hour must be exactly the same (because if a at 22PM you asked
# for 7AM, it makes no sense to compare the numbers), minute must be equal
# or superior (in case we missed the exact minute, god knows how).
while ($requested > $elapsed) {

    # provide nice info (before any computation so it is brought immediatly,
    # while the clear() is made below)
    print BOLD, "\tWakey Wakey (not yet)", RESET "\n\n";

    my $still = ($requested - $elapsed);
    my $still_unit = "s";
    if ($still  > 180 && $still < 10800) {
	$still = int(($still / 60));
	$still_unit = "m";
    }
    if ($still > 10799) {
	$still = int(($still / 3600));
	$still_unit = "h";
    }
    # show ~ remaining time 
    print GREEN, "\t\t... ~ ".$still.$still_unit, RESET " \n\n";

    # show progression bar
    # available chars = width - 4 chars
    my $percent = (($wait_count * $wait)/$delta)*100;
    print "really elapsed ".($wait_count * $wait)."s = ".int($percent)."% while delta ".$delta."s = 100%\n" if $debug;
    my $chars = int((($columns-4)/100)*$percent);
    print int($percent)."% = ".$chars." chars while ".($columns-4)." chars = 100%\n" if $debug;

    print BOLD, " [";
    for (my $i = 0; $i <= ($columns-4); $i++) {
	if ($i < $chars) {
	    print "#";
	} else {
	    print ".";
	}
    }
    print "]", RESET "\n";

    # now update
    sleep $wait;
    $wait_count++;
    print $wait."s elapsed, $wait_count runs\n" if $debug;

    # clear window now that time elapsed (so avoid to loose immediately
    # previous warning message, if any)
    print $clear unless $debug;

    if ($timer) {
	$elapsed = ($wait_count * $wait);
	print "\ttimer mode totals: ".$requested."s requested > ".$elapsed."s elapsed\n" if $debug;
    } else {
	$elapsed = timelocal(localtime());
	print "\tEpoch time is $elapsed, $requested ($hours:$minutes) requested\n" if $debug;
    }
}

## PREPARE SOUNDING THE ALARM
# Adjust sound volumes

# make sure Master and PCM mixers are not mute
system($mixer, "-q", "set", "Master", "unmute");
system($mixer, "-q", "set", "PCM", "unmute");

# save current volume setup, yes, this is über ugly, please FIXME
my $mixer_volume_before = "50";
my $mixer_volume_pcm_before = "50";
open(MIXER, "$mixer get Master |");
while (<MIXER>) {
    next unless /.*\[(\d*)%\].*/;
    $mixer_volume_before = $1;
    last;
}
close(MIXER);
open(MIXER, "$mixer get PCM |");
while (<MIXER>) {
    next unless /.*\[(\d*)%\].*/;
    $mixer_volume_pcm_before = $1;
    last;
}
close(MIXER);
print "Volume before: Master ".$mixer_volume_before."%, PCM ".$mixer_volume_pcm_before."%\n" if $debug;

# Put PCM at 100%, start master volume at volume-max (default: 100%) - 40
my $mixer_volume = ($volume_max-40);
system($mixer, "-q", "set", "Master", $mixer_volume."%");
system($mixer, "-q", "set", "PCM", "100%");

## ACTUALLY SOUND THE ALARM
# start (silently) the song player in a child so we can keep control
my $pid = fork();
if (defined $pid && $pid == 0) {
    # child
    exec($player, $song,
	 "-loop", "0",
	 "-really-quiet",
	 "-noconsolecontrols",
	 "-nomouseinput");
}

# back to parent, trash noise on STDOUT
print $clear;

# Enter in an 5 minutes (300s) loop waiting for the user to wake up
# (if 5 minutes arent enough, call 911)
my $valid_exit = 0;
ReadMode("raw");
my $input;
while ($valid_exit < 300 && $word ne $input) {
    # increase sound volume every 5s, until 100%
    if (($valid_exit%5) && ($mixer_volume < $volume_max)) {
	$mixer_volume = ($mixer_volume+5);
	system($mixer, "-q", "set", "Master", $mixer_volume."%");
	print "Set mixer to ".$mixer_volume."%\n" if $debug;
    }

    # title
    if ($valid_exit%2) {
	print ON_RED, WHITE, "\t\t\tWAKEY", RESET, BOLD, " wakey", RESET "\n\n";
	print BOLD, "\twakey ", RESET, ON_RED, WHITE, "WAKEY", RESET "\n\n";
    } else {
	print ON_RED, WHITE, "\tWAKEY", RESET, BOLD, " wakey", RESET "\n\n";
	print BOLD, "\t\t\twakey ", RESET, ON_RED, WHITE, "WAKEY", RESET "\n\n";
    }
    
    # user input
    print "$word: $input\n";

    # if input >= 5, we should no longer be here. If so, clear input, user
    # mispelled/miscopied
    $input = "" if (length($input) >= 5);

    # check if the latest char the user type is correct, if not cancel it
#    print "Last ".substr($input, (length($input)-1), 1)."\n";
    if ((substr($word, (length($input)-1), 1)) ne
	(substr($input, (length($input)-1), 1))) {
	chop($input);
	print (substr($word, (length($input)-1), 1))." (dict) ne ".(substr($input, (length($input)-1), 1))." (input), erase last char of ".length($input)."\n" if $debug;
    }

    # redraw the window each second or each time the user put some input
    (($input .= ReadKey(1)) || sleep 1);

    print $clear unless $debug;

    $valid_exit++;
}

## That is all, almost
ReadMode("normal");
# make sure the child is dead
kill('KILL', $pid);
print "Killing $pid\n" if $debug;

# Before exiting, reset the volume to previous values
system($mixer, "-q", "set", "Master", $mixer_volume_before."%");
system($mixer, "-q", "set", "PCM", $mixer_volume_pcm_before."%");

print "Hum, well done. You may now drink a coffee.\n";

# EOF 
