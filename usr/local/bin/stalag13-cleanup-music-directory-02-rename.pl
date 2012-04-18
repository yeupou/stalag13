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
use Getopt::Long;

# config:
my $user = "klink";
my $maindir = "/storage/abstract/musique";
my $importdir = "/storage/abstract/musique/.A TRIER";
my $debug = 0;
my $getopt;


# get standard opts with getopt
eval {
    $getopt = GetOptions("debug" => \$debug);
};

if ($debug) {
    print "DEBUG MODE:\n";	     
    <STDIN>;
}

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

    # ignores flagged directories
    print "Fichier $dir/ignore, dossier ignoré.\n" if -e "$dir/ignore";
    next if -e "$dir/ignore";


    # otherwise, find out band name and all
    open(ALBUMINFO, "< $dir/import");
    my $style;
    my $is_va = 0;
    my $band;
    my $album;
    my $year = "0000";
    while (<ALBUMINFO>) {
	chomp($_);
	($style,$band,$year,$album) = split(/\|/, $_);
	last;
    }
    close(ALBUMINFO);

    # check we have something valid
    die "style = $style; band = $band ; album = $album, exit working $dir " unless ($style and $band and $album);

    # various artists case
    $is_va = 1 if ($band eq "-----VARIOUS ARTISTS-----");

    # create the destination directory,
    # FIXME: seems to be some issues with accentued characters, not sure
    # why.
    my $destdir = "$maindir/$style/$band/$album";
    $destdir = "$maindir/$style/$band/$year-$album" if $year;
    $destdir = "$maindir/$style/$album" if $is_va;
 
    if (-d "$destdir") {
	print "$destdir existe déjà!\n";
	<STDIN>;
    } else  {
	system("/bin/mkdir", "-p", $destdir) unless $debug;
	print "/bin/mkdir -p $destdir\n";
    }
    
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
	if ($file =~ /^(.*)(\.[^.]*)$/) { $suffix = lc($2); $realfile = $1; }
	next unless $suffix && $realfile;
	
	# if image, simply move it
	if ($suffix eq ".png" or $suffix eq ".jpg") {
	    print "mv $file $destdir/\n";
	    move("$importdir/$dir/$file", "$destdir") unless $debug;
	}
	
	# if mp3 or ogg, use lltag to update tag and rename
	if ($suffix eq ".ogg" or $suffix eq ".mp3" or $suffix eq ".flac") {

	    # lltag is buggy with ogg files, it fails sometimes to find
	    # out the NUMBER and TITLE tags values on the fly. Extract them
	    # beforehand
	    my @lltag_opts = ();
	    if ($suffix eq ".ogg") {
		print "Extract TITLE and NUMBER tags from $file... ";
		open(ALBUMINFO, "lltag -S \"$importdir/$dir/$file\" |");
		my ($title, $number);
		while(<ALBUMINFO>) {
		    $title = $1 if /\sTITLE=(.*)$/i;
		    $number = $1 if /\sTRACKNUMBER=(.*)$/i;
		    last if ($title and $number);
		}
		close(ALBUMINFO);
		print "$number, $title\n";
		@lltag_opts = ("--TITLE", $title,
			       "--NUMBER", $number);
	    }

	    # Various artists
	    if ($is_va) {
		# always extract the correct band name
		# (yes, not uberclean to call so many times lltag, but let's
		# keep it stupid/simple)
		$band = "";
		print "Extract BAND from $file (various artists)... ";
		open(ALBUMINFO, "lltag -S \"$importdir/$dir/$file\" |");
		while(<ALBUMINFO>) {
		    $band = $1 if /\sARTIST=(.*)$/i;
		    last if $band;
		}
		close(ALBUMINFO);
		print "$band\n";

		# add specific tags (try to set the usual ones)
		push(@lltag_opts, ("--tag", "ALBUMARTIST=$album"), ("--tag", "TPE2=$album"));
	    }
	    
	    if ($debug) {		
		system("lltag", "--dry-run", "--preserve-time", "--yes",
		       "--id3v2",
		       "--ARTIST", $band,
		       "--ALBUM", $album,
		       "--DATE", $year,
		       "--maj",
		       "--GENRE", $style,
		       @lltag_opts,
		       "--rename-min",
		       "--rename-slash", "_",
		       "--rename", "$destdir/%a-%d-%A-%n-%t",
		       "$importdir/$dir/$file");
		<STDIN>;
	    } else {
		system("lltag", "--preserve-time", "--yes", "--quiet",
		       "--id3v2",  
		       "--ARTIST", $band,
		       "--ALBUM", $album,
		       "--DATE", $year,
		       "--maj",
		       "--GENRE", $style,
		       @lltag_opts,
		       "--rename-min",
		       "--rename-slash", "_",
		       "--rename", "$destdir/%a-%d-%A-%n-%t",
		       "$importdir/$dir/$file");
	    }
	}
    }
    closedir(ALBUMDIR); 
    
    # more cleanups
    print "/usr/bin/urlize -D $destdir\n";
    system("/usr/bin/urlize", "-D", $destdir) unless $debug;
    print "/bin/chown -R $user:$user $maindir/$style/band/\n";
    system("/bin/chown", "-R", "$user:$user", "$maindir/$style/$band/") unless $debug;
    print "/bin/chmod -R a+r $maindir/$style/$band/\n";
    system("/bin/chmod", "-R", "a+r", "$maindir/$style/$band/") unless $debug;
    
    # if we get here, everything was moved, we can safely eraze initial dir
    print "rm -rvf $importdir/$dir\n";
    system("/bin/rm", "-rf", "$importdir/$dir") unless $debug;
}
closedir(IMPORT);

# EOF
