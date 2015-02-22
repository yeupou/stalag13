#!/usr/bin/perl -w
# http://prefetch.net/blog/index.php/2006/05/27/using-bind-to-reduce-ad-server-content/
# run by /etc/cron.weekly/update-bind-ads-block > /etc/bind/named.conf.ads
#
# Program: Create zone entries for ad servers <updateads.pl>
#
# Author: Matty <matty91 at gmail dot com>
#
# Current Version: 1.0
#
# Revision History:
#
#  Version 1.0
#   Original release
#
# Last Updated: 05-22-2006
#
# Purpose:
#        Generates zone files with wild card IN A records for ad servers
#
# Notes:
#        null.zone consists of the following (from http://pgl.yoyo.org/adservers/):
#
#         $TTL    86400
#
#         @       IN      SOA     ns.domain.com      hostmaster.domain.com. (
#                                 2002061000       ; serial number YYMMDDNN
#                                 28800   ; refresh  8 hours
#                                 7200    ; retry    2 hours
#                                 864000  ; expire  10 days
#                                 86400 ) ; min ttl  1 day
#                         NS      ns.domain.com.
#
#                         A       127.0.0.1
#
#         *               IN      A       127.0.0.1
#
# License:
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


# You can choose between wget or curl. Both rock!
# my $snagger = "curl -q";
my $snagger = "wget -q -O - ";

# If you want the "zone" entries appended to an existing named.conf,
# specify it here. The entries will be appended with a timestamp.
# my $named = "named.conf";

# List of URLs to find ad servers.
my @urls = ( "http://pgl.yoyo.org/adservers/serverlist.php?showintro=0;hostformat=hosts" );

# If $named isn't NULL, dump it before the domains
if ( defined $named ) {
    open(NAMED, $named);

    while ( <NAMED> ) {

        if ( $_ !~ /Added domains on/ ) {
             print $_;
         } else {
             last;
         }
    }
}

# Grab the list of domains and add them to the realm file
foreach $url (@urls) {

    # Open the curl command
    open(CURL, "$snagger $url |") || die "Cannot execute $snagger: $@\n";

    printf( "// *** Added domains on %s *** //\n\n", scalar localtime);

    while (<CURL>) {
         chomp;

         # Should take care of host files in the following format: name
         if ( $_ =~ /^[0-9a-zA-Z\-]+\.[0-9a-zA-Z\-]+$/) {
              printf("zone \"%s\" { type master\; notify no\;", $_);
              print  " file \"/etc/bind/db.ads\"\; }\;\n";
         }
    }
}

# EOF
