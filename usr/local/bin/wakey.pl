#!/usr/bin/perl
#
# Copyright (c) 2012-2014 Mathieu Roy <yeupou--gnu.org>
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
# 
# for sound volume  consistency, you should run 
#       cd ~/.wakey && normalize-audio -b *

use strict;

use Getopt::Long;
use Time::Local;
use POSIX;
use File::HomeDir;
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
my ($columns) = GetTerminalSize();
my $clear = `clear`;
use Text::Wrap qw(&wrap $columns);

## SETUP
# take into account user input
my $fallback = "/usr/share/sounds/KDE-Sys-Log-In-Long.ogg";
my $beep = "/usr/share/sounds/KDE-Sys-App-Positive.ogg";
my $songs = File::HomeDir->my_home()."/.wakey";
my $player = "/usr/bin/mplayer";
my @player_opts = ("-really-quiet", "-noconsolecontrols", "-nomouseinput", "-nolirc", "-vo", "null");
my $mixer_alsa = "/usr/bin/amixer";
my $mixer_oss = 0;
my $volume_max = "80";
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
       $0 HH: [OPTIONS]
    
Wakes you up at HH hours and MM minutes by playing (at increasing volume)
a song contained in ~\/.wakey that can be of any format the configured
player ($player) supports.

For sound volume  consistency, you should run something like:
   cd ~/.wakey && normalize-audio -b *

To manipulate volume, it expects $mixer_alsa to be properly set up, with
a 'Master' control. It it fails, it will try to fallback on OSS Audio::Mixer.

