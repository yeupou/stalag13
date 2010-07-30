#!/usr/bin/perl
#
# Copyright (c) 2004 Mathieu Roy <yeupou@gnu.org>
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
# $Id: cgn-updateaddress.pl,v 1.12 2004-12-03 10:51:38 moa Exp $

use strict;
use warnings;
use Sys::Hostname;
use Getopt::Long;
use Net::DNS;

our $server;
do "/etc/hosts.nib.pl" or exit;
exit unless $server;
exit if hostname() ne $server;

my $getopt;
my $verbose;

eval {
    $getopt = GetOptions("verbose" => \$verbose);
};


my @hosts = ("ulysse.attique.org");
my $hostfile = "/etc/hosts.allow";
my $tmphostfile = "/etc/hosts.allow.tmp";

my @wannabe_addresses;

# get wannabe addresses (submitted via scp)
print "--- WANNABE ADRESSES ---\n" if $verbose;
# foreach my $host (@hosts) {
#     next unless -e "/home/cgn/$host/.address";
#     open(ADDRESS, "< /home/cgn/$host/.address");
#     while (<ADDRESS>) {
# 	print "$host -> $_ ..." if $verbose;
# 	last if m/^192\.168\.1.*/;
# 	push(@wannabe_addresses, $_);
# 	print "Registered\n" if $verbose;
# 	last;
#     }
#     close(ADDRESS);
# }
foreach my $host (@hosts) {
    my $res = Net::DNS::Resolver->new;
    my $query = $res->search($host);

    if ($query) {
	foreach my $rr ($query->answer) {
	    next unless $rr->type eq "A";
	    next if $rr->type =~ m/^192\.168\.1.*/;
	    print "$host -> ", $rr->address, " ... "
		if $verbose;
	    push(@wannabe_addresses, $rr->address);
	    print "Registered\n" if $verbose;	    
	}
    } else {
	print "Query failed for $host: ", $res->errorstring, "\n"
	    if $verbose;
    }

 }


# compare with currently registered addresses
print "--- REGISTERED ADRESSES ---\n" if $verbose;
open(OLD, "< $hostfile");
open(NEW, "> $tmphostfile");
while(<OLD>)
{
    next if(/^\# CGN MAGIC BEGIN/ .. /^\# CGN MAGIC END/);
    print NEW $_;
}
close(OLD);

print NEW "# CGN MAGIC BEGIN\n";
for (@wannabe_addresses) {
    print NEW "ALL: $_\n";
    print "$_\n" if $verbose;
    
}
print NEW "# CGN MAGIC END\n";

system("/bin/mv",
       $tmphostfile,
       $hostfile);


