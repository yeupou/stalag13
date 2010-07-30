#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

my $cgn_conf = "/etc/fstab-cgn";
my $atn_conf = "/etc/fstab-atn";
my $base_conf = "/etc/fstab";

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
    print "En quel mode nfs doit fonctionner ?\n\n";
    print "\t -", CYAN," cgn ", RESET, ": avec hephaistos\n";
    print "\t -", CYAN," atn ", RESET, ": pas de NFS\n\n";
    print "[cgn]: ";
    chomp($mode = <STDIN>);
}

sub Update {
    if (-e $_[0]) {
	`ln -sfv $_[0] $base_conf`;
    } else {
	print "Mise-à-jour de $base_conf avec $_[0] impossible.\n";
	print "$_[0] n'existe pas.\n";
    }
}

$mode = "cgn" unless $mode eq "atn";
Update($cgn_conf) if $mode eq "cgn";
Update($atn_conf) if $mode eq "atn";





