#!/usr/bin/perl
#
# Copyright (c) 2013 Mathieu Roy <yeupou--gnu.org>
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
    debug => '2,2,8,3',
    );
my $default_program = "tabata 20";
my $default_warmup = 10;
my $lines_max = 4;

## SETUP
my ($help, $getopt, $debug, $mute);


# get standard opts with getopt
eval {
    $getopt = GetOptions("help" => \$help,
			 "debug" => \$debug);
};

# get hour/minute (others options should no longer be in ARGV thanks to
# getopt
for (@ARGV) { 
}

if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

Provides a workout timer (to be run in a term with a big font size).

  -m, --mute                With or without sound.

When running, type:
     E or Q to exit/quit.
     P to change program.
     R to restart current program.
     M to (un)mute.

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

if ($debug) {
    $default_program = "debug";
}

## CHECK UP
# make sure we will able to do expected job when the time will be up
# (and doing so, select the song about to be played later)

# check if we can run the player

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
while (my $sleep = int(sleep(1))) {
    ## USER INPUT
    # get update
    $input .= uc(ReadKey(-1));

    print "input: $input\n" if $debug;
    # but only ever keep the one latest char
    $input = substr($input, -1);
    # if using azerty without caps lock, may be confusing
    $input = 1 if $input eq "&";
    $input = 2 if $input eq "é";
    $input = 3 if $input eq "\"";
    $input = 4 if $input eq "'";
    $input = 5 if $input eq "(";
    $input = 6 if $input eq "-";
    $input = 7 if $input eq "è";
    $input = 8 if $input eq "_";
    $input = 9 if $input eq "ç";
    print "input: $input\n" if $debug;
 
    # user requested exit
    if ($input eq "Q" or $input eq "E") { ReadMode(0); 	exit; }
    # user request an ided program
    if ($input =~ /^\d$/ and exists($program_id{$input})) { 
	$program = $program_id{$input};
	$program_need_update = 1; 
	$input = ""; 
    }
    # user requested restart current program
    if ($input eq "S") { $program_need_update = 1; $input = ""; }
    # user requested reset script
    if ($input eq "R") { $program_need_update = 1; $counter_main_h = $counter_main_m = $counter_main_s = 0; $input = ""; }
    # user requested to show next programs, bump offset and set to menu
    if ($input eq "N") { $input_offset += $lines_max; $input = "P"; }
    # idem reverse, bump back offset and set to menu
    if ($input eq "B") { $input_offset = 0; $input = "P"; }
    # user want to pause
    if ($input eq " ") { 
	if ($pause) { $pause = 0; }
	else { $pause = 1; }
	$input = "";
    }
    # user want to mute/unmute TODO
    if ($input eq "M") { $input = ""; }

    ## UPDATES
    
    # Check term size each run
    my ($columns) = GetTerminalSize();;

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
    $countdown--
	unless $pause;
    
    if ($countdown < 1) {
	# change status
	given ($status) {
	    when ("warmup") {
		# real start
		$counter_sub_h = $counter_sub_m = $counter_sub_s = 0;
		$cycle = 1;
		$status = "exercice";
		$countdown = $hundred = $exercice;
	    }
	    when ("exercice") {     
		$status = "rest";
		$countdown = $hundred = $rest;
	    }
	    when ("rest") {
		# increment cycles if we finished a rest
		$cycle++;
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

    ## PRINT MENU
    if ($input eq "H" or 
	$input eq "P" or
	$input eq "N" or
	$input eq "B") {
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
	    print BOLD, $list, RESET ") ",BRIGHT_RED,"${this_exercice}",RESET,"-",BRIGHT_GREEN,"${this_rest}",RESET,"\t$this_program\n";

	    # list only 3 at once
	    last if ($list - $input_offset) >= ($lines_max - 1);


	}
	
	# Back if we are not at offset null
	print " ", RESET BOLD, "b", RESET BRIGHT_BLACK, "ack" if $input_offset > 0;
	# Next if the offset wont be higher than the list
	print " ", RESET BOLD, "n", RESET BRIGHT_BLACK, "ext" if ($input_offset + $lines_max) < (scalar(keys %programs));
	# Allow to restart current program / everything
       	print " re", RESET BOLD, "s", RESET BRIGHT_BLACK, "tart", RESET;
	print " ", RESET BOLD, "r", RESET BRIGHT_BLACK, "eset", RESET; 
	# quit
	print " ", RESET BOLD, "q", RESET BRIGHT_BLACK, "uit", RESET, "\n"; 
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

    # numeric (centered) countdown
    print BOLD if $countdown < 6;
    given ($status) {
	when ("rest") { print BRIGHT_GREEN; }
	when ("exercice") { print BRIGHT_RED; }
	when ("warmup") { print BRIGHT_YELLOW; }
    }
    for (my $i = 0; $i < (($columns/2)-3); $i++) { print " "; }
    print "$countdown\n";

    # countdown progress bar
    #     (countdown * 100 / def countdown) 
    my $percent = (($countdown*100)/$hundred);
    my $chars = int(($columns/100)*$percent);
    for (my $i = 0; $i < $columns; $i++) {
	if ($i < $chars) { print "#"; } 
	else { print " "; }
    }
    print RESET;
 
    print "\n" if $debug;
}

ReadMode(0);
print "Bye!\n";

# EOF 