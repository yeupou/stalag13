#!/usr/bin/perl
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
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
#   - ~/.tumblrrc must be set containing username= and password= and 
#   eventualy content= as path
#
# This was designed to be set up as a daily cronjob

use strict;
use locale;
use File::HomeDir;
use WWW::Mechanize;

my $git = "/usr/bin/git";

print @INC;

# First thing first, user read config
my $rc = File::HomeDir->my_home()."/.tumblrrc";
my $content = File::HomeDir->my_home()."/tmp/tumblr";
my ($tumblr_user, $tumblr_password);
die "Unable to read $rc, exiting" unless -r $rc;
open(RCFILE, "< $rc");
while(<RCFILE>){
    $tumblr_user = $1 if /^user\s?=\s?(\S*)\s*$/i;
    $tumblr_password = $1 if /^password\s?=\s?(\S*)\s*$/i;
    $content = $1 if /^content\s?=\s?(.*)$/i;
}
close(RCFILE);
die "Unable to determine user (found: $tumblr_user) and/or password (found: $tumblr_password) after reading $rc, exiting" unless $tumblr_user and $tumblr_password;
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


# Connect to tumblr
my $browser = WWW::Mechanize->new();
$browser->agent_alias("Linux Konqueror");
$browser->use_plugin('Ajax');

$browser->get("https://www.tumblr.com/login");
$browser->click("signup_button_login");
$browser->form_with_fields(('user[email]', 'user[password]'))
    or die "tumblr.com: Unable select the login form, exiting";
# try to set the login/password fields by lucky guess first
$browser->set_visible($tumblr_user, $tumblr_password); 
$browser->set_fields('user[email]' => $tumblr_user,
		     'user[password]' => $tumblr_password);
$browser->click("login_btn");
#$browser->submit(); 

print $browser->content();

print $browser->success.": ".$browser->uri.": ".$browser->response->status_line."\n";
#$browser->get("https://www.tumblr.com/new/photo");
#print $browser->success.": ".$browser->uri.": ".$browser->response->status_line."\n";
#print $browser->content;


# EOF
