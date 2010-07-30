#!/usr/bin/perl
# 
#
# Mettre à jour le fetchmailrc en fonction de la conf 
# /etc/fetchmailupdate.conf

use strict;
use warnings;
use POSIX qw(strftime);

our $run = 0; # par défaut, on ne travaille pas !
our $log = "/var/log/cgn_fetchmailupdate.log";
our $conffile = "/etc/fetchmailupdate.conf";
our @users = ("moa", "egh");

our $fetchmaildir = "/home/fetchmail";

our $fetchmailrc = "/etc/fetchmailrc";
our $fetchmailrc_mode = "600";
our $fetchmailrc_owner = "fetchmail";
#our $fetchmailrc_part_dir = $fetchmaildir;

our $fetchmailrc_basis = "set syslog
set postmaster \"mail\"
set daemon 60
#set bouncemail
#set no spambounce
set no bouncemail
set properties \"\"";

open(LOG, ">> $log");

# Read configuration file
# Dans confile, on peut redéfinir la valeur des variables prédéfinies
do $conffile or print LOG "Unable to run $conffile.\nMost commonly, it's a privilege issue.\n\nStopped" && exit;

exit unless $run; # doit avoir $run = 1 dans la conf

# On fait une liste d'utilisateurs ok pour téléchargement
our @users_ok;
foreach my $user (@users) {
    if (-e "/home/$user/cherche_le_courriel") {
	push(@users_ok, $user);
    }
}
# On met toujours le pseudo-utilisateur fetchmail
push(@users_ok, "fetchmail");

# On écrit le fetchmailrc temporaire
open(FETCHMAILRC, "> /tmp/fetchmailrc-tmp");
print LOG strftime "%c: \n", localtime;
print FETCHMAILRC $fetchmailrc_basis."\n";
foreach my $user (@users_ok) {
    my $userrc = "/home/$user/.fetchmailrc";
    if (-e $userrc) {
	open(USERRC, "< $userrc");
	while(<USERRC>) {
	    print FETCHMAILRC $_;
	}
	close(USERRC);
	print LOG "Contenu de $userrc ajouté\n";
    } else {
	print LOG "Erreur : impossible de trouver $userrc bien que demandé";
    }

}
close(FETCHMAILRC);

# On compare le fetchmailrc temporaire et remplace si différent
my $rewrite;
unless (-e $fetchmailrc) {
    $rewrite = 1;
} else {
    unless (`diff /tmp/fetchmailrc-tmp $fetchmailrc` eq '') {
	$rewrite = 1;
    }
}

if ($rewrite) {
    system("/bin/mv", "-f", "/tmp/fetchmailrc-tmp", $fetchmailrc);
    system("/bin/chmod", $fetchmailrc_mode, $fetchmailrc);
    system("/bin/chown", $fetchmailrc_owner, $fetchmailrc);
    print LOG "$fetchmailrc mis-à-jour\n";
} else {
    unlink("/tmp/fetchmailrc-tmp");
}

close(LOG);

