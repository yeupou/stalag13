#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/post-image-to-tumblr.pl
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
# Copyright (c) 2012-2015 Mathieu Roy <yeupou--gnu.org>
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
# Will go into $content (default: ~/tmp/tumblr) where two subdirs exists: 
#    queue/ and over/
# It will take the first file in queue/ (pulled with git) and post it to
# tumblr using WWW::Tumblr from https://github.com/damog/www-tumblr
# 
# If the image metadata contains a legend field (Description, Comment, etc)
# with strings beginning with # then it will assume these are tags for tumblr.
# The image metadata will be rewritten and only this specific field kept.
# If tagrequired is included in your .tumblrrc, images without proper tag
# wont be posted.
#   (run with --check-images argument just to check whether all images
#   about to be posted contains a proper tag)
#
# It will always keep a pool of 5 files in queue/, so if you had several
# files from one same source at once, you'll still have enough files to
# randomize it.
#
# If there are only few messages in the queue, it will slow down post unless
# --always-post option is set.
#
# It requires your tumblr OAuth to be setup, for instance as described
# in http://ryanwark.com/blog/posting-to-the-tumblr-v2-api-in-perl using
# the counterpart script post-image-to-tumblr-init-auth.pl
#
# ~/.tumblrrc MUST be created containing at least:
#     base_url = BLOGNAME.tumblr.com
#     consumer_key=
#     consumer_secret= 
#     token=
#     token_secret=
# It could also take the following options:
#     content= (default being ~/tmp/tumblr)
#     debug
#     always_post
#     tags_required
#
# This script was designed to run as a daily cronjob.
#
# FACULTATIVE:
# 
# To randomize feed, you may just run, in queue/ the following:
#   for i in *; do mv "$i" `mktemp --dry-run --tmpdir=. -t XXXXXXX$i`; done
#
# To clean up alphabetically order stuff, you may also run the following: 
#   count=0 && for i in *; do count=`expr $count + 1` && case $count in [0-5]) prefix=A;; [6-9]) prefix=C;; 1[0-5]) prefix=E;; 1[5-9]) prefix=G;; 2[0-9]) prefix=I;; 3[0-9]) prefix=K;; 4[0-9]) prefix=M;; 5[0-9]) prefix=O;; *) prefix=Q;; esac && mv $i $prefix`echo $i | tr A-Z a-z`; done 
#   or, better, use qrename.pl provided also on the same git repository
#   as this.

use strict;
use locale;
use Getopt::Long;
use File::HomeDir;
use File::Copy;
use POSIX qw(strftime);
use URI::Encode qw(uri_encode);
use Image::ExifTool;
use WWW::Tumblr;
use Encode qw(encode decode);
use Encode::Detect::Detector;
use HTML::Entities;

### INIT
my $git = "/usr/bin/git";
my @metadata_fields = ("Description", "Comment", "ImageDescription", "UserComment");
my $images_types = "png|gif|jpg|jpeg";
my %images_max_size = ("gif" => "1048576");
my $debug = 0;
my $always_post = 0;
my $tags_required = 0;

# First thing first, user read config
my $rc = File::HomeDir->my_home()."/.tumblrrc";
my $content = File::HomeDir->my_home()."/tmp/tumblr";
my ($tumblr_base_url, $tumblr_consumer_key, $tumblr_consumer_secret, $tumblr_token, $tumblr_token_secret);
my ($workaround_login, $workaround_dir, $workaround_url);
die "Unable to read $rc, exiting" unless -r $rc;
open(RCFILE, "< $rc");
while(<RCFILE>){
    # required oauth
    $tumblr_base_url = $1 if /^base_url\s?=\s?(\S*)\s*$/i;
    $tumblr_consumer_key = $1 if /^consumer_key\s?=\s?(\S*)\s*$/i;
    $tumblr_consumer_secret = $1 if /^consumer_secret\s?=\s?(\S*)\s*$/i;
    $tumblr_token = $1 if /^token\s?=\s?(\S*)\s*$/i;
    $tumblr_token_secret = $1 if /^token_secret\s?=\s?(\S*)\s*$/i;

    # handle options
    $content = $1 if /^content\s?=\s?(.*)$/i;
    $debug = 1 if /^debug$/i;
    $always_post = 1 if /^always_post$/i;
    $always_post = 1 if /^alwayspost$/i;
    $tags_required = 1 if /^tags?_required$/i;

    # workaround, see below
    $workaround_login = $1 if /^workaround_login\s?=\s?(.*)$/i;
    $workaround_dir = $1 if /^workaround_dir\s?=\s?(.*)$/i;
    $workaround_url = $1 if /^workaround_url\s?=\s?(.*)$/i;
}
close(RCFILE);
die "Unable to determine oauth info required by Tumblr API v2 (found: base_url = $tumblr_base_url ; consumer_key = $tumblr_consumer_key ; consumer_secret = $tumblr_consumer_secret ; token = $tumblr_token ; token_secret = $tumblr_token_secret) after reading $rc, exiting" unless $tumblr_consumer_key and $tumblr_consumer_secret and $tumblr_token and $tumblr_token_secret;
my $queue = $content."/queue";
my $over = $content."/over";

