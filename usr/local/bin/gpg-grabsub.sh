#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/gpg-grabsub.sh
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
#!/bin/bash
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

red="\e[31m"
yellow="\e[33m"
cyan="\e[36m"
bold="\e[1m"
reset="\e[0m"

echo -e "${red}This script assumes that you already set up a primary key and sub keys"
echo -e "(one to sign, one to en/decrypt)${reset}"


# gpg dir should not already exists
dir=~/.gnupg
if [ -d "$dir" ]; then echo "$dir already exists, we wont mess with it" && exit 1; fi
   
# get hostname of the should be secured box
echo "Master key host to contact via SSH?"
read host

echo -e "${cyan}Keys:${reset}"
ssh $host 'gpg --list-key'

# set the primary key
echo -e "Primary key id? (pub    4096R/${yellow}??????????${reset})"
read primary

# local import keys 
ssh $host 'gpg  --export-secret-key --armor'  | gpg --import -


# remove the secret key of the primary
echo -e "${cyan}Removing the primary key from the set, approve please...${reset}"
temp=$(mktemp)
gpg --export-secret-subkeys $primary > $temp
gpg --delete-secret-keys $primary
gpg --import $temp
rm -f $temp
gpg --list-keys

# set a local password
echo -e "${cyan}Set a new local password that will differ from the primary and save:${reset}"
gpg --edit-key $primary passwd

# EOF
