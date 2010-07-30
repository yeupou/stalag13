#!/usr/bin/perl

use strict;
use Getopt::Long;

my ($getopt, $depends, $provides, $version, $help);

eval {
    $getopt = GetOptions("help" => \$help,
			 "depends=s" => \$depends,
			 "provides=s" => \$provides,
			 "version=s" => \$version);
};

if ($help) {
    print "Options: --depends, --provides, --version\n";
    print "This script will build in the current dir a package for each\nentry in provides (separator = ,), with the given version,\n depending on the depends package\n";
    exit;
}

if (!$version || !$provides || !$depends) {
    print "Missing parameter\n";
    exit;
}

$provides =~ s/\ //g;
my @provides = split(",", $provides);

foreach my $item (@provides) {
    print "################# BUILDING $item #################\n\n";

    open(EQUIV, "> equiv");
    print EQUIV "Section: Equivs
Priority: Optional
Standards-Version: 3.5.10

Package: $item
Version: $version
Maintainer: <yeupou\@attique.in>
Depends: $depends
Provides: $item
Architecture: all
Copyright: equiv
Changelog: equiv.cl
Readme: equiv
Description: Equiv package for $depends $version
";
    close(EQUIV);

    open(CHANGELOG, "> equiv.cl");
    print CHANGELOG "$item ($version-1) unstable; urgency=low

  * New package

 -- root <yeupou\@attique.in>  Sat, 15 May 2004 14:20:01 +0200
";
    close(CHANGELOG);

    `equivs-build equiv`;
}