# command line args
my ($getopt,$help,$check);
eval {
    $getopt = GetOptions("debug" => \$debug,
			 "help" => \$help,
			 "check-images" => \$check,
	                 "always-post" => \$always_post);
};
$git = "/bin/echo" if $debug;

# help if asked
if ($help) {
    print STDERR <<EOF;
Usage: $0 [OPTIONS]

      --check-images   Go through the queue and check whether images
                       are ready to be posted (with proper #Tag and
		       not exceding certain size depending on the
		       file type).
      --always-post    Not skipping post if the number of images in the
                       queue is low.
      --debug          Not doing any git commit or moving files.

This script will go through $images_types files found 
in $content 
and post to Tumblr the first one found, using auth info 
from $rc.

It is designed to run as a cronjob. You could also use qrename.pl
to keep a big queue clean.
     
Author: yeupou\@gnu.org
       http://yeupou.wordpress.com/

EOF
exit(1);
    
}

### RUN
# Enter working directory
chdir($content) or die "Unable to enter $content, exiting";

# Update content with git
system($git, "pull", "--quiet");

# Enter the queue
chdir($queue) or die "Unable to enter $queue, exiting";

# List images
# If none found, silently exit, as an empty queue/ is not an issue.
opendir(IMAGES, $queue);
my (@images, $image);
while (defined(my $image = readdir(IMAGES))) {
    next if -d $image;
    next unless -r $image;
    next unless lc($image) =~ /\.($images_types)$/i;
    push(@images, $image);
}
closedir(IMAGES);
# end here if no image found at all
exit if scalar(@images) < 1;
# end here if we only have the pool we want to keep, unless we're just 
# checking files
exit if scalar(@images) < 6 and ! $check and ! $always_post;
# if we are low on images, slow down posting
if (scalar(@images) < 63 and ! $check and ! $always_post) {
    if (scalar(@images) < 32) {
	# only for one month, post only twice per week (monday and thursday)
	exit unless (localtime(time))[6] eq 1 or (localtime(time))[6] eq 4;
    } else {
	# otherwise, post every two days (even days)
	exit unless ((localtime(time))[3] % 2) == 0;
    }   
}

