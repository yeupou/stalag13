#!/usr/bin/perl
#
# Copyright (c) 2006 Mathieu Roy <yeupou--gnu.org>
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
# $Id: AT-server.update-bookmarks-www.pl,v 1.7 2007-04-30 08:12:35 moa Exp $

use Sys::Hostname;
use CGI qw(:standard Link);

do "/etc/hosts.nib.pl" or exit;
exit unless $server;
exit if hostname() ne $server;

# Go

my @users = ("moa", "egh");
my $cvsdir = "racine";
my $bookmarks = "bookmarks.xml";
my $xsl = "/usr/share/xbel/xbel.xsl";

for my $user (@users) {
    # egh have racine hidden
    $cvsdir = ".racine" if $user eq "egh";

    # skip if no monitored file exist
    next unless -e "/home/cvs/cgn-home/$user/$cvsdir/$bookmarks,v";

    # move the www directory
    system("mkdir", "/var/www/$user") unless -e "/var/www/$user";
    chdir("/var/www/$user");

    # remove previous bookmarks, to avoid merge conflicts
    # (should not happen but it already did)
    system("rm", "-f", $bookmarks);

    # get
    `co -q -f /home/cvs/cgn-home/$user/$cvsdir/$bookmarks,v`;

    # convert
    `xsltproc $xsl $bookmarks > index.html`;

}

# Do it for the main server page
chdir("/var/www");
if (-e "/var/www/$bookmarks") {
    `xsltproc $xsl $bookmarks > index.html`;
}
