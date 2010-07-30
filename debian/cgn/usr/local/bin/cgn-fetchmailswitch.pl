#!/usr/bin/perl

use strict;
use warnings;
use Term::ANSIColor qw(:constants);
use Getopt::Long;

my %rc_conf = (cgn => "/etc/fetchmailupdate-cgn.conf",
	       atn => "/etc/fetchmailupdate-atn.conf",
	       real => "/etc/fetchmailupdate.conf"
	       );

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
    print "En quel mode fetchmail doit fonctionner ?\n\n";
    print "\t -", CYAN," cgn ", RESET, ": se rabat sur hephaistos (arrêt)\n";
    print "\t -", CYAN," atn ", RESET, ": gère de manière autonome (marche)\n\n";
    print "[cgn]: ";
    chomp($mode = <STDIN>);
}

sub Update {
    Link($rc_conf{$mode}, $rc_conf{real});
    if ($mode eq "cgn") {
	`rm -f /etc/rc2.d/S70fetchmail` if -e "/etc/rc2.d/S70fetchmail";
    } else {
	Link("/etc/init.d/fetchmail", "/etc/rc2.d/S70fetchmail");
    }
}

sub Link {
    if (-e $_[0]) {
	`ln -sfv $_[0] $_[1]`;
    } else {
	print "Mise-à-jour de $_[1] avec $_[0] impossible.\n";
	print "$_[0] n'existe pas.\n";
    }
}

$mode = "cgn" unless $mode eq "atn";
Update($mode);






