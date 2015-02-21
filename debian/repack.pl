#!/usr/bin/perl
use strict;
use File::Basename;

my $curdir = $ARGV[0];
die "Invalid directory passed as argument" unless -d $curdir;
my $path = "$curdir/debian/stalag13";
my $main = "utils-ahem";
my %packages = (utils => [],
		keyring => ["/etc/apt"],
                "utils-cache-apt" => ["/etc/nginx/sites-available/cache-apt", "/etc/cron.weekly/cache-apt"],
		"utils-cache-steam" => ["/etc/nginx/sites-available/cache-steam", "/etc/cron.daily/cache-steam"],
		"utils-cache-spoof" => ["/etc/dnsspoof.conf", "/etc/default/dnsspoof", "/etc/init.d/dnsspoof"]);

for my $package (keys %packages) {
    print "Repacking $package with:\n";
    foreach (@{$packages{$package}}) {
	print "  $_\n";
	# create parent directory if missing
	system("/bin/mkdir", "-p", dirname("$path-$package$_")) unless -e dirname("$path-$package$_");
	# move
	system("/bin/mv", "-fv", "$path-$main$_", "$path-$package$_");
    }
}