# Now go through the list of images in sorted order.
# (vars set in this loop are necessary below, so init them outside the 
# loop)
my ($image_info, $image_info_kept, @image_tags, $exifTool);
for (sort(@images)) { 
    # This var has been init before and we'll be used until the
    # end
    $image = $_;
    # Clean vars that we need outside of this loop but should actually
    # be empty for each new image we re looking at
    $image_info = "";
    $image_info_kept = "";
    @image_tags = ();

    # Extract tumblr tag from the selected image metadata
    $exifTool = new Image::ExifTool;
    $image_info = $exifTool->ImageInfo($image);
    if ($debug) { foreach (sort keys %$image_info) { print "Found tag $_ => $$image_info{$_}\n"; }} 
    foreach my $field (@metadata_fields) {
	# Remember which metadata field was useful
	$image_info_kept = $field;

	# Ignore if missing one or more #tag
	next unless $$image_info{$field} =~ /(^|\s)#\S/;
	
	# Split it with the # sign
	foreach (split("#", $$image_info{$field})) {
	    # ignore blank before and after
	    s/^\s+//;
	    s/\s+$//;
	    # ignore full blank
	    next if /^$/;
	    # otherwise register it
	    print "Register ($field) tag: $_ (".detect($_).")\n" if $debug;
	    if (detect($_)) {
		#    with accents, we get either
		#      HTTP::Message content must be bytes at 
		#      /usr/share/perl5/HTTP/Request/Common.pm line 94.
		#    or
		#      Net::OAuth warning: your OAuth message appears to contain
		#      some multi-byte characters that need to be decoded via
		#      Encode.pm or a PerlIO layer first.  This may result in an
		#      incorrect signature. at 
		#      /usr/share/perl5/Net/OAuth/Message.pm line 106.
		#
		#    a possible workaround is be encode as HTML entities 
		#    after decoding to perl internal format (encode_entities
		#    requires encoding to be identified and defined, so 
		#    it is best to simply decode first cf.
	        #    https://bugs.debian.org/787821 )  
		#
		# save the string in perl internal format		
		push(@image_tags, decode(detect($_),$_));
	    } else {
		push(@image_tags, $_);
	    }
	}
	
	# if we found some valid #tags, dont check any other field
	last if (scalar(@image_tags) > 0);
    }

    # Check for file size, if there are limit on this type
    # (this test wont prevent the script to attempt to post the file)
    my $image_type;
    $image_type = lc($1) if $image =~ /([^\.]*)$/;
    if (exists($images_max_size{$image_type})) {
	my $image_size = -s $image;
	print "$image is bigger ($image_size) than expected for $image_type.\n"
	    if $image_size > $images_max_size{$image_type};
    }

    # Unless we are checking files, we want to deal only with the 
    # first image found
    last unless $check;

    # Otherwise, print results
    if ((scalar(@image_tags) < 1 and $tags_required)) { print "$image has no valid tag.\n"; } 
    elsif ($debug) { print "$image '$image_info_kept' field is ".$$image_info{$image_info_kept}."\n"; }
}

# Exit here if we are just checking files, everything beyond has to do
# with actual posting
exit(0) if $check;

# Exit if no tag found and nonetheless required
die "No tag found for $image, exiting" if (scalar(@image_tags) < 1) and $tags_required;

# Reset image tags: tumblr gives out meaningless error 400 for some image
# depending on it's meta data. So we're forced to remove metadata
print "Reset $image metada except field $image_info_kept set to ".$$image_info{$image_info_kept}."\n" if $debug;
$exifTool->SetNewValue('*');
$exifTool->SetNewValue($image_info_kept, $$image_info{$image_info_kept});
$exifTool->WriteInfo($image);
if ($debug) {
    $image_info = $exifTool->ImageInfo($image);
    foreach (sort keys %$image_info) { print "Final tag $_ => $$image_info{$_}\n"; }
} 

# Now set up API contact
my $tumblr = WWW::Tumblr->new(
    consumer_key => $tumblr_consumer_key,
    secret_key =>$tumblr_consumer_secret,
    token =>  $tumblr_token,
    token_secret => $tumblr_token_secret,
    );
my $blog = $tumblr->blog($tumblr_base_url);

# And post the image
#
# BASIC POST TEST
#($blog->post(type => 'text', body => 'Delete me, I am a damned test with '.join(',', @image_tags), title => 'test') or die $blog->error->code);

# Direct post (see history of this file for a version that post with url)

# temporary workaround with accentued characters: post with caption
# encoded to HTML entities
my $description = join(',', @image_tags);
my $description_field = 'tags';
$description_field = 'caption' if encode_entities($description) ne $description;

($blog->post(type => 'photo',
	     $description_field => encode_entities($description),
	     data => ["$image"]) 
 or die $blog->error->code." while posting $image with tags ".join(',', @image_tags));

print "It was not possible to set $description as tag, it has been set as caption.\n" if $description_field eq 'caption'; 

# If we get here, we can assume everything went well. 
# Move the file in over/ and commit to git
chdir($content);
my $today = strftime("%Y%m%d", localtime);
move("$queue/$image", "$over/$today-$image") unless $debug;
print "mv $queue/$image $over/$today-$image\n" if $debug;
system($git, "add", $over);
system($git, "commit", "--quiet", "-am", "Posted by post-image-to-tumblr.pl");
system($git, "push", "--quiet");

# EOF
