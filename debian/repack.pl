#!/usr/bin/perl
use strict;
use File::Basename;

my $curdir = $ARGV[0];
die "Invalid directory passed as argument" unless -d $curdir;
my $path = "$curdir/debian/stalag13";
my $main = "utils-ahem";
my %packages = (utils => [["/etc/bash_completion.d", "/etc/bashrc.d", "/etc/profile.d"],
		keyring => ["/etc/apt"],
                "utils-cache-apt" => ["/etc/nginx/sites-available/cache-apt", "/etc/cron.weekly/cache-apt"],
		"utils-cache-steam" => ["/etc/nginx/sites-available/cache-steam", "/etc/cron.daily/cache-steam"],
		"utils-cache-spoof" => ["/etc/dnsspoof.conf", "/etc/default/dnsspoof", "/etc/init.d/dnsspoof"],
		"utils-nginx" => ["/etc/init.d/perl-fcgi", "/etc/init.d/php-fcgi", "/etc/nginx/cache_proxy_params", "/etc/nginx/certs", "/etc/nginx/allow_local"],
		"utils-cloud" => ["/usr/share/owncloud", "/etc/nginx/sites-available/cloud"],
		"utils-webmail" => ["/usr/share/roundcube", "/var/lib/roundcube/plugins/antibruteforce", "/var/lib/roundcube/plugins/carddav", "/etc/nginx/sites-available/webmail"]
		"utils-transmission" => ["/usr/local/bin/*torrent-watch*", "/etc/cron.d/torrent", "/etc/logrotate.d/torrent"]
    );

for my $package (keys %packages) {
    print "Repacking $package with:\n";
    foreach (@{$packages{$package}}) {
	print "  $_\n";
	# create parent directory if missing
	system("/bin/mkdir", "-p", dirname("$path-$package$_")) unless -e dirname("$path-$package$_");
	# move
	system("/bin/mv", "-f", "$path-$main$_", "$path-$package$_");
    }
}
