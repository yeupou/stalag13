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
# Wrapper to several tools in order to build a splitted html output of a 
# pdf:
# I use this to read PDF ebooks on my smartphone that handles poorly font 
# sizes when reading PDF, can't cope with a big HTML file and would unable
# anyway to get back to the latest read page.
# 
# requires debian packages pdftk poppler-utils

use strict;
use Getopt::Long;
use File::Basename;
use File::Copy;

# required binaries
my $pdftk = "/usr/bin/pdftk";
my $pdftohtml = "/usr/bin/pdftohtml";

# get standard opts with getopt
my ($help, $getopt, $debug,
    $input,
    $output);
eval {
    $getopt = GetOptions("help" => \$help,
			 "input=s" => \$input,
			 "output=s" => \$output);
};

## Show help
if ($help || !$input) {
    print STDERR <<EOF;
Usage: $0 -i file.pdf 
    
Ouput to multiple HTML files the content of one PDF.

  -i, --input=file.pdf       Input PDF file.
  -o, --output=directory     Output directory.

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

## Base checks
# required softwares
for ($pdftk, $pdftohtml) { 
    die "Unable to find or run $_, exiting" unless -x $_; 
}
# files and dir
die "Unable to find or read $input" unless -r $input;
$output = basename(lc($input), ".pdf") unless $output;

## If we get here, everything should be in order, process the PDF
# create the output file
mkdir($output) unless -e $output;
chdir($output);
# split pdf
system($pdftk, "../".$input, "burst");
# convert to ugly html
opendir(PDFS, ".");
while (defined(my $file = readdir(PDFS))) {
    # deal only with PDFs 
    next unless -f $file;
    my $suffix = 0;
    $suffix = lc($1) if ($file =~ /^.*(\.[^.]*)$/);
    next unless $suffix eq ".pdf";
    system($pdftohtml, $file, 
	   "-i", "-s", "-c", "-noframes");
    unlink($file);
}
closedir(PDFS);
# clean up html
opendir(HTMLS, ".");
my @htmls;
while (defined(my $file = readdir(HTMLS))) {
    # deal only with HTMLs 
    next unless -f $file;
    my $suffix = 0;
    $suffix = lc($1) if ($file =~ /^.*(\.[^.]*)$/);
    next unless $suffix eq ".html";

    # Study the content
    open(IN, "<$file");
    open(OUT, ">$file~");
    while (<IN>) {
	# remove any style, class and bgcolor definition
	s/\W(style|vlink|class|bgcolor)=\"[^\"]*\"//gi;
	# remove blank spaces
	s/\&\#160\;/ /g;
	# remove closing BODY and HTML because we'll add it just below
	# after a link to the next page
	s/\<\/(BODY|HTML)\>//g;     
	print OUT $_;
    }
    close(IN);
    # link to the next page (assuming it always a four digits)
    my $number = sprintf("%04d", ($1+1)) if ($file =~ /^\D*(\d*)\D*$/);
    push(@htmls, $number);
    print OUT "<A HREF=\"pg_$number.html\">Go to page $number</A>\n";
    print OUT "</BODY>\n</HTML>\n";
    close(OUT);
    rename("$file~", $file);
}
closedir(HTMLS);
# add indexes
# FIXME: add chapters titles to the index
open(INDEX, ">index.html");
print INDEX "<HTML><BODY>\n";
foreach my $number (sort(@htmls)) {
    print INDEX "<A HREF=\"pg_$number.html\">$number</A> ";
}
print INDEX "</BODY></HTML>\n";
close(INDEX);
copy("index.html", "zindex.html");
copy("index.html", "aindex.html");

## EOF
