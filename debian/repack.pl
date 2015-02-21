#!/usr/bin/perl
use strict;
use File::Basename;

my $curdir = $ARGV[0];
die "Invalid directory passed as argument" unless -d $curdir;
my $path = "$curdir/debian/stalag13";
my $main = "utils-ahem";
my %packages = (utils => [],
		keyring => ["/etc/apt"],
                "cache-apt" => ["/etc/nginx/sites-available/cache-apt", "/etc/cron.weekly/cache-apt"],
		"cache-steam" => ["/etc/nginx/sites-available/cache-steam", "/etc/cron.daily/cache-steam"],
		"cache-spoof" => ["/etc/dnsspoof.com", "/etc/default/dnsspoof", "/etc/init.d/dnsspoof"]);

for my $package (keys %packages) {
    print "Repacking $package with:\n";
    foreach (@{$packages{$package}}) {
	print "\t$_\n";
	# create parent directory if missing
	system("/bin/mkdir", "-p", dirname("$path-$package$_")) unless -e dirname("$path-$package$_");
	# move
	system("/bin/mv", "-f", "$path-$main$_", "$path-$package$_");
    }
}
