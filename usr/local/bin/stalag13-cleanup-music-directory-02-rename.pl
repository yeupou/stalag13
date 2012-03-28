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
chdir($importdir) or die "Unable to enter $importdir. Exit";

# in $importdir, there should be dirs containing, each one, an album, 
# with a file named import with the following content
#     style|band|album|year
opendir(IMPORT, $importdir);
while (defined(my $dir = readdir(IMPORT))) {
    # silently ignores anything but standard directories
    next unless -d $dir;
    next if $dir eq "." or $dir eq "..";

    # ignores directories with no import file within
    print "Pas de fichier $dir/import (style|band|year|album), dossier ignoré.\n" unless -e "$dir/import";
    next unless -e "$dir/import";

    # otherwise, find out band name and all
    open(ALBUMINFO, "< $dir/import");
    my $style;
    my $band;
    my $album;
    my $year = "0000";
    while (<ALBUMINFO>) {
	chomp($_);
	($style,$band,$year,$album) = split(/\|/, $_);
    }
    close(ALBUMINFO);

    # create the destination directory, skip everything if it already exists
    my $destdir = "$maindir/".lc("$style/$band/$year-$album");
    print "$destdir existe déjà, dossier ignoré.\n" if -d "$destdir";
    next if -d "$destdir";
    system("/bin/mkdir", "-p", $destdir) unless $debug;
    print "/bin/mkdir -p $destdir\n";
    
    # now deals with each file within: 
    #  - move images to new dir
    #  - ogg or mp3, update tags, rename
    opendir(ALBUMDIR, $dir);
    while (defined(my $file = readdir(ALBUMDIR))) {
	# ignore dirs
	next if -d $file;

	# find out suffix, ignore file if none found
	my $suffix = 0;
	my $realfile;
	if ($file =~ /^(.*)(\.[^.]*)$/) { $suffix = $2; $realfile = $1; }
	next unless $suffix && $realfile;
	
	# if image, simply move it
	if ($suffix eq ".png" or $suffix eq ".jpg") {
	    print "mv $file $destdir/\n";
	    move("$importdir/$dir/$file", $destdir) unless $debug;
	}
	
	# if mp3 or ogg, use lltag to update tag and rename
	if ($suffix eq ".ogg" or $suffix eq ".mp3" or $suffix eq ".flac") {
	    system("lltag", "--dry-run", "--preserve-time", "--yes",
		   "--id3v2",
		   "--ARTIST", $band,
		   "--ALBUM", $album,
		   "--DATE", $year,
		   "--maj",
		   "--GENRE", $style,
		   "--rename-min",
		   "--rename-slash", "_",
		   "--rename", "$destdir/%a-%d-%A-%n-%t",
		   "$importdir/$dir/$file") if $debug;
	    system("lltag", "--preserve-time", "--yes", "--quiet",
		   "--id3v2",  
		   "--ARTIST", $band,
		   "--ALBUM", $album,
		   "--DATE", $year,
		   "--maj",
		   "--GENRE", $style,
		   "--rename-min",
		   "--rename-slash", "_",
		   "--rename", "$destdir/%a-%d-%A-%n-%t",
		   "$importdir/$dir/$file") unless $debug;
	}
    }
    closedir(ALBUMDIR); 
    
    # more cleanups
    print "/usr/bin/urlize -D $destdir\n";
    system("/usr/bin/urlize", "-D", $destdir) unless $debug;
    print "/bin/chown -R $user:$user $maindir/".lc("$style/$band/")."\n";
    system("/bin/chown", "-R", "$user:$user", "$maindir/".lc("$style/$band/")) unless $debug;
    print "/bin/chmod -R a+r $maindir/".lc("$style/$band/")."\n";
    system("/bin/chmod", "-R", "a+r", "$maindir/".lc("$style/$band/")) unless $debug;
    
    ## if we get here, everything was moved, we can safely eraze initial dir
    #print "rm -rvf $importdir/$dir";
    #system("/bin/rm", "-rf", "$importdir/$dir") unless $debug;
    # Ask to do it manually to avoid data loss
    print "Job done, now you should remove content of $importdir/$dir\n";
}
closedir(IMPORT);

# EOF
