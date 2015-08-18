#!/usr/bin/perl
use strict;
use File::Basename;

my $curdir = $ARGV[0];
die "Invalid directory passed as argument" unless -d $curdir;
my $path = "$curdir/debian/stalag13";
my $main = "utils-ahem";

# get list of files that changed since the latest release
# number of commits
my $commits;
open(LATESTIS, "< $curdir/LATESTIS");
while (<LATESTIS>) { $commits = $_;}
close(LATESTIS);
chomp($commits);
# list of changed files
my %changed;
open(CHANGED, "git log --name-only -n $commits |");
while(<CHANGED>) {
    next if /^commit /;
    next if /^Author\: /;
    next if /^Date\: /;
    next if /^$/;
    next if /^\s/;
    # we dont need to be very selective since we just want a list of files
    chomp();
    $changed{"/$_"} = 1;    
}
close(CHANGED);
# need also to get every directory within the path of updated files in the list
for my $file (keys %changed) {
    while ($file =~ /\//) {
	$file = dirname($file);
	$changed{$file} = 1;
	last if $file eq "/";
    }
}
print "Changed since $commits commit(s):\n  ";
for my $file (keys %changed) {
    print "$file ";
}
print "\n";
  
# handpick files or directories
my %packages = (utils => ["/etc/bash_completion.d", "/etc/bashrc.d", "/etc/profile.d", "/usr/local/bin/qrename.pl", "/usr/local/bin/flonkout.pl", "/usr/local/bin/4-2cal.pl", "/usr/local/bin/switch-sound.pl", "/usr/local/bin/urlize.pl", "/usr/local/bin/wakey.pl", "/etc/default/shush-toram", "/etc/init.d/shush-toram", "/etc/cron.daily/shush-toram", "/etc/network"],
		keyring => ["/etc/apt/apt.conf.d/stalag13", "/etc/apt/sources.list.d/50-stalag13.list", "/etc/apt/trusted.gpg.d/stalag13.gpg"],
		"utils-cache-apt" => ["/etc/nginx/sites-available/cache-apt", "/etc/cron.weekly/cache-apt"],
		"utils-cache-steam" => ["/etc/nginx/sites-available/cache-steam", "/etc/cron.daily/cache-steam"],
		"utils-cache-spoof" => ["/etc/bind", "/usr/local/bin/update-bind-ads-block.pl"],
		"utils-exim" => ["/etc/exim4", "/usr/local/bin/memcached-exim.pl"],
		"utils-nginx" => ["/etc/init.d/perl-fcgi", "/etc/init.d/php-fcgi", "/etc/nginx/cache_proxy_params", "/etc/nginx/allow_local", "/etc/nginx/sites-available/fcgi", "/usr/local/bin/fastcgi-wrapper.pl"],
		"utils-ssl" => ["/etc/dovecot/certs", "/etc/nginx/certs", "/etc/ssl"],
		"utils-cloud" => ["/usr/share/owncloud", "/etc/nginx/sites-available/cloud"],
		"utils-webmail" => ["/usr/share/squirrelmail", "/etc/nginx/sites-available/webmail", "/usr/local/bin/carddav2abook.pl"],
		"utils-torrent" => ["/usr/local/bin/torrent-watch.pl", "/etc/cron.d/torrent", "/etc/cron.weekly/torrent", "/etc/logrotate.d/torrent"],
		"utils-tumblr" => ["/usr/local/bin/post-image-to-tumblr-init-auth.pl", "/usr/local/bin/post-image-to-tumblr.pl", "/usr/local/lib/site_perl/WWW/Tumblr.pm", "/usr/local/lib/site_perl/WWW/Tumblr"]
    );

# move them
open(NOTUPDATED, ">$curdir/debian/notupdated");
for my $package (keys %packages) {
    my $updated = 0;
    print "Repacking $package with:\n";
    foreach (@{$packages{$package}}) {	
	print "  $_";
	if (exists($changed{$_})) {
	    print " UPDATED";
	    $updated = 1;
	}
	print "\n";
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

    # no file in the package was not updated? 
    next if $updated;
    # not main utils package that we always want up to date no matter what?
    next if $package eq "utils";
    # not selected by hand for rebuild?
    if (-e "$curdir/debian/$package.rebuild") {
	unlink("$curdir/debian/$package.rebuild");
	print "  => no changes but will be updated since debian/?.rebuild exists\n";
	next;
    }
    
    print "  => no changes, won't be updated\n";
    # then register the information for later
    print NOTUPDATED "$package\n";
}
close(NOTUPDATED);
