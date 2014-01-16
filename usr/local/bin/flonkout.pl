#!/usr/bin/perl
#
# Copyright (c) 2014 Mathieu Roy <yeupou--gnu.org>
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
# requires debian packages libterm-readkey-perl

use strict;
use feature "switch";

use Getopt::Long;

use Time::HiRes qw(sleep);
use POSIX;

use Term::ANSIColor qw(:constants);
use Term::ReadKey;
my $clear = `clear`; 
use Text::Wrap qw(&wrap $columns);

## PROGRAMS
# http://en.wikipedia.org/wiki/High-intensity_interval_training
# name cycles exercise rest (warmup)
# tabata 8x 20 10 
# tabata2  4x 40 20
# gibala  12x 60 75    180 
# nada 5x  30 30 nada
# timmons  3x  20120    120
# 
# If no warmup, the program will nonetheless add a 15s before starting
# Cycle is informative, it wont affect timers and wont stop anything
#
# To keep it the interface simple and small, the number of programs is so
# far limited to 9 (debug being excluded). I may implement .flonkoutrc 
# support to enable to set the 9 to something more specific
my %programs = (
    'tabata 20' => '8,20,10',
    'tabata 40' => '4,40,20',
    gibala => '12,60,75,180',
    '30/30' => '5,30,30',
    timmons => '3,20,120,120',
    debug => '2,5,20,3',
    );
my $default_program = "tabata 20";
my $default_warmup = 10;

## USER INTERFACE
my $lines_max = 4;
my $refresh_delay = 0.4;

## SOUNDS

# by default use sounds from freedesktop
my $sounds_path = "/usr/share/sounds/freedesktop/stereo/";
# but use my updated version (no useless blank space, normalized) if possible
$sounds_path = "/usr/share/sounds/flonkout/" 
    if -e "/usr/share/sounds/flonkout/message.oga";
my %sounds = (
    # ordered by perceptibility
    0 => $sounds_path.'message.oga',
    1 => $sounds_path.'message-new-instant.oga',
    1 => $sounds_path.'bell.oga',
    3 => $sounds_path.'complete.oga',
    );

## SETUP
my ($help, $getopt, $debug, $mute);

# get standard opts with getopt
eval {
    $getopt = GetOptions("help" => \$help,
			 "debug" => \$debug);
};


if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

Provides a workout timer (to be run in a term with a big font size).

  -m, --mute                With or without sound.

When running, type:
  Escape to exit/quit.
       P to change program, with PageUp and PageDown to navigate
         in the list
       R to restart current program.
  Delete to reset everthing
Spacebar to (un)pause
       M to (un)mute.

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

if ($debug) {
    $default_program = "debug";
}

## SOUND CHECKS
# print something when no sound
# EXPERIMENTAL. Wonder whether it is worth using SDL for better timings
my $player = "/usr/bin/mplayer";
my @player_opts = ("-really-quiet", "-noconsolecontrols", "-nomouseinput", "-nolirc", "-vo", "null");

# specific fonction to play sound
sub Play {
    my @sounds_selected = ($sounds{0});

    given ($_[0]) {
	# go from 0 to 3 by order of noticeability
	when ("endprogram") { @sounds_selected = ($sounds{3}, $sounds{3}, $sounds{3}); }
	when ("startstop") { @sounds_selected = ($sounds{3}); }
	when ("tenminutesmore") {@sounds_selected = ($sounds{2}); }
	when ("tensecondsmore") { @sounds_selected = ($sounds{0}); }
    }

    # fork so we dont interrupt timers and all
    my $pid = fork();
    if (defined $pid && $pid == 0) {
	print "play '".join(", ", @sounds_selected)."' with $player\n" if $debug;
	# child
	exec($player, 
	     @sounds_selected,
	     @player_opts);
    }
}

## RUN
my ($counter_main_h, $counter_main_m, $counter_main_s);
my ($counter_sub_h, $counter_sub_m, $counter_sub_s);
my ($program, $cycles, $exercice, $rest, $warmup);
my ($status, $countdown, $cycle, $hundred, $pause);
my ($input, $input_offset, %program_id, $program_need_update);
ReadMode("cbreak"); # use cbreak to read each char, but keeping ctrl-c working 

