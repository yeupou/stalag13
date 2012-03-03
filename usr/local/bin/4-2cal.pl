#!/usr/bin/perl
#
# Copyright (c) 2011 Mathieu Roy <yeupou--gnu.org>
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
# requires libdate-calc-perl libcalendar-simple-perl

use strict;
use Calendar::Simple;
use POSIX qw(strftime);
use Date::Calc qw(Delta_Days);
use Time::Local;
use Term::ANSIColor qw(:constants);

my $debug = 1;

## get input

my $mon = shift || (localtime)[4] + 1;
my $yr  = shift || (localtime)[5] + 1900;
my $group  = shift || 3;


## prepare data

# create a cal output, with month starting on monday (will also check input)
my @month = calendar($mon, $yr, 1);
# note for future ref the current day, if we are printing the current month
my $currentday = 0;
$currentday = (localtime)[3] if ($mon eq ((localtime)[4] + 1));

# determine time ref depending on the selected group (check input: 1 to 3) 
# and compare, in days, 1st of currently printed month to it
my $timedelta = 0;
$timedelta = Delta_Days(2011, 12, 29, $yr, $mon, 1) if $group eq 1;
$timedelta = Delta_Days(2011, 12, 25, $yr, $mon, 1) if $group eq 2;
$timedelta = Delta_Days(2011, 12, 21, $yr, $mon, 1) if $group eq 3;
die unless $timedelta;
print "timedelta is $timedelta days\n" if $debug;
# then determine when exactly we are in the cycle the 1st of currently...
my $cyclemeridiem = "AMM";
my $cycleday = 1;
for (my $day=1; $day <= $timedelta; $day++) {
    $cycleday++;
    if ($cycleday > 6) {
	$cycleday = 1;
	if ($cyclemeridiem eq "PM") {
	    $cyclemeridiem = "AM";
	} else {
	    $cyclemeridiem = "PM";
	}
    }
    print "day $day out of $timedelta:\t$cycleday $cyclemeridiem\n" if $debug;
}
print "1st of the month is $cycleday $cyclemeridiem in the group $group cycle\n" if $debug;


## print output

# print group
print "$group/";
# print i18n month
print " ", strftime("%B %Y", localtime(timelocal(1,0,0,1,($mon-1),($yr-1900)))), "\n";
# print i18n week day
for (my $i=2; $i < 9; $i++) {
    print substr(strftime("%a", localtime(timelocal(1,0,0,$i,0,112))),
		 0, 2)." ";
}
print "\n";
foreach (@month) {
    map { 
	if ($_) {
	    # take into account when we are in the cycle
	    # - output only between 1st and 4th
	    # - change from AM/PM the 6th and reset
	    if ($cycleday < 5) {
		if ($cyclemeridiem eq "AM") {
		    print WHITE ON_BLUE;
		} else {
		    print WHITE ON_MAGENTA;
		}
	    }
	    $cycleday++;
	    if ($cycleday > 6) {
		$cycleday = 1;		
		if ($cyclemeridiem eq "AM") {
		    $cyclemeridiem = "PM";
		} else {
		    $cyclemeridiem = "AM";
		}
	    }

	    # print in bold current day
	    print BOLD if ($_ eq $currentday);
	    print sprintf "%2d ", $_;
	    
	    # always reset
	    print RESET;
	} else {
	    print '   '; }
    } @$_;
    print "\n";
}

# EOF

