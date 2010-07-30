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
# $Id: cgn-photosupdate.pl,v 1.23 2005-10-11 14:55:49 moa Exp $

use strict;
use Getopt::Long;
use Sys::Hostname;
use POSIX qw(strftime);
use Net::FTP;
use Digest::MD5 qw(md5_base64);
use File::Find::Rule;
use Term::ReadKey;

$ENV{LC_ALL} = "fr_FR";


my $getopt;
my $nodownload;
my $onlylist;
my $verbose;
my $readd;
my $check_upload;

my $lock = "/var/run/cgn-photosupdate.lock";

our $server; 
do "/etc/hosts.nib.pl" or exit;
exit unless $server;
#exit if hostname() ne $server;

my $user = "eglantinegh";
my $ftphost = "ftpperso.free.fr";
our $passwd; 
do "/etc/majphotos";


eval {
    $getopt = GetOptions("no-download" => \$nodownload,
			 "only-list" => \$onlylist,
			 "re-add" => \$readd,
			 "check-upload" => \$check_upload,
			 "verbose" => \$verbose);
};



my $topdir = "/stock/photos";
my $wwwdir = "/var/www/photos";
my $timestamp = "/stock/photos/.timestamp";

chdir($topdir);

# Check lock/Create lock
exit if -e $lock;
system("touch", $lock);

######################################################################
### Check if there are new pictures
my $need_update = 0;

# Each run, we touch the timestamp, and then we use find to find new files.
# If there is no timestamp, indeed there are new files
$need_update = 1 unless -e $timestamp;
$need_update = 1 if `find $topdir -newer $timestamp`;


######################################################################
### Generate albums if necessary
my @bins_args = ("-f/stock/photos/.binsrc", "-oscaled", "-sjoi");

if ($need_update) {
    system("/usr/bin/mrclean", $topdir);
    system("/bin/chmod", "g+w", $topdir, "-R");
    system("/bin/chgrp", "users", $topdir, "-R");
    system("bins", @bins_args, $topdir, $wwwdir);
}


######################################################################
### Update the timestamp
system("/usr/bin/touch", $timestamp);

unless ($need_update or $check_upload) {
    unlink($lock);
    exit;
}


######################################################################
### Check files to upload

# first make an hash with all the files we have here + their size
# make an additional hash for the subdirectory
my %harddisk;
my %subdir;
my $file;
my $size;

sub AddToList {
    opendir(DIR, $_[0]);
    while (defined($file = readdir(DIR))) {
	next unless -f $_[0]."/".$file;
	next if $file eq ".cvsignore";
	next if $file =~ /.*~/m;

	$file = $_[0]."/".$file;

	open(FILE, $file);
	binmode(FILE);
	$harddisk{$file} = Digest::MD5->new->addfile(*FILE)->b64digest;
	close(FILE);
	$subdir{$file} = $_[0];

    }
}

chdir($wwwdir);
chdir("..");
my @subdirectories = File::Find::Rule->directory()
    ->directory
    ->in("photos");
for (@subdirectories) {
    AddToList($_);
    print "Will handle $_\n" if $verbose;
}

# secondly get the online list
my $originallist = "/tmp/eglantinegh.free.fr-list";

unless ($nodownload) {
    print "Get original list\n" if $verbose;
    `rm -f $originallist`;
    `wget http://eglantinegh.free.fr/photos/.list --cache=off --http-user=oui --http-passwd=non --proxy=off --output-document=$originallist`;
    $size = (stat($originallist))[7];
    `rm -f $originallist` if $size eq 0;
} else {
    print "Build fake original list\n" if $verbose;
    `rm -f $originallist`;
    `touch $originallist`;
#    `cp htdocs/.list $originallist`;
}

# make an hash with the original list
unless (-f $originallist) {
    unlink($lock);
    exit;
}
print "Original list was found\n" if $verbose;

my %online;
open(ORIGINALLIST, "< $originallist");
while (<ORIGINALLIST>) {
    ($file, $size) = split(":", $_);
    $online{$file} = $size;
}
close(ORIGINALLIST);

