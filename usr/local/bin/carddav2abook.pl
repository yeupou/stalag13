#!/usr/bin/perl
#
# Copyright (c) 2015 Mathieu Roy <yeupou--gnu.org>
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

use strict;
use Fcntl qw(:flock);
use File::HomeDir;
use File::Copy;
use File::Temp qw(tempfile tempdir);
use Text::vCard::Addressbook;

## INIT
# silently forbid concurrent runs
# (http://perl.plover.com/yak/flock/samples/slide006.html)
open(LOCK, "< $0") or die "Failed to ask lock. Exit";
flock(LOCK, LOCK_EX | LOCK_NB) or exit;

# First thing first, user read config
my $rc = File::HomeDir->my_home()."/.carddav2abookrc";
my ($carddav, $abook, $user, $password, $wget_args);
open(RCFILE, "< $rc");
while(<RCFILE>){
    $carddav = $1 if /^carddav\s?=\s?(\S*)\s*$/i;
    $abook = $1 if /^abook\s?=\s?(\S*)\s*$/i;
    $user = $1 if /^user\s?=\s?(\S*)\s*$/i;
    $password = $1 if /^password\s?=\s?(\S*)\s*$/i;
    $wget_args = $1 if /^wget_args\s?=\s?(.*)\s*$/i;
}

unless ($carddav and $abook and $user and $password) {
    print "You must write an $rc with the following contents:
# url
# example for owncloud addressbook
# (ending by contacts_shared_by_USER?export instead for a shared one)
carddav = https://SERVER/remote.php/carddav/addressbooks/USER/contacts?export

# file (need write access to)
# example for squirrelmail
abook = /var/lib/squirrelmail/data/USER.abook

# auth
user = username
password = password

# optional for self-signed certificate
#wget_args = --no-check-certificate
# EOF
";
    die;
}


## RUN
# download the vcard in a tempfile
my ($tempvcard_fh, $tempvcard) = tempfile(UNLINK => 1);
`wget $wget_args --quiet --output-document="$tempvcard" --no-check-certificate --http-user="$user" --http-password="$password" "$carddav"`;

# register each vcard entry in a temp abook file
my ($tempabook_fh, $tempabook) = tempfile(UNLINK => 1);
my $book = Text::vCard::Addressbook->new({ 'source_file'  => $tempvcard });
my $count = 0;
foreach my $vcard ($book->vcards()) {
    # from Squirrelmail doc
    #      An address book file contains five fields, which are delimited by the vertical line (|): the first field stores nicknames, short names that are used to identify address book entries; the second field stores names; the third field stores surnames; the forth field stores mail addresses; and the fifth field stores additional information.
    next unless $vcard->EMAIL();
    print $tempabook_fh $vcard->fullname()."|||".$vcard->EMAIL()."||\n";
    $count++;
  }
close($tempabook_fh);

# overwrite if any results
exit unless $count;
move($tempabook, $abook);
    
# EOF 

