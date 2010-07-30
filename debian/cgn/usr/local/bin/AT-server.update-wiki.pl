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
# $Id: AT-server.update-wiki.pl,v 1.5 2006-12-10 11:12:14 moa Exp $

use Sys::Hostname;
use CGI qw(:standard Link);

do "/etc/hosts.nib.pl" or exit;
exit unless $server;
exit if hostname() ne $server;

$wikidb = "/var/www/wiki/database";
exit unless -e $wikidb;
chdir $wikidb; 

# First update existing files
system("svn", "-q", "update");
# Try to add new ones
`svn -q add * >/dev/null 2>/dev/null`;
# Commit changes
system("svn", "-q", "ci", "-m", "'Automated update'");
# Update mode
system("chmod", "g+rw", "-R", $wikidb);
system("chgrp", "www-data", "-R", $wikidb);


# EOF

