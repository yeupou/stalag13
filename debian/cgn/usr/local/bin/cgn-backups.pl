#!/usr/bin/perl
#
# $Id: cgn-backups.pl,v 1.16 2005-10-10 18:58:28 moa Exp $

use Sys::Hostname;
use POSIX qw(strftime);
use Getopt::Long;


# get opts
my $getopt;
my $force;
my $verbose;
my $tmp = "/tmp/backups";

eval {
    $getopt = GetOptions("force" => \$force,
			 "verbose" => \$verbose);
};


do "/etc/hosts.nib.pl" or exit;



# SERVER: archive home content + database, store it in /backups
# Make sure we still have enough room for the backups
if (hostname() eq $server) {
    
    # Make room
    system("/usr/local/bin/cgn-bak-makespace.pl");

    my @dirs = ("/home/cvs",
		"/home/backup-area",
		"/home/wiki",
		"/home/cgn",
		"/home/moa",
		"/home/egh",
		"/stock/photos");

    my $backupsdir = "/backups/cgn-".strftime("%Y-%m-%d", localtime);
    system("mkdir", "-p", $backupsdir);
    system("chmod", "o-rwx", $backupsdir);
    system("chmod", "g-rwx", $backupsdir);

    # arg SQL
    my $sqlargs = "-u backups -pbackups?";

    
    print strftime("%Y-%m-%d %H:%M:%S", localtime)." Fetch databases names.\n";
    my @tables = (split "\n", `mysql $sqlargs -B --skip-column-names -e "SHOW DATABASES"`);

    print strftime("%Y-%m-%d %H:%M:%S", localtime)." Starts creating backups.\n";
    
    foreach my $table (@tables) {
	next if $table eq "mnogosearch";
	next if $table eq "thenoize";
	next if $table eq "acti";
	next if $table eq "test";
	
	print strftime("%Y-%m-%d %H:%M:%S", localtime)." Dump+gzip de $table\n"; 
	`mysqldump $sqlargs $table | gzip > $backupsdir/$table.sql.gz`;
    }


    print strftime("%Y-%m-%d %H:%M:%S", localtime)." Create $backupsdir/home.tar.gz.\n";
    system("tar", "cfz", "$backupsdir/home.tar.gz", @dirs);

}


# DIO: maintain a copy of sons+mail archives, which are not in fact archived
# No check made on the hard disk space remaining
if (hostname() eq "dionysos") {
    my @distant_dirs = ("/stock/sons",
			"/stock/suxor",
			"/stock/www",		   
			"/home/deb/deb");

    my $backupsdir = "/home/backups";
    system("mkdir", "-p", $backupsdir);
    system("chmod", "o-rwx", $backupsdir);
    system("chmod", "g-rwx", $backupsdir);

    # copie les dossiers distants
    for (@distant_dirs) {
	print strftime("%Y-%m-%d %H:%M:%S", localtime)." Sync $_ to $backupsdir/$_.\n";
	system("mkdir", "-p", "$backupsdir/$_") unless -e "$backupsdir/$_";
	system("rsync", "-a", "--delete", "-e", "ssh",
	       "cgn-backups\@gate:$_/", "$backupsdir/$_/");
	
    }

}


# End
