#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Getopt::Long;
my $getopt;
my $mode;
my $help;

eval {
    $getopt = GetOptions("help" => \$help,
			 "mode=s" => \$mode);
};

if ($help) {
    print "Option possible : --mode=[cgn|atn]\n";
    exit;
}

unless ($mode) {
    print "En quel mode ulysse doit fonctionner ?\n\n";
    print "\t -", CYAN," cgn ", RESET, ": avec hephaistos\n";
    print "\t -", CYAN," atn ", RESET, ": autonome\n\n";
    print "[cgn]: ";
    chomp($mode = <STDIN>);
}


$mode = "cgn" unless $mode eq "atn";

my @switchs = ("cgn-fetchmailswitch.pl", "cgn-nfsswitch.pl");

foreach my $switch (@switchs) {
    `$switch --mode=$mode`;
}





