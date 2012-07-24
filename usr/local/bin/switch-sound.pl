#!/usr/bin/perl
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
#         http://yeupou.wordpress.com/
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

# set up
use strict;
use Getopt::Long;

my $active_profile = "output:analog-stereo";
my $suspend_profile = "off";
my $pactl = "/usr/bin/pactl";
die "Unable to run $pactl" unless -x $pactl;
my $debug;
eval { $getopt = GetOptions("debug" => \$debug); };

# list of souncards always off (product name)
my %cards_to_ignore;
$cards_to_ignore{"Barts HDMI Audio [Radeon HD 6800 Series]"} = 1;

# get list of active cards (should be only two, put the rest in 
# ignore list)
open(LIST_CARDS, "export LC_ALL=C && $pactl list cards |");
my $current_card;
my %cards;
my $already_found_one_active;
while(<LIST_CARDS>) {
    # which one we work on
    $current_card = $1 if /^Card \#(\d)$/i;

    # take into account ignore list
    if (/device.product.name = \"([^\"]*)\"$/i) {
	$cards{$current_card} = $1;
	delete($cards{$current_card}) if $cards_to_ignore{$1};
    }
    next unless $cards{$current_card};

    # record the first card we find active
    $already_found_one_active = $current_card if /Active Profile: $active_profile$/i;
}
close(LIST_CARDS);
print "Is active: $already_found_one_active\n" if $debug;

# now proceed to the changes
my $already_set_one_active = 0;
while (my ($card, $name) = each(%cards)){
    print "$card, $name " if $debug;
    my $profile;

    # if it's the one card flagged as already active, set if off
    if ($already_found_one_active eq $card or $already_set_one_active) {
	$profile =  $suspend_profile;
    } else {
	$profile = $active_profile;
	# we wont activate more than one
	$already_set_one_active = 1;
    }
    
    # ask pactl to change the profile
    system($pactl, "set-card-profile", $card, $profile);
    print "=> $profile\n" if $debug;
}

# EOF 
