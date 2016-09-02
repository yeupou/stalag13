#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/4-2cal.pl
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
#!/usr/bin/perl
#
# Copyright (c) 2011-2014 Mathieu Roy <yeupou--gnu.org>
#   http://yeupou.wordpress.com
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

use Getopt::Long;
use Calendar::Simple;
use POSIX qw(strftime isatty);
use Date::Calc qw(Delta_Days);
use Time::Local;
use Term::ANSIColor qw(:constants);

my $debug = 0;
my $month = (localtime)[4] + 1;
my $year  = (localtime)[5] + 1900;
my $group  = 1;
my $full_year = 0;
my $html = 0;
my $help;

# do HTML if not started by a term
unless (isatty(*STDIN)) {
    $html = 1;
}

## get tty input with standard opts.
my $getopt;
unless ($html) {
    eval {
	$getopt = GetOptions("debug" => \$debug,
			     "html" => \$html,
			     "help" => \$help,
			     "full-year" => \$full_year,
			     "group=s" => \$group,
			     "year=s" => \$year,
			     "month=s" => \$month);
    };
}

## get tty input with what remains in ARGS
unless ($html) {
    for (@ARGV) { 
	# case month/year
	if (/^(\d{1,2})\/(\d{4})$/) {
	    $month = $1;
	    $year = $2;
	    last;
	}
	# case year/month
	if (/^(\d{4})\/(\d{1,2})$/) {
	    $year = $1;
	    $month = $2;
	    last;
	}
	# one or two numbers: a month
	if (/^(\d{1,2})$/i) {
	    $month = $1;
	}
	# four numbers: a year
	if (/^(\d{4})$/i) {
	    $year = $1;
	}      
    }
}


if ($help) {
    print STDERR <<EOF;
Usage: $0 MM/YYYY [OPTIONS]
       $0 MM YYYY [OPTIONS]
       $0 --month=MM --year=YYYY [OPTIONS]
    
      --group=n              Group (default: $group)
      --html                 xHTML output (default if not started by a
			     terminal).
      --full-year            Show 12 months instead of 3 (default for xHTML
                             output).

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}



## set up output: HTML or terminal?
my $out_linebreak = "\n";
my ($out_startrow, $out_starttable, $out_endtable, $out_startcolumn, $out_endcolumn);
my $out_endrow = $out_linebreak;
my $out_style_reset = RESET;
my $out_style_startbold = BOLD;
my $out_style_endbold = $out_style_reset;
my $out_style_color_blue = WHITE ON_BLUE;
my $out_style_color_magenta = WHITE ON_MAGENTA;

if ($html) {
    # if not a TTY, assume we want HTML
    use CGI qw(:standard Link);
    $out_linebreak = br();
    $out_starttable = '<table>';
    $out_endtable = '</table>';    
    $out_startrow = '<tr>';
    $out_endrow = '</tr>';
    $out_startcolumn = '<td>';
    $out_endcolumn = '</td>';
    $out_style_reset = $out_endcolumn;
    $out_style_startbold = '<span style="font-weight: bold">';
    $out_style_endbold = '</span>';
    $out_style_color_blue = '<td style="background-color: blue; color: white">';
    $out_style_color_magenta = '<td style="background-color: red; color: white">';

    # Init http header if not from standard input
    print header(-charset => 'UTF-8') unless (isatty(*STDIN));
    # Immediately create the HTML layout
    print start_html(-title => '4-2cal', -encoding => 'UTF-8');

    # For a full year
    $full_year = 1;
}


## prepare data
# month-1 / month / month+1
my $output_count = 0;
my $output_max = 3;
$output_max = 12 if $full_year;
for ($month = ($month - 1); $output_count < $output_max; $month++) {
    print $out_linebreak if $output_count > 0;
    $output_count++;
    # month is 0, go back a year
    if ($month < 1) {
	$year = ($year - 1);
	$month = 12;
    }
    # month is 13, go forward a year
    if ($month > 12) {
	$year = ($year + 1);
	$month = 1;
    }
    
    # create a cal output, with month starting on monday (will also check input)
    my @days = calendar($month, $year, 1);
    # note for future ref the current day, if we are printing the current month
    my $currentday = 0;
    $currentday = (localtime)[3] if ($month eq ((localtime)[4] + 1));
    
    # determine time ref depending on the selected group (check input: 1 to 3) 
    # and compare, in days, 1st of currently printed month to it
    my $timedelta = 0;
    $timedelta = Delta_Days(2011, 12, 29, $year, $month, 1) if $group eq 1;
    $timedelta = Delta_Days(2011, 12, 25, $year, $month, 1) if $group eq 2;
    $timedelta = Delta_Days(2011, 12, 21, $year, $month, 1) if $group eq 3;
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
    
    # print i18n month
    print "   ", strftime("%B %Y", localtime(timelocal(1,0,0,1,($month-1),($year-1900)))), $out_linebreak;
    # print i18n week day
    print $out_starttable.$out_startrow;
    for (my $i=2; $i < 9; $i++) {
	print $out_startcolumn.
	    substr(strftime("%a", localtime(timelocal(1,0,0,$i,0,112))),
		   0, 2)." ".
		   $out_endcolumn;
    }
    print $out_endrow;
    foreach (@days) {
	print $out_startrow;
	map { 
	    if ($_) {
		# take into account when we are in the cycle
		# - output only between 1st and 4th
		# - change from AM/PM the 6th and reset
		if ($cycleday < 5) {
		    if ($cyclemeridiem eq "AM") {
			print $out_style_color_blue;
		    } else {
			print $out_style_color_magenta;
		    }
		} else {
		    print $out_startcolumn;
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
		print $out_style_startbold if ($_ eq $currentday);
		print sprintf "%2d ", $_;
		print $out_style_endbold if ($_ eq $currentday);
		
		# always reset
		print $out_style_reset;
	    } else {
		print $out_startcolumn."   ".$out_endcolumn; 
	    }
	} @$_;
	print $out_endrow;
    }
    print $out_endtable;
}

print end_html() if $html;


# EOF

