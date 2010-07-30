#!/usr/bin/perl
#
# Copyright (c) 2005 Mathieu Roy <yeupou--gnu.org>
# http://yeupou.coleumes.org
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
# $Id: keduca-shrinker.pl,v 1.2 2005-04-23 11:31:48 moa Exp $

use Getopt::Long;

my $getopt;
my $debug; 
my $help;

my $input;
my $output;
my $number = "20";


########### Get options, give help

eval {
    $getopt = GetOptions("debug" => \$debug,
			 "help" => \$help,
			 "number=s" => \$number,
			 "input=s" => \$input,
			 "output=s" => \$ouput);
};

if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTION] --input [FILE] 

A small program that take a kdeduca test file (.edu) as input with say 100
question and output a kdeduca test file with 20 questions selected randomly. 

    -i, --input=FILE          Input keduca file.
    -o, --output=FILE         Output keduca file, shrinked.
                              (By default, the suffix -shrinked will be added)
    -n, --number=NUMBER       Number expected of questions, in the shrinked
                              version.
                              ($number by default)
 
Project Homepage: https://gna.org/projects/keduca-shrinker/
EOF
exit(1);
}

# Test input file existence
unless ($input) {
    print "No input file.\n";
}
unless (-r $input) {
    print "Input file not readable.\n";
    exit;
}
open(INPUT, "< $input");

# Test output writability
unless ($output) {
    $output = $input;
    $output =~ s/.edu$//;
    $output .= "-shrinked.edu";
}
if (-e $output && ! -w $output) {
    print "Output file not writable.\n";
    exit;

}
open(OUTPUT, "> $output");

########### Define subs

sub fisher_yates_shuffle {
    my $table = shift;
    my $i;
    for ($i = @$table; --$i;) {
	my $j = int rand($i+1);
	next if $i == $j;
	@$table[$i,$j] = @$table[$j,$i];
    }
}


########### Grab the file header, store questions in an array.
# I know, it's XML, it may be simple to call an xml parser.
# But in fact, we have nothing to parse here, we do not care about
# the real content, so...
my $structure = "header";
my $header;
my $footer;
my @questions;
my $newquestion;

while (<INPUT>) {
    ## Grab the structure (footer and header)
    # the header last when data begins
    # the footer begin when data ends

    $header .= $_ if $structure eq "header";

    $structure = "content" if /\<Data\>/m;
    $structure = "footer" if /\<\/Data\>/m;

    $footer .= $_ if $structure eq "footer";

    ## Grab the questions
    if ($structure eq "content") {
	$newquestion .= $_;
	
	# If we found the string </question>, that the end of a question
	if (/\<\/question\>/m) {
	    push(@questions, $newquestion);
	    $newquestion = "";
	}
	
    }
}

########### Select the number of questions we want
# warn the user if there's nothing to do
if (scalar(@questions) < $number) {
    print "There are only ".scalar(@questions)." questions in the input file, less than $number.\n";
    # Copy & exit
    system("cp", $input, $output);
    exit;
} else {
    # Shuffle
    fisher_yates_shuffle(\@questions);
    # Keeps only the desired amount (number-1, as 0 is counted)
    $#questions = ($number-1);
}

########### Final output
print OUTPUT $header;
print OUTPUT @questions;
print OUTPUT $footer;

close(INPUT);
close(OUTPUT);
