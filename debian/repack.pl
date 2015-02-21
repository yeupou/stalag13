#!/usr/bin/perl
use strict;
use File::Basename;

my $curdir = $ARGV[0];
die "Invalid directory passed as argument" unless -d $curdir;
my $path = "$curdir/debian/stalag13";
my $main = "utils-ahem";
my @ignore = ("/etc/apt/sources.list.d/49-stalag13.list");
my %packages = (utils => ["/etc/bash_completion.d", "/etc/bashrc.d", "/etc/profile.d", "/usr/local/bin/qrename.pl", "/usr/local/bin/flonkout.pl", "/usr/local/bin/4-2cal.pl", "/usr/local/bin/switch-sound.pl", "/usr/local/bin/urlize.pl", "/usr/local/bin/wakey.pl"],
		keyring => ["/etc/apt"],
		"utils-cache-apt" => ["/etc/nginx/sites-available/cache-apt", "/etc/cron.weekly/cache-apt"],
		"utils-cache-steam" => ["/etc/nginx/sites-available/cache-steam", "/etc/cron.daily/cache-steam"],
		"utils-cache-spoof" => ["/etc/dnsspoof.conf", "/etc/default/dnsspoof", "/etc/init.d/dnsspoof"],
		"utils-exim" => ["/etc/exim4", "/usr/local/bin/memcached-exim.pl"],
		"utils-nginx" => ["/etc/init.d/perl-fcgi", "/etc/init.d/php-fcgi", "/etc/nginx/cache_proxy_params", "/etc/nginx/certs", "/etc/nginx/allow_local"],
		"utils-cloud" => ["/usr/share/owncloud", "/etc/nginx/sites-available/cloud"],
		"utils-webmail" => ["/usr/share/roundcube", "/var/lib/roundcube/plugins/antibruteforce", "/var/lib/roundcube/plugins/carddav", "/etc/nginx/sites-available/webmail"],
		"utils-torrent" => ["/usr/local/bin/torrent-watch.pl", "/etc/cron.d/torrent", "/etc/cron.weekly/torrent", "/etc/logrotate.d/torrent"],
		"utils-tumblr" => ["/usr/local/bin/post-image-to-tumblr-init-auth.pl", "/usr/local/bin/post-image-to-tumblr.pl", "/usr/local/lib/site_perl/WWW/Tumblr.pm", "/usr/local/lib/site_perl/WWW/Tumblr"]
    );

for my $package (keys %packages) {
    print "Repacking $package with:\n";
    foreach (@{$packages{$package}}) {
	# check ignore list first
	next if $_ ~~ @ignore;
	
	print "  $_\n";
	my ($file, $dir, $ext) = fileparse($_, qr/\.[^.]*/);
 
	# create parent directory if missing
	system("/bin/mkdir", "-p", "$path-$package$dir") unless -e "$path-$package$dir";
	# move the file
	system("/bin/mv", "-f", "$path-$main$_", "$path-$package$_");
	# if it's a script, assume there could be a symlink without ext
	# to move as well
	if ($ext eq ".pl" || $ext eq ".sh") {
	    system("/bin/mv", "-f", "$path-$main$dir/$file", "$path-$package$dir/$file")
		if -l "$path-$main$dir/$file";
	}
		
    }
}
