#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/stalag13-cleanup-music-directory-01-identify.pl
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
use Term::ANSIColor qw(:constants);
use Term::ReadKey;
my ($columns) = GetTerminalSize();;
my $clear = `clear`;
use Text::Wrap qw(&wrap $columns);

# config:
my $maindir = "/storage/abstract/musique";
my $importdir = "/storage/abstract/musique/.A TRIER";
my $editor = "emacs";

# enter working directories
chdir($maindir) or die "Unable to enter $maindir. Exit";

# identify styles available (set with 0 = null, to ease user input later)
opendir(STYLES, $maindir);
my @style = ("null");
print "Found style... ";
while (defined(my $dir = readdir(STYLES))) {
    # silently ignores anything but standard directories
    next unless -d $dir;
    next if $dir eq "." or $dir eq "..";
    next if $dir =~ /^\..*/;

    print "$dir... ";
    push(@style, $dir);

}
closedir(STYLES);
print "\n\n\n";


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

    # ignores directories with already import file within
    print ON_RED, WHITE, "$dir/import already available, skip directory.\n", RESET if -e "$dir/import";
    next if -e "$dir/import";

    # ignores directories flagged
    print ON_RED, WHITE, "$dir/ignore exists, skip directory.\n", RESET if -e "$dir/ignore";
    next if -e "$dir/ignore";



    # go inside the directory and try to get tags for an ogg or mp3 or else
    my ($band, $album, $style, $year);
    opendir(ALBUMDIR, $dir);
    while (defined(my $file = readdir(ALBUMDIR))) {
	# ignore dirs
	next if -d $file;

	# find out suffix, ignore file if none found
	my $suffix = 0;
	my $realfile;
	if ($file =~ /^(.*)(\.[^\.]*)$/) { $suffix = lc($2); $realfile = $1; }
	next unless $suffix && $realfile;
	next unless ($suffix eq ".ogg" or $suffix eq ".mp3" or $suffix eq ".flac");
	
	# if a music file, extract the tag
	print ON_BLUE, WHITE, "Extract tags from $file\n", RESET;
	open(ALBUMINFO, "lltag --id3v2 -S \"$importdir/$dir/$file\" |");
	while(<ALBUMINFO>) {
	    $band = $1 if /\sARTIST=(.*)$/i;
	    $album = $1 if /\sALBUM=(.*)$/i;
	    $style = $1 if /\sGENRE=(.*)$/i;
	    $year = $1 if /\sDATE=(.*)$/i;
	    last if ($band and $album and $style and $year);
	}
	close(ALBUMINFO);

	# if we get here, we had at least one file with all relevant info, exit
	last if ($band and $album and $style and $year);
    }

    # Provides first results,
    print "So far, we found ", BOLD $dir, RESET " to contain:\n";
    print "\t$style|$band|$year|$album\n";
    print "> ", BOLD "Y", RESET "es/enter or ", BOLD "E", RESET "dit or ", BOLD "I", RESET "gnore or\n> ", BOLD "S", RESET "et to various artists or set style to\n> ";
    # show style list (not refreshed after first start)
    for (my $i = 1; $i < scalar(@style); $i++) {
	print BOLD "$i", RESET ") ".$style[$i]." ";
    }
    print "\n";
    
    # Ask for confirmation
    my $stdin;
    chomp($stdin = <STDIN>);

    # If S was typed, set band to various artists (this tag should be
    # unique enough, I dont think a band with such name exists)
    if (lc($stdin) eq "s") {
	$band = "-----VARIOUS ARTISTS-----";
	# in this case, always review/edit
	$stdin = "e";
    }

    # Ignore if I was typed (create ignore file so it will be ignored the next
    # run
    if (lc($stdin) eq "i") {
	system("touch", "$dir/ignore");
	next;
    }

    # If a digit is typed, change the style to the relevant one
    if ($stdin =~ m/^\d*$/ and $stdin != 0) {
	$style = $style[$stdin];
	print "\t$style|$band|$year|$album\n";
    }

    # Create the import file
    open(IMPORT, "> $dir/import");
    print IMPORT "$style|$band|$year|$album\n";
    close(IMPORT);

    # If E was typed, then fire up emacs to edit it
    system($editor, "$dir/import", "-nw") if (lc($stdin) eq "e"); 
    
    print "\n\n";
}
closedir(IMPORT);

# EOF