# loop every second until forcefully quit 
# (user interface will be one sec delayed, this an acceptable drawback)
$|++;
while (my $sleep = sleep($refresh_delay)) {
    ## USER INPUT

    # get keystrokes. try to get a full sequence to enable access to
    # keys like DEL, etc
    my $new_input;
    while (my $key = ReadKey(-1)) { $new_input .= $key; }
    # $input will only be touched on change and will not accumulate data
    $input = $new_input if $new_input;
    
    print "input: '$input'   as typed: '$new_input'\n" if $debug;

    # deal with complex chars coming from keys like ESC
    given ($input) {
	# FIXME: this is probably not portable.
	# user requested exit with ESC
	when ("\e") { ReadMode(0); exit(1); }
	# user want to reset whole with DEL
	when ("\e[3~") { $program_need_update = 1; $counter_main_h = $counter_main_m = $counter_main_s = 0; $input = ""; }  
	# user requested to show next programs, bump offset and set to menu
	# with PageDown
	when ("\e[6~") { $input_offset += $lines_max; $input = "p"; }
	# idem reverse, bump back offset and set to menu with PageUp
	when ("\e[5~") { $input_offset = 0; $input = "p"; }
    }
    
    # then deal with single chars, keeping only the latest, in lowerclass
    $input = lc(substr($input, -1));

    # accept counterpart without caps lock for the AZERTY layout
    given ($input) {
	when ("&") { $input = 1; }
	when ("é") { $input = 2; }
	when ("\"") { $input = 3; }
	when ("'") { $input = 4; }
	when ("(") { $input = 5; }
	when ("-") { $input = 6; }
	when ("è") { $input = 7; }
	when ("_") { $input = 8; }
	when ("ç") { $input = 9; }
    }
    # only numeric means a specific ided program.
    if ($input =~ /^\d$/ and exists($program_id{$input})) { 
	$program = $program_id{$input};
	$program_need_update = 1; 
	$input = ""; 
    }
    
    # otherwise that a regular menu option
    given ($input) {
	# user requested to quit with q
	when ("q") { ReadMode(0); exit(1); }
	# user requested restart current program
	when ("r") { $program_need_update = 1; $input = ""; }
	# user want to pause
	when (" ") { 
	    if ($pause) { $pause = 0; }
	    else { $pause = 1; }
	    $input = "";
	}
	# user want to mute/unmute TODO
	when ("m") { $input = ""; }
    }
	
    ## UPDATES
    
    # Update program
    if (!$program or $program_need_update) {
	# no program set? take default
	$program = $default_program unless $program;

	# get parameters
	($cycles, $exercice, $rest, $warmup) = split(",", $programs{$program});
	# reset anything else
	$counter_sub_h = $counter_sub_m = $counter_sub_s = 0;
	$cycle = $countdown = $status = 0;
	$program_need_update = 0;
    }

    # Update general timers (warmup is not counted)
    # Use time returned by sleep() just in case there was unexpected gap
    $counter_main_s += $sleep
	unless ($status eq "warmup" 
		or $status eq ""
		or $pause);
    if ($counter_main_s > 59) { $counter_main_s = 0; $counter_main_m++; }
    if ($counter_main_m > 59) { $counter_main_m = 0; $counter_main_h++; }

    $counter_sub_s += $sleep
	unless $pause;
    if ($counter_sub_s > 59) { $counter_sub_s = 0; $counter_sub_m++; }
    if ($counter_sub_m > 59) { $counter_sub_m = 0; $counter_sub_h++; }

    # Update countdown
    $countdown -= $sleep
	unless $pause;
    
    if ($countdown < 1) {
	# change status
	given ($status) {
	    when ("warmup") {
		# real start
		Play("startstop");
		$counter_sub_h = $counter_sub_m = $counter_sub_s = 0;
		$cycle = 1;
		$status = "exercice";
		$countdown = $hundred = $exercice;
	    }
	    when ("exercice") {
		Play("startstop"); 
		$status = "rest";
		$countdown = $hundred = $rest;
	    }
	    when ("rest") {
		# increment cycles if we finished a rest
		$cycle++;
		# play specific sound if we just finished the amount
		# of cycles for this program
		if ($cycle eq $cycles) {
		    Play("endprogram");
		} else {
		    Play("startstop"); 
		}
		$status = "exercice";
		$countdown = $hundred = $exercice;
	    }
	    default {
		# status unset mean we just started
		# go for warmup. if warmup is null, then set it to 15s
		$status = "warmup";
		$warmup = $default_warmup unless $warmup;
		$countdown = $hundred = ($warmup-1);
	    }
	}
    }

    ## CLEAR
    print $clear unless $debug;

    # Check term size each run
    my ($columns) = GetTerminalSize();
    # we need at least 28 chars (circa first line's max)
    if ($columns < 28) {
	print BRIGHT_RED BOLD, "Reduce font-size or\nenlarge window!\n", RESET;
	next;
    }

    ## PRINT MENU
    if ($input eq "p") {
	# any keep pressed that are not these will make thb e user return
	# to regular printout
	
	# Basically, this is just a list of programs. Since we want to
	# run this possibly in a very small terminal, we ll print
	# only three at once and user will have to type next to select
	# further
	my $list;
	foreach my $this_program (sort(keys %programs)) {
	    # ignore debug program
	    next if $this_program eq "debug";

	    $list++;

	    # ignore already registered;
	    next if $list < $input_offset;

	    # get and register programs
	    my ($this_cycles, $this_exercice, $this_rest, $this_warmup) = split(",", $programs{$this_program});
	    $program_id{$list} = $this_program 
		unless exists($program_id{$list});

	    # list it
	    print BOLD, $list, RESET ") ",BRIGHT_RED,"${this_exercice}",RESET,"-",BRIGHT_GREEN,"${this_rest}",RESET," $this_program";

	    # list only 3 at once
	    last if ($list - $input_offset) >= ($lines_max - 1);

	    # start newline only if more data is to be printed
	    print "\n";
	}
	
	next;
    }


    ## PRINT INFO

    # exercise  total   time
    print BOLD;
    # print hour counter only if bigger than 1
    printf("%02d:", $counter_sub_h) if $counter_sub_h > 0;
    printf("%02d:%02d", $counter_sub_m,$counter_sub_s);
    print "   ";

    # total
    print BRIGHT_BLACK;
    # print hour counter only if bigger than 1
    printf("%02d:", $counter_main_h) if $counter_main_h > 0;
    printf("%02d:%02d", $counter_main_m,$counter_main_s);
    print "   ";

    # current time
    print strftime("%Hh%M", localtime());
    print RESET, "\n";

    # current time
    
    # exercice name , cycle count or and if doing warmup or paused
    print "\"$program\" "; 
    if ($pause) {
	# simple warn when in pause
	print BRIGHT_CYAN, "PAUSE";
    } else { 
	if ($status eq "warmup") {
	    # specific colors for WARMUP
	    print BRIGHT_CYAN "WARMUP/PREP"; 
	} else {
	    # otherwise print cycle count
	    print BRIGHT_YELLOW if $cycle > $cycles;
	    print "$cycle", RESET, "/$cycles";
	}
    }
    print "\n";

    # numeric countdown
    print BOLD if $countdown < 6;
    given ($status) {
	when ("rest") { print BRIGHT_GREEN; }
	when ("exercice") { print BRIGHT_RED; }
	when ("warmup") { print BRIGHT_YELLOW; }
    }
    print int($countdown)." ";

    # countdown progress bar
    #   main bar from 100% to 0%:
    #     1% = (current countdown * 100 / total countdown) 
    my $percent = (($countdown * 100) / $hundred);
    #     length = term size / 100 * 1%
    my $progressbar_main = int(($columns / 100) * $percent);
    #   sub bar from 10/5s to 0s, for countdown at least bigger than 9
    #     by default at least size of the term
    my $progressbar_sub = $columns;
    if ($hundred > 9) { 
	my $this_hundred = 10;
	$this_hundred = 5 if $hundred < 40;
	# same as before but on one line
	$progressbar_sub = int($columns / 100 * 
			       (($countdown * 100) / $this_hundred))
	    if $countdown <= $this_hundred;
    }
    
    # loop for the lenght of term size
    for (my $i = (length(int($countdown))+1); $i < $columns; $i++) {
	if ($i < $progressbar_main) { 
	    print "|"; 
	    next;
	} 
	if ($i < $progressbar_sub) { 
	    print "_"; 
	    next;
	}
	# unlikely to get here
	print " "; 
    }   
    print RESET;
 
    print "\n" if $debug;
}

ReadMode(0);
print "Bye!\n";

# EOF 
