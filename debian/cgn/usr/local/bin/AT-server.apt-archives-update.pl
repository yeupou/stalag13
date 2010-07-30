#!/usr/bin/perl
#
# Archiver les courriers recus, mis dans un fichier  
# /home/$user/.mail-vers-archives/$YYYY-MM.mbox
# dans un dossier /var/www/$user.mail
#
# On peut tomber sur les fichiers mis en place par procmail à chaque
# distribution de courrier.
# On peut aussi tomber sur des fichiers issues des archives de lecteurs
# de courriels, ceux envoyés (voir cron.weekly/mail-archives). 
#
# On ne redefinit pas la date, on se fie a celle du filtrage.
#
# $Id: AT-server.apt-archives-update.pl,v 1.4 2005-10-17 07:53:27 moa Exp $

use Sys::Hostname;

do "/etc/hosts.nib.pl" or exit;
exit unless $server;
exit if hostname() ne $server;

# Maintain the local deb archives
my @dirs = ("dists/stable/all/binary-i386", 
	    "dists/stable/server/binary-i386",
	    "dists/testing/updates/binary-i386");

my %dirs_real;
$dirs_real{"dists/stable/all/binary-i386"} = "/stock/debian/stable-all";
$dirs_real{"dists/stable/server/binary-i386"} = "/stock/debian/stable-server";
$dirs_real{"dists/testing/updates/binary-i386"} = "/stock/debian/testing";

# every hour, update homemade packages list
chdir("/var/www/debian");

foreach my $dir (@dirs) {
    # Needed to get the real dir path because -L (follow symlinks) option
    # is missing in find shipped with sarge
    my $dir_real = $dirs_real{$dir};
    my $testfile = "$dir_real/Packages.gz";

    # Run only if there are new files or if the file newer is missing
    if (! -e $testfile or `find $dir_real -newer $testfile -name "*.deb"`) {
	`apt-ftparchive packages $dir/ > $dir/Packages`;
	
	# We have more bandwith than CPU, so skip the gzipping..
	# But apparently apt-get now longer accept ungzipped Packages files
	system("gzip", "-f", "$dir/Packages");
	#system("rm", "-f", "$dir/Packages.gz") if -e "$dir/Packages.gz";
    }
}
