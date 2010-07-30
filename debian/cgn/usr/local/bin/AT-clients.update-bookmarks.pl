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
# $Id: AT-clients.update-bookmarks.pl,v 1.3 2006-03-23 17:22:00 moa Exp $

use Sys::Hostname;

do "/etc/hosts.nib.pl" or exit;
exit if hostname() eq $server;
exit if hostname() eq "ulysse";

my @users = ("moa", "egh");
my $konquidir = ".kde/share/apps/konqueror"; # useless so far
my $cvsdir = "racine";
my $bookmarks = "bookmarks.xml";

for my $user (@users) {
    # egh have racine hidden
    $cvsdir = ".racine" if $user eq "egh";

    # skip if no monitored file exist
    next unless -e "/home/$user/$cvsdir/$bookmarks";

    # move the cvs directory
    chdir("/home/$user/$cvsdir/");

    # get
    `su $user -c "cvs update $bookmarks >/dev/null 2>/dev/null"`;

    # send
    `su $user -c "cvs ci -m 'Automated update' $bookmarks >/dev/null 2>/dev/null"`;
}
