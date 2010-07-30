#!/usr/bin/perl
#
# Copyright 2004 (c) Vincent Caron <zerodeux@gnu.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

use strict;
use Getopt::Long;
use POSIX;

# Maximum number of 'old' backup to remove in order to free some disk space
#
my $max_free_pass = 5;

my ($getopt, $dest, $log, $debug, $max);

eval {
    $getopt = GetOptions("dest=s" => \$dest,
			 "log=s" => \$log,
			 "debug" => \$debug,
			 "max=i" => \$max);
};
$dest = "/backups" if not defined $dest;

die "Unable to enter '$dest', exiting" if not chdir($dest);

print strftime('%Y-%m-%d %H:%M:%S', localtime())." [bak-makespace] checking disk space in '$dest'\n\n";

# Grab the tarball collection written during the last 24h
#
my $prev_backup_files = `find . -maxdepth 1 ! -name 'lost+found' -and ! -name '.'  -and -type d | tail -n1`;
chomp($prev_backup_files);
my $prev_backup_size  = $prev_backup_files ne '' ? `du -cm $prev_backup_files|grep total|cut -f1` : 0;
chomp($prev_backup_size);
print "* prev_backup_files: $prev_backup_files\n";
print "* prev_backup_size : $prev_backup_size (MB)\n";

sub get_available {
    if (defined $max) {
        # Compute what's used, and see what's left to reach $max
        my $avail = $max - (split / +/, `du -sm '$dest'`)[0];
        return $avail > 0 ? $avail : 0;
    } else {
        # No explicit size max, use 'disk free' value
        return (split / +/, `df -m '$dest'|grep /`)[3];
    }
}

my $pass;

# Remove oldest tarballs to free some disk space
#
for ($pass = 1; ; $pass++) {
    my $available = get_available();
    print "* get_available    : ".get_available()." (MB)\n";
    last if ($available > $prev_backup_size);

    if ($pass > $max_free_pass) {
        print "\nWARNING: could not make enough room in $max_free_pass passes, giving up.\n";
        last;
    }

    print "* deleting some old files (pass #$pass)\n";
    my @oldest_backup_files = split /\n/, `ls -1rSt --ignore="lost+found" | head -n1`;

    my $free = 0;
    for my $file (@oldest_backup_files) {
        my $size = `du -cm $file|grep total|cut -f1`;
        print "   removing $file ($size MB)\n";
	system("/bin/rm", "-rf", $file) if not $debug;
        $free += $size;
    }
    print "   freed $free MB\n";
}
print "\n";

# EOF
