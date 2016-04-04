#!/usr/bin/perl
#
#  Copyright 2010-2016 (c) Mathieu Roy <yeupou--gnu.org> 
#     http://yeupou.wordpress.com
#
# Thi program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# The Savane project is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with the Savane project; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
use strict;
use POSIX qw/setsid/;

my @redshift_opts=();
# now redshift include geoclue2 method to find location, use this
# instead of hardcoded location
#"-l", "48.799:2.505",
#"-t", "6500:3700");

# search for any redshift process in /proc
my @tokill;
opendir(PROC, "/proc");
while (defined(my $pid = readdir(PROC))) {
    # not a process if not a directory
    next unless -d "/proc/$pid";
    # not a process if not containing cmdline
    next unless -e "/proc/$pid/cmdline";
    # look out for redshift
    open(PID, "< /proc/$pid/cmdline");
    while (<PID>) {
	# with or without path
	next unless m/^redshift/ or m/^\/usr\/bin\/redshift/;
	push(@tokill, $pid);
    }
    close(PID);
}
closedir(PROC);


if (scalar(@tokill) > 0) {
    # if any process found
    # now kill these with SIGTERM (15), software termination
    kill(15, @tokill);
    
    # wait a bit and then make sure redshift is properly reset by using -x  
    sleep(1);
    system("redshift", "-x");
} else {
    # otherwise, just start a redshift process
    exec("redshift", @redshift_opts);
}

# EOF
