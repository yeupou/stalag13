#!/usr/bin/perl
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
#        http://yeupou.wordpress.com/
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
# Will go into $CONTENT where two subdirs exists: queue and over
# It will take the first file in queue (pulled with git) and post it to
# tumblr using WWW::Mechanize 
#
# If you want it to be absolutely random, you may just run, in queue/ the
# following:
#   for i in *; do mv "$i" `mktemp --dry-run --tmpdir=. -t XXXXXXX$i`; done
#
#   - content is by default ~/tmp/tumblr
#   - ~/.tumblrrc must be set containing email= and password= and 
#   eventualy content= as path
#
# This was designed to be set up as a daily cronjob

use strict;
use locale;
use File::HomeDir;
use File::Copy;
use Tumblr;
use POSIX qw(strftime);

my $debug = 0;
my $git = "/usr/bin/git";
$git = "/bin/echo" if $debug;


# First thing first, user read config
my $rc = File::HomeDir->my_home()."/.tumblrrc";
my $content = File::HomeDir->my_home()."/tmp/tumblr";
my ($tumblr_email, $tumblr_password);
die "Unable to read $rc, exiting" unless -r $rc;
open(RCFILE, "< $rc");
while(<RCFILE>){
    $tumblr_email = $1 if /^user\s?=\s?(\S*)\s*$/i;
    $tumblr_email = $1 if /^email\s?=\s?(\S*)\s*$/i;
    $tumblr_password = $1 if /^password\s?=\s?(\S*)\s*$/i;
    $content = $1 if /^content\s?=\s?(.*)$/i;
}
close(RCFILE);
die "Unable to determine email (found: $tumblr_email) and/or password (found: $tumblr_password) after reading $rc, exiting" unless $tumblr_email and $tumblr_password;
my $queue = $content."/queue";
my $over = $content."/over";

# Enter working directory
chdir($content) or die "Unable to enter $content, exiting";

# Update content with git
system($git, "pull", "--quiet");

# Enter the queue
chdir($queue) or die "Unable to enter $queue, exiting";

# Select an image
# If none found, silently exit
opendir(IMAGES, $queue);
my (@images, $image);
while (defined(my $image = readdir(IMAGES))) {
    next if -d $image;
    next unless -r $image;
    next unless $image =~ /\.(jpg|png|gif)$/i;
    push(@images, $image);
}
closedir(IMAGES);
exit if scalar(@images) < 1;
for (sort(@images)) { $image = $_; last; }

# Post to tumblr using https://github.com/damog/www-tumblr
my $tumblr = WWW::Tumblr->new;
$tumblr->email($tumblr_email);
$tumblr->password($tumblr_password);
($tumblr->write(type => 'photo', data => $image) or die $tumblr->errstr) unless $debug;
print "$image ===> $tumblr_email\n" if $debug;

# If we get here, we can assume everything went well. So move the
# file in the over directory and commit to git
chdir($content);
my $today = strftime("%Y%m%d", localtime);
move("$queue/$image", "$over/$today-$image") unless $debug;
print "mv $queue/$image $over/$today-$image\n" if $debug;
system($git, "add", $over);
system($git, "commit", "--quiet", "-am", "Posted by post-image-to-tumblr.pl");
system($git, "push", "--quiet");


# EOF
