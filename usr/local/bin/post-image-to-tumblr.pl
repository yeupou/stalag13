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
#   - ~/.tumblrrc must be set containing consumer_key= consumer_secret= 
#   token= and token_secret=
#   eventualy content= as path
#
# This was designed to be set up as a daily cronjob

use strict;
use locale;
use File::HomeDir;
use File::Copy;
use Tumblr;
use POSIX qw(strftime);

my $debug = 1;
my $git = "/usr/bin/git";
$git = "/bin/echo" if $debug;


# First thing first, user read config
my $rc = File::HomeDir->my_home()."/.tumblrrc";
my $content = File::HomeDir->my_home()."/tmp/tumblr";
my ($tumblr_base_url, $tumblr_consumer_key, $tumblr_consumer_secret, $tumblr_token, $tumblr_token_secret);
die "Unable to read $rc, exiting" unless -r $rc;
open(RCFILE, "< $rc");
while(<RCFILE>){
    $tumblr_base_url = $1 if /^base_url\s?=\s?(\S*)\s*$/i;
    $tumblr_consumer_key = $1 if /^consumer_key\s?=\s?(\S*)\s*$/i;
    $tumblr_consumer_secret = $1 if /^consumer_secret\s?=\s?(\S*)\s*$/i;
    $tumblr_token = $1 if /^token\s?=\s?(\S*)\s*$/i;
    $tumblr_token_secret = $1 if /^token_secret\s?=\s?(\S*)\s*$/i;
    $content = $1 if /^content\s?=\s?(.*)$/i;
}
close(RCFILE);
die "Unable to determine oauth info required by Tumblr API v2 (found: base_url = $tumblr_base_url ; consumer_key = $tumblr_consumer_key ; consumer_secret = $tumblr_consumer_secret ; token = $tumblr_token ; token_secret = $tumblr_token_secret) after reading $rc, exiting" unless $tumblr_consumer_key and $tumblr_consumer_secret and $tumblr_token and $tumblr_token_secret;
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

#CURRENTLY BROKEN# Post to tumblr using https://github.com/damog/www-tumblr
##my $tumblr = WWW::Tumblr->new;
#($tumblr->write(type => 'photo', data => $image) or die $tumblr->errstr) unless $debug;
## ALTERNATIVE WORKAROUND, WAITING FOR WWW::Tumblr to get
## updated http://ryanwark.com/blog/posting-to-the-tumblr-v2-api-in-perl
## http://txlab.wordpress.com/2011/09/03/using-tumblr-api-v2-from-perl/

use utf8;
use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;
use HTTP::Request::Common;
use LWP::UserAgent;

my %oauth_api_params =
    ('consumer_key' => $tumblr_consumer_key,
     'consumer_secret' =>$tumblr_consumer_secret,
     'token' =>  $tumblr_token,
     'token_secret' => $tumblr_token_secret,
     'signature_method' =>        'HMAC-SHA1',
     request_method => 'POST',
    );


my $url = 'http://api.tumblr.com/v2/blog/'.$tumblr_base_url.'/post';
my $buffer;
my $data;
open(FILE, $image);
binmode FILE;
while (read(FILE, $buffer, 65536)) {
    $data .= $buffer;
}
close(FILE);
$data = utf8::decode("Faö");

my $request =
    Net::OAuth->request("protected resource")->new
        (request_url => $url,
         %oauth_api_params,
         timestamp => time(),
         nonce => rand(1000000),
         extra_params => {
	     'type' => 'text',
	     'body' => $data,
          #   'type' => 'photo',
         #    'data' => $data,
         });
$request->sign;
my $ua = LWP::UserAgent->new;
# this is the tricky part which is not documented where it should
my $response = $ua->request(POST $url, Content => $request->to_post_body);

if ( $response->is_success )
{
    my $r = decode_json($response->content);
    if($r->{'meta'}{'status'} == 201)
    {
        my $item_id = $r->{'response'}{'id'};
        print("Added a Tumblr entry\n");
    }
    else
    {
        printf("Cannot create Tumblr entry: %s\n",
                $r->{'meta'}{'msg'});
    }            
}
else
{
    printf("Cannot create Tumblr entry: %s\n",
            $response->as_string);
}
## ALTERNATIVE WORKAROUND END

print "$image ===> $url\n" if $debug;

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
