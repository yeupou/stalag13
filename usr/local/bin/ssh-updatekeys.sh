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

## CHECKS AND SETUP
echo -e "${cyan}SETUP...${reset}"
   
# require to be able to enter .ssh
dir=~/.ssh
cd "$dir" || exit 1

# require write access to authorized_keys
authorized_keys="$dir/authorized_keys"
touch "$authorized_keys" || exit 1
chmod -v 600 "$authorized_keys"

# no keys subdirectory? need to set up
subdir="$dir/updatekeys"
if [ ! -d "$subdir" ]; then
    echo -e "${red}$subdir does not exists!${reset}"
    echo
    echo "If not done yet, you must create a git repository."
    echo -e "Once done, copy/paste clone address such as ${yellow}git@github.com:USER/.ssh-keys.git${reset}"
    echo 
    echo -ne "[clone]: ${yellow}"
    read clone
    echo -ne "${reset}"
    git clone "$clone" "$subdir" || exit 1
    echo
    echo "=== README ====

Any subdirectory named like setXXX or setNNN will now be treated as
a specific set of public keys.

You need at least one set, it's just up to you to create relevant 
subdirectories.

Once your first set subdirectory created, add there the relevant public keys.
" > "$subdir/README"
    cat "$subdir/README"
    if [ ! -e "$subdir/.gitignore" ]; then echo "README
*~" > "$subdir/.gitignore" ; fi
fi
cd "$subdir"

## UPDATE THE REPOSITORY
# first pull and push so we have all the relevant keys
echo -e "${cyan}REPOSITORY UPDATE...${reset}"
git pull
git add set*
git commit -a -m "Usual suspect $0 update"
git push

## LIST KEYS INCLUDE IN THE REPOSITORY
echo -e "${cyan}LIST OF AVAILABLE SETS...${reset}"
name_list=''
for set in set*/; do
    name=`echo $set | sed 's@^set\(.*\)\/$@\1@g'`
    name_list="$name_list $name"
    echo -en "Set ${yellow}$name${reset}/\n\t"
    ls "$set"
done

## UPDATE OF THE AUTHORIZED_KEYS

# ask user to select a set
# not automated on purpose, it's serious and should not be done
# lightly
echo -e "${cyan}$authorized_keys UPDATE...${reset}"
echo -e "Which set (of${yellow}$name_list${reset})"
echo -ne "[set]: ${yellow}"
read set
set=set$set
echo -ne "${reset}"
if [ ! -d "$set" ]; then
    echo "This set does not exists!"
    exit 1
fi

# go through the list and incrementaly add keys
for key in "$subdir/$set"/*.pub; do
    key_name=`cat "$key" | cut -d " " -f 3`
    didwhat="="

    # only if not yet here
    if [ `grep -F -c -f "$key" "$authorized_keys"` == 0 ]; then
	didwhat="+"
    fi

    # not if it seems to be a key of local user on this local host
    if [ "$key_name" == "`whoami`@`hostname`" ]; then
	didwhat="@"
    fi

    # actually update the file if need be
    if [ "$didwhat" == "+" ]; then
	echo "# $0 `date --rfc-2822`" >> "$keyring"
	cat "$key" >> "$keyring"
    fi
    
    # give feedback
    echo -e "${bold}$didwhat${reset} $key_name ($key)"
done

echo -e "${cyan}OVER.${reset}"
# EOF