Time cannot exceed 23 hours in the future.

  General:
  -t, --timer                Work as a timer (alike \`sleep\`).
      --volume-max=nn        Set maximum volume in percent, in case
                             $volume_max% is too loud/silent on your setup.

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

## CHECK UP
# make sure we will able to do expected job when the time will be up
# (and doing so, select the song about to be played later)


# check if we can run the player
die "Unable to execute $player. Exiting" unless -x $player; 

# check if we can run the mixer
unless (-x $mixer_alsa) {
    # If we cannot, use basic perl module. FIXME: this is not great
    # since I dont even understand how to unmute some channel with this
    $mixer_alsa = "/bin/false";
    $mixer_oss = 1;
    use Audio::Mixer;
}

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
    die "Fallback $fallback not readable, unable to find an appropriate song to play. Exiting" unless -r $fallback;
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
# take one random, lowercase
my $word = lc($words[rand @words]);
chomp($word);

# now play a sound (without bothering changing volume or anything else,
# just so the user can be sure right now we can output audio
# (do that in a child so we can keep control)
my $pid = fork();
if (defined $pid && $pid == 0) {
    # child
    exec($player, 
	 $beep,
	 @player_opts);
}


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

# loop until elapsed time reached what was requested
while ($requested > $elapsed) {
    # keep up to date win size
    ($columns) = GetTerminalSize();

    # clean minimalistic layout
    # (before any computation so it is brought immediatly,
    # while the clear() is made below)
    
    # current time centered
    print DARK sprintf("%*s", int(($columns-5)/2), "")." ".
	strftime("%Hh%M", localtime())."\n", RESET;

    # line break
    print "\n";

    # elapsed justified left
    my $already = " ";
    my $already_color = CYAN;
    my $really_elapsed = int((($wait_count * $wait) / 60));
    if ($really_elapsed < 60) {
	# at least in minutes
	$already .= $really_elapsed."m";
    } else {
	# or in hours
	$already .= int(($really_elapsed / 60))."h";
    }
    $already .= " already";

    # remaining time justified right
    # determine if we ll count the remaining time in s, m or h, set 
    # a color:
    # by default in seconds and yellow
    my $left;
    my $left_color = BRIGHT_YELLOW;
    my $still = ($requested - $elapsed);
    my $still_unit = "s";
    if ($still  > 180 && $still < 10800) {
	# more than 3m and less than 3h:
	# in green if superior to 30 min
      	$left_color = BRIGHT_GREEN if $still > 1800;
	# in minutes 
	$still = int(($still / 60));
	$still_unit = "m";
    }
    if ($still > 10799) {
	# more than 3h:
	# in green unless superior to 9h30, otherwise in red
	unless ($still > 34200) { $left_color = GREEN; } else { $left_color = RED; }
	# in hours	
	$still = int(($still / 3600));
	$still_unit = "h";
    }
    $left = $still.$still_unit." left ";
    
    print $already_color, "$already", RESET
	sprintf("%-*s", int($columns-(length($already)+length($left))), "")
	, $left_color, "$left", RESET "\n\n";


    # show progression bar
    # available chars = width - 4 chars
    my $percent = (($wait_count * $wait)/$delta)*100;
    print "really elapsed ".($wait_count * $wait)."s = ".int($percent)."% while delta ".$delta."s = 100%\n" if $debug;
    my $chars = int((($columns-4)/100)*$percent);
    print int($percent)."% = ".$chars." chars while ".($columns-4)." chars = 100%\n" if $debug;

    print BOLD, " [";
    for (my $i = 1; $i <= ($columns-4); $i++) {
	if ($i < $chars) {
	    print "|";
	} else {
	    print "_";
	}
    }
    print "] ", RESET "\n";

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

# save current volume setup, yes, this is über ugly, please FIXME
my $mixer_not_found = "NOT FOUND";
my $mixer_volume_before = $mixer_not_found;
my $mixer_volume_pcm_before = $mixer_not_found;
# alsa
open(MIXER, "$mixer_alsa get Master |");
while (<MIXER>) {
    next unless /.*\[(\d*)%\].*/;
    $mixer_volume_before = $1;
    last;
}
close(MIXER);
# oss
($mixer_volume_before,) = Audio::Mixer::get_cval('vol')
    if $mixer_oss;

open(MIXER, "$mixer_alsa get PCM |");
while (<MIXER>) {
    next unless /.*\[(\d*)%\].*/;
    $mixer_volume_pcm_before = $1;
    last;
}
close(MIXER);

# fallback
($mixer_volume_pcm_before,) = Audio::Mixer::get_cval('pcm')
    if $mixer_oss;

print "Volume before: Master ".$mixer_volume_before."%, PCM ".$mixer_volume_pcm_before."%\n" if $debug;
die "Not able to find Master mixer volume. Exiting" if $mixer_volume_before eq $mixer_not_found; 

# make sure Master and PCM mixers are not mute
# alsa
system($mixer_alsa, "-q", "set", "Master", "unmute");
system($mixer_alsa, "-q", "set", "PCM", "unmute")
    unless $mixer_volume_pcm_before eq $mixer_not_found;
# oss = no way found to do this with Audio::Mixer

# Put PCM at 100%, start master volume at current - 25,
# at least 40%
my $mixer_volume = ($mixer_volume_before-25);
$mixer_volume = 40 if $mixer_volume < 40;
system($mixer_alsa, "-q", "set", "Master", $mixer_volume."%");
system($mixer_alsa, "-q", "set", "PCM", "100%")
    unless $mixer_volume_pcm_before eq $mixer_not_found;
Audio::Mixer::set_cval("vol", $mixer_volume) if $mixer_oss;
Audio::Mixer::set_cval("pcm", 100) if $mixer_oss;

## ACTUALLY SOUND THE ALARM
# start (silently) the song player in a child so we can keep control
my $pid = fork();
if (defined $pid && $pid == 0) {
    # child
    exec($player, 
	 $song,
	 "-loop", "0",
	 @player_opts);
}

# back to parent, trash noise on STDOUT
print $clear unless $debug;

# Enter in an 5 minutes (300s) loop waiting for the user to wake up
# (if 5 minutes arent enough, call 911)
my $valid_exit = 0;

# get raw input, so we deactivate CTRL-C, CTRL-Z, etc
ReadMode("raw");
my $input;
my $previous_input;

while ($valid_exit < 300 && $word ne $input) {
    print "Run $valid_exit (mixer: $mixer_volume)\n" if $debug;

    # increase sound volume of 2% every 2s, until volume-max %
    # avoiding anychange if the user type anything
    if (($previous_input eq $input) &&
	($valid_exit%2) && 
	($mixer_volume < $volume_max)) {
	$mixer_volume += 2;
	system($mixer_alsa, "-q", "set", "Master", $mixer_volume."%");
	Audio::Mixer::set_cval('vol', $mixer_volume);
	print "Set mixer to ".$mixer_volume."%\n" if $debug;
    }

    # print colored title
    if ($valid_exit%2) {
	print ON_RED, WHITE, "\t\t\tWAKEY", RESET, BOLD, " wakey", RESET "\n\n";
	print BOLD, "\twakey ", RESET, ON_RED, WHITE, "WAKEY", RESET "\n\n";
    } else {
	print ON_RED, WHITE, "\tWAKEY", RESET, BOLD, " wakey", RESET "\n\n";
	print BOLD, "\t\t\twakey ", RESET, ON_RED, WHITE, "WAKEY", RESET "\n\n";
    }

    # provide the word for the user to type
    print "$word: ";
    
    # if input > 5, we should no longer be here. If so, clear input, user
    # mispelled/miscopied
    $input = "" if (length($input) > 5);

    # check if the latest char the user type is correct, if not cancel it
    if ((substr($word, (length($input)-1), 1)) ne
	(substr($input, (length($input)-1), 1))) {
	chop($input);
	print (substr($word, (length($input)-1), 1))." (dict) ne ".(substr($input, (length($input)-1), 1))." (input), erase last char of ".length($input)."\n" if $debug;
    } 

    # at this point, input is validated:
    print GREEN, $input, RESET if $input;
    print "\n";

    # save for later current input
    $previous_input = $input;
    
    # redraw the window each second or each time the user put some input
    (($input .= lc(ReadKey(1))) || sleep 1);

    # increment counter anyway
    $valid_exit++;
    
    print $clear unless $debug;
}

## That is all, almost

# reset term readmode to normal
ReadMode("normal");

# make sure to kill the player process
kill('KILL', $pid);
print "Killing $pid\n" if $debug;

# Reset the volume to previous values
# alsa
system($mixer_alsa, "-q", "set", "Master", $mixer_volume_before."%");
system($mixer_alsa, "-q", "set", "PCM", $mixer_volume_pcm_before."%")
    unless $mixer_volume_pcm_before eq $mixer_not_found;
# oss
Audio::Mixer::set_cval('vol', $mixer_volume_before);
Audio::Mixer::set_cval('pcm', $mixer_volume_pcm_before);

print "Hum, well done. You may now drink a coffee.\n";

# EOF 
