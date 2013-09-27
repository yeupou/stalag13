#!/usr/bin/perl
#
# Copyright (c) 2003-2013 Mathieu Roy <yeupou--gnu.org>
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
# Set up a firewall with active NAT, for Linux >= 2.4 with iptables

use strict;
use Sys::Hostname;
use Getopt::Long;

my ($getopt, $save, $help);
my $dev_internet = "eth0";
my $dev_intranet = "eth1";
my $initscript = "/etc/init.d/coupefeu";

eval {
    $getopt = GetOptions("help" => \$help,
                         "save" => \$save,
			 "internet=s" => \$dev_internet,
			 "intranet=s" => \$dev_intranet);
};


if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

Set-up a basic gateway firewall, with NAT if intranet device is set. 
This script is crude and will not attempt to check whether the devices
 actually exists. 

The general policy will be to accept anything outgoing and nothing ingoing,
except replies to requests made from inside and ingoing on servers ports.
As matter of principle, you should not count on a firewall to protect servers
not meant to be of public access but configure them to listen on the proper
ports.
This script will neither protect you against rootkits.

In general, if you just want a simple firewall for a normal workstation, you\'d
better use something like firehol, fwbuilder, etc.

It is not meant to be run on startup but, instead, to setup rules to be
saved and reused with /etc/init.d/coupefeu
    
      --internet=ethX        Internet device (default: $dev_internet)
      --intranet=ethX        Extranet device, if 0 no NAT will be
                             configured (default: $dev_intranet)
      --save                 Update configuration of $initscript
                             so effects are kept after reboot

Author: yeupou\@gnu.org
        http://yeupou.wordpress.com/
EOF
exit(1);
}

################### hardcoded CONFIGURATION

# input
my @open_iports = (
    "21",  # ftp
    "22", # ssh 
    "22221", #
    "22222", # 
    "22223", # 
    "22224", # 
    "23",  # telnet
    "25",  # smtp
    "115", # sftp
    "194", # irc
    "443", # https
    "465", # ssmtp
    "993", # imaps
    "51413", # extra
    "16222", # extra
    "16224", # extra
    "6882",  # extra
    "6881",  # extra
    "22221", # extra
    "22222", # extra
    "22223", # extra
    "22224" # extra
); 

# output
my @open_oports = ();

# forward
my @open_fports = ();
my $open_fports_destination = "192.168.1.9";


################### RUN!

# Clean up previous rules
system($initscript,
       "clear");


# default policy, close the door
`iptables -P INPUT DROP`;
`iptables -P FORWARD DROP`;
`iptables -P OUTPUT ACCEPT`;  # first, we close the input and
                             # forward ; output is a second
                             # matter
       
# accept traffic on the loopback device
`iptables -A INPUT -i lo -j ACCEPT`;
`iptables -A OUTPUT -o lo -j ACCEPT`; 
`iptables -A FORWARD -i lo -j ACCEPT`; 
`iptables -A FORWARD -o lo -j ACCEPT`;

# close anything that pretend to come from 127.0.0.1 over the network card
# (some virii do that)
# it must be a prerouting entry, otherwise it will be dropped after being
# logged by the kernel.
# (it requires iptables_nat to be loaded)
`iptables -t nat -I PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP`;

# accept anything that come from the local ethernet
`iptables -A INPUT -i $dev_intranet -j ACCEPT`;
`iptables -A OUTPUT -o $dev_intranet -j ACCEPT`;
`iptables -A FORWARD -i $dev_intranet -j ACCEPT`;
`iptables -A FORWARD -o $dev_intranet -j ACCEPT`;

# accept anything that we initiated
`iptables -A INPUT -i $dev_internet -m state --state ESTABLISHED,RELATED -j ACCEPT`;
`iptables -A OUTPUT -o $dev_internet -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT`;

# create the NAT
`iptables -A FORWARD -i $dev_internet -o $dev_intranet -m state --state ESTABLISHED,RELATED -j ACCEPT`;
`iptables -A FORWARD -i $dev_intranet -o $dev_internet -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT`;
`iptables -A POSTROUTING -t nat -o $dev_internet -j MASQUERADE`;

# open specifically requested ports on input
foreach my $port (@open_iports) {
    `iptables -A INPUT -i $dev_internet -p tcp --dport $port -j ACCEPT`;
    `iptables -A INPUT -i $dev_internet -p udp --dport $port -j ACCEPT`;
}


# open the wanted ports on output, which means 
foreach my $port (@open_oports) {
    # accept return from established connections
    `iptables -A INPUT -i $dev_internet -p tcp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT`;
    `iptables -A INPUT -i $dev_internet -p udp --sport $port -m state --state ESTABLISHED,RELATED -j ACCEPT`;

    # create new connections in => out
    `iptables -A OUTPUT -o $dev_internet -p tcp --dport $port -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT`;
    `iptables -A OUTPUT -o $dev_internet -p udp --dport $port -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT`;
}

# specific connection tracking (passive ftp, irc/dcc)
`iptables -A INPUT -i $dev_internet -p tcp --sport 1024:65535 --dport 1024:65535 -m state --state ESTABLISHED,RELATED -j ACCEPT`;
`iptables -A OUTPUT -o $dev_internet -p tcp --sport 1024:65535 --dport 1024:65535 -m state --state ESTABLISHED,RELATED -j ACCEPT`;

# forward specific ports
foreach my $port (@open_fports) {
    `iptables -A INPUT -i $dev_internet -p tcp --dport $port -j ACCEPT`;
    `iptables -t nat -A PREROUTING -p tcp -i $dev_internet --dport $port -j DNAT --to $open_fports_destination:$port`;
    `iptables -A FORWARD -p tcp -i $dev_internet -d $open_fports_destination --dport $port -j ACCEPT`;
}


# allow ping, only 10/m in input
`iptables -A OUTPUT -o $dev_internet -p icmp -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT`;
`iptables -A INPUT -i $dev_internet -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT`;
`iptables -A INPUT -i $dev_internet -p icmp -m state --state NEW -m limit --limit 10/min -j ACCEPT`;

if ($save) {
    # backup the original file
    `cp -fv /var/lib/iptables/active /var/lib/iptables/activebak`;
    # create the new file
    `iptables-save > /var/lib/iptables/active`;
}

# EOF
