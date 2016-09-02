#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/stalag13-cleanup-music-directory-02-rename.pl
#
#                                 |     |
#                                 \_V_//
#                                 \/=|=\/
#                                  [=v=]
#                                __\___/_____
#                               /..[  _____  ]
#                              /_  [ [  M /] ]
#                             /../.[ [ M /@] ]
#                            <-->[_[ [M /@/] ]
#                           /../ [.[ [ /@/ ] ]
#      _________________]\ /__/  [_[ [/@/ C] ]
#     <_________________>>0---]  [=\ \@/ C / /
#        ___      ___   ]/000o   /__\ \ C / /
#           \    /              /....\ \_/ /
#        ....\||/....           [___/=\___/
#       .    .  .    .          [...] [...]
#      .      ..      .         [___/ \___]
#      .    0 .. 0    .         <---> <--->
#   /\/\.    .  .    ./\/\      [..]   [..]
#
#!/usr/bin/perl
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
#      http://yeupou.wordpress.com
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
use Term::ANSIColor qw(:constants);

# config:
my $user = "klink";
my $maindir = "/storage/abstract/musique";
my $importdir = "/storage/abstract/musique/.A TRIER";
my $debug = 0;
my $getopt;
my $wentwell = 1;


# get standard opts with getopt
eval {
    $getopt = GetOptions("debug" => \$debug);
};

if ($debug) {
    print "DEBUG MODE: (type enter)\n";	     
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
    print ON_RED, WHITE, "No $dir/import (style|band|year|album), skip directory.\n", RESET unless -e "$dir/import";
    next unless -e "$dir/import";

    # ignores flagged directories
    print ON_RED, WHITE, "$dir/ignore exists, skip directory.\n", RESET if -e "$dir/ignore";
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
    unless ($style and $band and $album) {
	print ON_RED, WHITE, "Unable to get any info from the existing $dir/import file. style = $style; band = $band ; album = $album. Skip directory.\n", RESET;
	next;
    }

    # various artists case
    $is_va = 1 if ($band eq "-----VARIOUS ARTISTS-----");

    # create the destination directory,
    # FIXME: seems to be some issues with accentued characters, not sure
    # why.
    my $destdir = "$maindir/$style/$band/$album";
    $destdir = "$maindir/$style/$band/$year-$album" if $year;
    $destdir = "$maindir/$style/$album" if $is_va;
 
    if (-d "$destdir") {
	print ON_RED, WHITE, "$destdir already exists (check and type enter if ready)!\n", RESET;
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

	    # default name scheme
	    my $naming = "%a-%d-%A-%n-%t";

	    # lltag fails sometimes to find out the NUMBER and TITLE tags
	    # values on the fly. Extract them
	    # beforehand to avoid any trouble
	    my @lltag_opts = ();
	    print ON_BLUE, WHITE, "Extract TITLE and NUMBER tags from $file... ", RESET;
	    open(ALBUMINFO, "lltag --id3v2 -S \"$importdir/$dir/$file\" |");
	    my ($title, $number);
	    while(<ALBUMINFO>) {
		$title = $1 if /\sTITLE=(.*)$/i;
		$number = $1 if /\sTRACKNUMBER=(.*)$/i;
		$number = $1 if /\sNUMBER=(.*)$/i;
		last if ($title and $number);
	    }
	    close(ALBUMINFO);
	    print ON_BLUE, WHITE, "$number, $title\n", RESET;
	    if ($title eq "") {
		# missing title is always a no-go
		print ON_RED, WHITE, "Something is very wrong with $dir/$file, we failed to extract the title of the current song. Skip file.\n", RESET;
		$wentwell = 0;
		next;
	    }
	    if ($number eq "") {
		# track number is weird but acceptable, ask the user
		# after trying some lucky guess
		$number = $2 if $file =~ /(^|\D)(\d\d?)\D/;
		print BOLD, "Weird, we have no track number for this one.\n", RESET, "Care to provide some?\n(type ENTER to use the lucky guess ", BOLD, "$number", RESET, ")\n";	       
		my $stdin;
		chomp($stdin = <STDIN>);
		$number = $stdin unless $stdin eq "";
	    }
	    @lltag_opts = ("--TITLE", $title,
			   "--NUMBER", $number);
	
	    # Various artists
	    if ($is_va) {
		# always extract the correct band name
		# (yes, not uberclean to call so many times lltag, but let's
		# keep it stupid/simple)
		$band = "";
		print  ON_BLUE, WHITE, "Extract BAND from $file (various artists)... ", RESET;
		open(ALBUMINFO, "lltag --id3v2 -S \"$importdir/$dir/$file\" |");
		while(<ALBUMINFO>) {
		    $band = $1 if /\sARTIST=(.*)$/i;
		    last if $band;
		}
		close(ALBUMINFO);
		print  ON_BLUE, WHITE, "$band\n", RESET;

		# add specific tags (try to set the usual ones)
		push(@lltag_opts, ("--tag", "ALBUMARTIST=$album"), ("--tag", "TPE2=$album"));

		# specific naming scheme
		$naming = "%A-%d-%n-%a-%t";

		if ($band eq "") {
		    # missing band is a no-go here
		    print ON_RED, WHITE, "Something is very wrong with $dir/$file, we failed to extract the band of the current song while it is VA. Skip file.\n", RESET;
		    $wentwell = 0;
		    next;
		}
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
		       "--rename", "$destdir/$naming",
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
		       "--rename", "$destdir/$naming",
		       "$importdir/$dir/$file");
	    }
	}
    }
    closedir(ALBUMDIR); 
    
    # more cleanups
    print "/usr/local/bin/urlize -D $destdir\n";
    system("/usr/local/bin/urlize", "-D", $destdir) unless $debug;
    print "/bin/chown -R $user:$user $maindir/$style/band/\n";
    system("/bin/chown", "-R", "$user:$user", "$maindir/$style/$band/") unless $debug;
    print "/bin/chmod -R a+r $maindir/$style/$band/\n";
    system("/bin/chmod", "-R", "a+r", "$maindir/$style/$band/") unless $debug;
    
    # if we get here, everything was moved, we can safely eraze initial dir
    print "rm -rvf $importdir/$dir\n" if $wentwell;
    print ON_RED, WHITE, "$importdir/$dir kept as it is, some files we're not renamed proper!", RESET unless $wentwell;
    system("/bin/rm", "-rf", "$importdir/$dir") unless ($debug or !$wentwell);
}
closedir(IMPORT);

# EOF
