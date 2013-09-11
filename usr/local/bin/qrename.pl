#!/usr/bin/perl
#
# Copyright (c) 2013 Mathieu Roy <yeupou--gnu.org>
#      http://yeupou.wordpress.com
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
# Related to post-image-to-tumblr: rename a queue/ directory assuming files
# are ordered in alphabetically.
# 
# Problem is if you just order like 1,2,3,4,... it's trouble when you want to
# insert files in the middle.
# If you purposely skip num and order like 1,4,8,... you are forced to deal
# with possible very very big number if there are many files in the queue
# and then it would be like 20001,20010,20020,... which may not be so 
# practical in the end
# The idea is to have order like CCC,CCG,CCK,CCN,CCP,CCS,CCW,CGC,CGG,...
# with an extra 5 as conveniency at the end of the string.

use strict;
use Getopt::Long;
use File::Copy qw(move);

my %chars = (1 => 'C',
	     2 => 'G',
	     3 => 'K',
	     4 => 'N',
	     5 => 'P',
	     6 => 'T',
	     7 => 'W');	
my $chars_max = scalar keys %chars;
my $queue_max_digits = 3;


## Get options and provide help
my ($help,$getopt,$please_do,$verbose);
eval {
    $getopt = GetOptions("help" => \$help,
			 "max-queue-digits=s" => \$queue_max_digits,
			 "please-do" => \$please_do,
			 "verbose" => \$verbose);
};

if ($help) {
    print STDERR <<EOF;
Usage: $0 -d .

Prefix files files in the current directory with alphabetical characters
to easily maintain a queue.

  -h, --help                 display this help and exit
      --max-queue-digits N   defines how many digits to use for the numerical
                             counter used when out of alphabetical chars
			     (default: $queue_max_digits)
  -p, --please-do            Mandatory: the script will only print what it
                             would do unless you use this option
  -v, --verbose              Self-explanatory.

EOF
exit(1);
}

## Run baby, run

# go through list of files (with glob, to get them ordered)
my $count;
my ($char1, $char2, $char3, $char4) = (1, 1, 0, 5);
while(defined(my $file = glob('*'))){ 
    # only deal with regular files
    next unless -f $file;

    # increment counters
    $count++;
    
    unless ($char1 == $chars_max and
	    $char2 == $chars_max and
	    $char3 >= ($chars_max - 1)) {
	# increment char3 until we are out of unused chars
	$char3++;
    } else {
	# otherwise add a three digit counter (or more, according to opts)
	$char4 = sprintf("%0".$queue_max_digits."d",$count)."5";
	$char3 = $chars_max;
    }

    if ($char3 > $chars_max) {
	# increment char2 when char3 is higher than max chars available
	$char2++;
	$char3 = 1;
    }
    if ($char2 > $chars_max) {
	# increment char1 when char2 is higher than max chars available
	$char1++;
	$char2 = 1;
    }


    # Now rename the file, removing prefix previously added, being not very
    # strict about it to allow the user to mess with it. We ll assume that
    # prefix is anything before ---.
    my $prefix = $chars{$char1}.$chars{$char2}.$chars{$char3}.$char4."---";
    my $file_cleaned = $file;
    if ($file =~ /^(\d*|\w*)---(.*)$/) { $file_cleaned = $2; }

    print "$count $file -> $prefix$file_cleaned\n" if !$please_do or $verbose;
    move($file, $prefix.$file) if $please_do;
}

print "(did nothing since --please-do was not set)\n" unless $please_do;

# EOF
