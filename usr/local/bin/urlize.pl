#!/usr/bin/perl
#
# (c) 2001-2012 Mathieu Roy <yeupou--gnu.org>
#     http://yeupou.wordpress.com
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
#    USA

########################################
# Configuration preset

# Requirements
use strict;
use Getopt::Long;

# Usual for Darius Tools perl scripts
my $DARIUS_AUTHOR="2002-2012 Mathieu Roy";
my $DARIUS_MAIL="yeupou--gnu.org";
my $DARIUS_VER="Irrelevant";

# Specific
my $getopt;
my $help;
my $version;
my $dir;
my $expression;
my $verbose;
my $success;

########################################
# Functions definition

########################################
# Here we go

# Get options
eval {
    $getopt = GetOptions("help" => \$help,
			 "version" => \$version,
			 "dir=s" => \$dir,
			 "expression=s" => \$expression,
			 "verbose" => \$verbose);
};

# Def return
if($help) {
    print STDERR <<EOF;
Usage: $0 [OPTION]
Rename files in a directory to a simplified name, 
(mainly for Universal Ressources Locators, URL.

  -h, --help                 display this help and exit
      --version              output version information and exit

  -d, --dir D                rename files in dir D (default)
  -e, --expression E         urlize expression E
      --verbose              tells you what is done

EXAMPLE: $0 .    # would urlize each file in the current dir
         $0 -d . # same command


Report bugs or suggestions to <$DARIUS_MAIL>
EOF
exit(1);
}

if($version) {
    print STDERR <<EOF;
$0 $DARIUS_VER

Copyright (c) $DARIUS_AUTHOR <$DARIUS_MAIL>
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.
EOF
exit(1);
}

sub Urlize {
    my $ret = $_[0];  
    $ret =~ tr/ /_/;  
    $ret =~ tr/à-é/a-e/;
    $ret =~ tr/+/_/;
    $ret =~ tr/=/_/;
    $ret =~ tr/ù/u/;
    $ret =~ s/\&//g;
    $ret =~ s/\!//g;
    $ret =~ s/\'//g;
    $ret =~ s/\?//g;
    $ret =~ s/\"//g;
    $ret =~ s/\%//g;
    return $ret;
}


if ($expression) {
    print Urlize($expression)."\n";
} elsif ($dir) {
    die "$dir does not exit\n" unless -e $dir;
    opendir(DIR, $dir);
    while (defined(my $file = readdir(DIR))) {
	next if $file =~ /^\.$/;
	next if $file =~ /^\.\.$/;
	my $file_clean = Urlize($file);
	unless ($file_clean eq $file) {
	    print "$file -> $file_clean\n" if $verbose;
	    $success = rename($dir."/".$file,$dir."/".$file_clean);
	    print "Failed to rename $file\n" unless $success;
	} else {
	    print "$file = $file_clean\n" if $verbose;	    
	}
    }
    closedir(DIR);
} else {
    die "No expression specified, no directory specified\n";
}

# End
########################################