# write the updated list
unlink("$wwwdir/.list");
foreach $file (sort(keys(%harddisk))) {
    open(NEWLIST, ">> $wwwdir/.list");
    print NEWLIST $file.":".$harddisk{$file}."\n";
    close(NEWLIST);
}
print "Newlist written\n" if $verbose;

# check which files needs to be updated
my @toupload;
foreach $file (keys(%harddisk)) {
    if (!exists($online{$file})) {
	push(@toupload, $file);
    } else {
	chomp($online{$file});
	
	# ignore la verif pour (.details.html, _Moy.jpg.*.html, _Gd.jpg.*.html)
	# si on est pas en re-add
	if ($readd ||
	    ($file !~ /.*\.details\.html$/ && 
	     $file !~ /.*\_Moy\.jpg\..*\.html$/ &&
	     $file !~ /.*\_Gd\.jpg\..*\.html$/))
	{
	    
	    if ($online{$file} ne $harddisk{$file}) {
		push(@toupload, $file);	    
	    }
	}
    }	
} 
unless (@toupload) {
    unlink($lock);
    exit;
}
@toupload = sort(@toupload);

# print a list of files that need to be updated
foreach $file (@toupload) {
    print $file." (".$online{$file}." -> ".$harddisk{$file}.")\n" if $verbose;
}
if ($onlylist) {
    unlink($lock);
    exit;
}

# upload!
unless ($passwd) {
    ReadMode('noecho');
    print "Mot de passe ?\n";
    chomp($passwd = ReadLine 0);
    ReadMode('normal');
}

print "Connexion vers $ftphost... ";
my $ftp = Net::FTP->new($ftphost,
			Timeout => 30) 
    or die "Unable to connect: $@\n";
print "ok\nSe loggue en tant que $user... ";
$ftp->login($user, $passwd) && print "ok\n"
    or die "Unable to login\n";

#$ftp->cwd("/photos") && print "cd /photos\n"
#   or die "Unable to cwd /photos\n";
my $count;
foreach $file (sort(@toupload)) {
    if ($count > 50) {
	print "Ferme la session FTP, plus de 50 fichiers mis-en-ligne.\n";
	$ftp->quit() or warn "Unable to cleanly logout. Who cares?\n";
	sleep(60);
	
	print "Reconnexion vers $ftphost... ";
	$ftp = Net::FTP->new($ftphost,
			    Timeout => 60) 
	    or die "Unable to connect: $@\n";
	print "ok\nSe loggue en tant que $user... ";
	$ftp->login($user, $passwd) && print "ok\n"
	    or die "Unable to login\n";
	$count = 0;
    }
    $count++;
    print "$count. Met-à-jour ".$file." (".$harddisk{$file}.", ";

    if ($subdir{$file}) {
	my $success_cwd = 1;
	$ftp->cwd($subdir{$file}) && print "cd ".$subdir{$file}.", "
	or $success_cwd = 0;
	
	unless ($success_cwd) {
	    $ftp->mkdir($subdir{$file}, 1) && $ftp->cwd($subdir{$file}) && print "mkdir + cd ".$subdir{$file}.", "
		or die "Unable to mkdir + cwd ".$subdir{$file}."\n";
	}
    }

    if ($file =~ /(\.ps\.gz$)|(\.ps$)|(\.eps$)|(\.pdf$)|(\.jpg$)|(\.png$)|(\.mov$)/) {
	print "mode binaire)... ";
	$ftp->binary();
    } else {
	print "mode texte)... ";
	$ftp->ascii();
    }

    $ftp->put($file) && print "ok\n" or die "Unable to put $file\n";
			
    if ($subdir{$file}) {
	$ftp->cwd("/") && print "cd /\n"
	    or die "Unable to cwd /\n";
    }	
						
}
print "Session finie.\n";
$ftp->quit() or warn "Unable to cleanly logout. Who cares?\n";


# remove lock
unlink($lock);
