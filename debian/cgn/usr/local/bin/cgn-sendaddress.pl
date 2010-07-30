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
# $Id: cgn-sendaddress.pl,v 1.4 2004-11-24 18:38:20 moa Exp $

print "DEPRECATED\n";
exit;

use strict;
use warnings;
use Getopt::Long;
use Sys::Hostname;


my $getopt;
my $help;
my $address;
my $lock = "/var/lock/cgn-sendaddress";
my $tmpfile = "/tmp/".hostname()."sendaddress";

eval {
    $getopt = GetOptions("help" => \$help,
			 "address=s" => \$address);
};

if ($help || ! $address) {
    print "Option possible : --address xxx.xxx.xxx.xxx\n";
    exit;
}

exit if -e $lock;
system("/usr/bin/touch", $lock);

open(TMP, "> $tmpfile");
print TMP $address;
close(TMP);

system("/usr/bin/scp",
       $tmpfile,
       "cgn-".hostname()."\@hephaistos.attique.org:/home/cgn/".hostname()."/.address");

unlink($tmpfile);
unlink($lock);

