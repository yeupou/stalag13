#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/pdf2htmls.pl
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
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
#           http://yeupou.wordpress.com/
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
    $output,
    $skip_pdftk, $skip_pdftohtml, $skip_cleanup);
eval {
    $getopt = GetOptions("help" => \$help,
			 "input=s" => \$input,
			 "output=s" => \$output,
			 "skip-pdftk" => \$skip_pdftk,
			 "skip-pdftohtml" => \$skip_pdftohtml,
			 "skip-cleanup" => \$skip_cleanup);
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
# copy the pdf in pwd if necessary
copy($input, ".") unless -e basename($input);
$output = basename(lc($input), ".pdf") unless $output;


## If we get here, everything should be in order, process the PDF
# create the output file
mkdir($output) unless -e $output;
chdir($output);
# split pdf
system($pdftk, "../".basename($input), "burst") 
    unless $skip_pdftk;
# convert to ugly html
opendir(PDFS, ".");
while (defined(my $file = readdir(PDFS))) {
    # deal only with PDFs 
    next unless -f $file;
    next unless $file =~ /\.pdf$/i;
    system($pdftohtml, $file, 
	   "-i", "-s", "-c", "-noframes") 
	unless $skip_pdftohtml;
    unlink($file)
	unless ($skip_pdftohtml or $skip_pdftk);
}
closedir(PDFS);
# clean up html
opendir(HTMLS, ".");
#my @htmls = ("0001");
my @htmls;
my %html_title;
while (defined(my $file = readdir(HTMLS))) {
    # deal only with HTMLs 
    next unless -f $file;
    next unless $file =~ /\.html$/i;
    next if $file =~ /index\.html$/;

    # remember for later
    push(@htmls, $file);

    next if $skip_cleanup;

    # Study the content
    open(IN, "<$file");
    open(OUT, ">$file~");
    print "DBG $file\n";
    while (<IN>) {
	# remove any style, class and bgcolor definition
	s/\W(style|vlink|class|bgcolor)=\"[^\"]*\"//gi;
	# remove blank spaces
	s/\&\#160\;/ /g;
	# if we find a string in bold and italic, assume it may be a page title
	# there may be several, we keep the later
	$html_title{$file} = $1 if /^\<p\>\<i\>\<b\>([^\<\>]*)\<\/b\>\<\/i\>\<\/p\>$/i;
	# remove closing BODY and HTML because we'll add it just below
	# after a link to the next page
	s/\<\/(BODY|HTML)\>//gi;     
	print OUT $_;
    }
    close(IN);
    # link to the next page (assuming it always a four digits)
    my $number = sprintf("%04d", ($1+1)) if ($file =~ /^\D*(\d*)\D*$/);
#    push(@htmls, $number);
    print OUT "<A HREF=\"pg_$number.html\">Go to page $number</A>\n";
    print OUT "</BODY>\n</HTML>\n";
    close(OUT);
    rename("$file~", $file);
}
closedir(HTMLS);
# add indexes
my $titles_count;
open(INDEX, ">index.html");
print INDEX "<HTML><BODY>\n";
foreach my $file (sort(@htmls)) {
    my $number = sprintf("%04d", $1) if ($file =~ /^\D*(\d*)\D*$/);
    if ($html_title{$file}) {
	$titles_count++;
	print INDEX "\n<br />$titles_count) ".$html_title{$file}.": ";
    }
    print INDEX "<A HREF=\"$file\">$number</A> ";
}
print INDEX "</BODY></HTML>\n";
close(INDEX);
copy("index.html", "zindex.html");
copy("index.html", "aindex.html");

## EOF
