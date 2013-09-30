#!/usr/bin/perl
#
# Copyright (c) 2013 Mathieu Roy <yeupou--gnu.org>
#   http://yeupou.wordpress.com
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
# Monitor connectivity on a main device. If it's off after a defined time,
# start another device and keep it up until the main device is back for
# at least the defined time.
# It is a daemon and should be started by an appropriate init script.


# store IP when it works so later we wont get in trouble because of temporary
# DNS failure

# update /var/www/netinfo

use strict;
use Sys::Hostname;
use Getopt::Long;
use Net::Ping;

my ($getopt, $save, $help);
my $dev_main = "eth0";
my $dev_backup = "wlan0";

eval {
    $getopt = GetOptions("help" => \$help,
			 "main-device=s" => \$dev_main,
			 "backup-device=s" => \$dev_backup);
};


if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

    
      --main-device=eth0     Main internet access device
      --backup-device=wlan0  Backup internet access device

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF


exit(1);
}




## Run


# check every n seconds if we can connect

# 78.249.90.254 ?

  # ip r
#default via 78.249.90.254 dev eth1 
#78.249.90.0/24 dev eth1  proto kernel  scope link  src 78.249.90.43 
#192.168.1.0/24 dev eth2  proto kernel  scope link  src 192.168.1.1 

08 19:16 klink@bender: ~
  $ netstat -rn
Table de routage IP du noyau
Destination     Passerelle      Genmask         Indic   MSS Fenêtre irtt Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG        0 0          0 eth2




my $host = "78.249.90.254";
my $p = Net::Ping->new("udp",5,1,$dev_main);
if ($p->ping($host)) {
    print "$host is alive on $dev_main\n";
} else {
    print "$host is dead on $dev_main\n";
}
$p->close();




# EOF
