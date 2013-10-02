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


# update /var/www/netinfo  with current availability and stats

use strict;
use Sys::Syslog;
use Fcntl ":flock";
use threads;
use threads::shared;
use Getopt::Long;
use Net::Ping;
use Socket;

#########  SETUP 

my ($getopt, $save, $help);
my $rcfile = "/etc/switch-accessrc";
my $dev_main = "eth0";
my $dev_backup = "wlan0";
my @hosts = ("free.fr", "wikipedia.org", "gnu.org");
my @hosts_override;
my $delay = 4;
my $debug = 0;               # internal
my $multiplier = 60;         # internal
my $acceptable_failures = 2; # internal

# rcfile if existing
if (-r $rcfile) {
    open(RCFILE, "< $rcfile");
    while(<RCFILE>) {
	next if /^#/;
	$dev_main = $1 if /^main-device\s?=\s?(\S*)\s*$/i;
	$dev_backup = $1 if /^backup-device\s?=\s?(\S*)\s*$/i;
	$delay = $1 if /^max-delay\s?=\s?(\S*)\s*$/i;
	$debug = 1 if /^debug\s*/i;
	$multiplier = $1 if /^multiplier\s?=\s?(\S*)\s*/i;
	@hosts_override = $1 if /^hosts\s?=\s?(\S*)\s*$/i;
    }
    close(RCFILE);
}


# Command line option (override rcfile)
eval {
    $getopt = GetOptions("help" => \$help,
			 "multiplier=n" => \$multiplier,
			 "debug" => \$debug,
			 "delay=n" => \$delay,
			 "hosts=s" => \@hosts_override,
			 "main-device=s" => \$dev_main,
			 "backup-device=s" => \$dev_backup);
};

# accept a coma-separated list of hosts
@hosts = split(/,/,join(',',@hosts_override)) if (scalar(@hosts_override));

# Print help
if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

Check whether internet access from the main device $dev_main is up 
against hosts @hosts.
If none of theses can be reached in a delay of $delay minutes, then switch
to the backup device $dev_backup.
   
      --main-device=ethX     Main internet access device
      --backup-device=wlanX  Backup internet access device
      --delay=N              Max delay in minute without connectivity
      --hosts=domain,domain,...  hosts to be checked against
                             (comma separated list with no spaces)
 
Alternatively, you can add a $rcfile file containing any option
on the form:

main-device=eth0
hosts=thisisp.com,thisdomain.net

(without leading --)

Author: yeupou\@gnu.org
 http://yeupou.wordpress.com/
EOF
exit(1);
}

############## RUN

# disallow concurrent run
open(LOCK, "< $0") or die "Failed to ask lock. Exiting";
flock(LOCK, LOCK_EX | LOCK_NB) or die "Unable to lock. This daemon is already alive. Exiting";

# start logging activity from now on
openlog("switch-access", "pid", "LOG_DAEMON");
syslog("info", "started with $dev_main as main and $dev_backup as backup");
syslog("info", "with additional debug info") if $debug;

# assume the network is on when started
my $dev_main_linkon :shared = 1;
my $dev_backup_on :shared = 0;

### Autonomous thread to activate the backup device or to deactivate
# exactly on delay
async { 
    while (sleep(($delay * $multiplier))) {
	syslog("info","main-device: $dev_main_linkon, backup-device: $dev_backup_on") if $debug;
	if ($dev_main_linkon) {
	    # Main device on:
	    # nothing to if backup is not up
	    next unless $dev_backup_on;
	    ####SHUTOOWN BACKUP
	    syslog("info", "$dev_main is back on line, shutting down $dev_backup");
	    $dev_backup_on = 0;
	} else {
	    # Main device off:
	    # nothing to do if we already activated backup device
	    next if $dev_backup_on;
	    ###BRING UP BACKUP 
	    syslog("info", "$dev_main is offline, bringing up $dev_backup");
	    $dev_backup_on = 1;
	}
    }
};

### Main doing connectivity checks every minute (more or less
# depending on how pings go themselves) on main device
# Every minute we check the first address. Only if it fails we try the second,
# and third hosts from the list.
#
# Note: if we succesfully pinged an address by name, we save the IP and we'll
# afterwards only ping the IP. So even if DNS get down, we wont mess with
# the connectivity. If we fail a ping by IP, then we'll retry by name
my %hosts_ip;
my %hosts_linkon;

# check every n seconds if we can connect
while (sleep($multiplier)) {
    syslog("info", "pinging hosts...") if $debug;
    # Ping domains one by one.
    foreach my $target (@hosts) {
	# Try to access by IP if registered
	my $target_ip = $target;
	$target_ip = $hosts_ip{$target} if exists($hosts_ip{$target});
	my $p = Net::Ping->new("udp",5,1,$dev_main);
	my $success = $p->ping($target_ip);
	$p->close();
	if ($success) {
	    # success: record it by incrementing a counter
	    # until it reach max number of accepted failures
	    $hosts_linkon{$target}++ 
		unless $hosts_linkon{$target} >= $acceptable_failures;
	    # record the IP if not done yet
	    $hosts_ip{$target} = inet_ntoa(inet_aton($target)) 
		unless exists($hosts_ip{$target});	    
	    # log 
	    syslog("info", "ping ok for $target_ip (".$hosts_linkon{$target}.")") if $debug;
	    # end the loop
	    last;
	} else {
	    # failure: decrement the link on counter
	    $hosts_linkon{$target}--
		unless $hosts_linkon{$target} < 1;
	    # remove the known IP
	    delete($hosts_ip{$target})
		if exists($hosts_ip{$target});
	    # log
	    syslog("info", "ping failed for $target_ip (".$hosts_linkon{$target}.")");
	    # continue the loop
	}
	
    }
   
    # One host up is enough. Check for any positive value.
    my $at_least_on_linkon = 0;
    while (my ($target,$linkon) = each(%hosts_linkon)) {
	# skip fast fails
	continue unless $linkon;
	# record the first valid entry
	$at_least_on_linkon = 1;
	last;
    }
    $dev_main_linkon = $at_least_on_linkon;
    syslog("info", "update main-device status to $dev_main_linkon") if $debug;
}

# EOF
