#!/usr/bin/perl
#
# Copyright (c) 2011-2012 Mathieu Roy <yeupou--gnu.org>
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

use strict "vars";
use Fcntl ':flock';
use POSIX qw(strftime);
use File::Basename;
use File::Copy;

my $user = "klink";
my $maindir = "/storage/abstract/musique";
my $importdir = "/storage/abstract/musique/.A TRIER";
my $debug = 1;

# enter working directories
chdir($maindir) or die "Unable to enter $maindir. Exit";

# identify styles available
opendir(STYLES, $maindir);
my @style;
while (defined(my $dir = readdir(IMPORT))) {
    # silently ignores anything but standard directories
    next unless -d $dir;
    next if $dir eq "." or $dir eq "..";
    next if $dir =~ /^\..*/;

    push(@style, $dir);

}
closedir(STYLES);


# now enter import dir
chdir($importdir) or die "Unable to enter $importdir. Exit";

# in $importdir, there should be dirs containing, each one, an album, 
# without a file named import with the following content
#     style|band|album|year
# the purpose of this script is to create such file
opendir(IMPORT, $importdir);
while (defined(my $dir = readdir(IMPORT))) {
    # silently ignores anything but standard directories
    next unless -d $dir;
    next if $dir eq "." or $dir eq "..";

    # ignores directories with no import file within
    print "Fichier $dir/import disponible, dossier ignoré.\n" if -e "$dir/import";
    next if -e "$dir/import";

    # go inside the directory and try to get tags for an ogg or mp3 or else
    my $band;
    my $album;
    my $style;
    my $year;
    opendir(ALBUMDIR, $dir);
    while (defined(my $file = readdir(ALBUMDIR))) {
	# ignore dirs
	next if -d $file;

	# find out suffix, ignore file if none found
	my $suffix = 0;
	my $realfile;
	if ($file =~ /^(.*)(\.[^.]*)$/) { $suffix = $2; $realfile = $1; }
	next unless $suffix && $realfile;
	next unless ($suffix eq ".ogg" or $suffix eq ".mp3" or $suffix eq ".flac");
	
	# if a music file, extract the tag
	print "Extract tags from $dir/$file\n";
	open(ALBUMINFO, "lltag --id3v2 -S $importdir/$dir/$file|");
	while(<ALBUMINFO>) {
	    $band = $1 if /ARTIST=(.*)$/;
	    $album = $1 if /ALBUM=(.*)$/;
	    $style = $1 if /GENRE=(.*)$/;
	    $year = $1 if /DATE=(.*)$/;
	    last if ($band and $album and $style and $year);
	}
	close(ALBUMINFO);

	# if we get here, we had at least one file with all relevant info, exit
	last if ($band and $album and $style and $year);
    }

    print "So far, we found $dir to contain:\n";
    print "\t($style|$band|$album|$year)\n";
       
}
closedir(IMPORT);

# EOF
