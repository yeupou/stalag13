#!/usr/bin/perl

chdir("..") unless -e "README";
die "README not found, you must start this script at the root of the repository" unless -e "README";

# make general README
open(README, "> README");
print README  'Stuff completely useless, or almost, as described at # cd /scratch
Check http://yeupou.wordpress.com/

Debian packages are available. The easier way to get them is to get the keyring package as follows:
  	# wget http://apt.rien.pl/stalag13-keyring.deb
	# dpkg -i stalag13-keyring.deb
	# apt-get update
	# apt-get install ...

';

# list packages from debian/control
# (as this will be included with packages, important info must be in the
# description)
open(PACKAGES, "< debian/control");
while (<PACKAGES>) {
    next unless 
	s/^Package\: (.*)/$1:/ or
	/^Description\: / .. /^ \.$/;
    s/^Description\://g;
    s/^ \.//g;
    print README $_;
}
close(PACKAGES);
close(README);
