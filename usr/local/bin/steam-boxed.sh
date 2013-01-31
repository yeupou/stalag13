#!/bin/bash
#
# Copyright (c) 2013 Mathieu Roy <yeupou--gnu.org>
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


# 1. proprietary
# 2. wtf wrapping stuff already supposed to work?

# CONFIG
STEAM_USER="pllx"
STEAM_ROOT="/mnt/steam"
BINDS="/proc /dev /sys /var/lib/dbus /run"
FILES="/etc/resolv.conf /etc/hosts"

# VARS
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# CHECKS
if [ "`id -u`" != 0 ]; then 
    echo -e $RED "Only root can mount and chroot" $NC
    echo "You should run the command with sudo by editing /etc/sudoers:"
    echo `whoami` "ALL=(ALL) NOPASSWD: ${0}"
    echo -e $RED "Exit" $NC
    exit
fi
SESSIONS_DIR=/tmp/steam-boxed-sessions
if [ ! -d $SESSIONS_DIR ]; then
    mkdir -v $SESSIONS_DIR
done

# SET UP SESSION
if [ `ls -1 $SESSIONS_DIR/ | wc -l` -lt 1 ]; then
    echo -e $GREEN ==== SETTING UP SESSION ==== $NC
    mount -v $STEAM_ROOT
    for bind in $BINDS; do
	if [ ! -d $STEAM_ROOT$bind ]; then mkdir -v $STEAM_ROOT$bind; fi
	mount -v --bind $bind $STEAM_ROOT$bind;
    done
    for file in $FILES; do
	rm -f $STEAM_ROOT$file
	cp -v $file $STEAM_ROOT$file
    done
    # dirty hack specific to flash
    if [ -e $STEAM_ROOT/home/$STEAM_USER/.local/share/Steam/ubuntu12_32 ]; then cp -fv /usr/lib/flashplugin-nonfree/libflashplayer.so $STEAM_ROOT/home/$STEAM_USER/.local/share/Steam/ubuntu12_32; fi
    # another dirty hack required by steam
    chmod 1777 $STEAM_ROOT/dev/shm
    # mark that we have an active session already
    touch $SESSIONS_DIR/$BASHPID
else 
    echo -e $YELLOW ==== SKIP SETTING UP SESSION, AT LEAST ONE ALREADY EXISTS ==== $NC    
fi


# GET IN AND START STEAM/SHELL
case $1 in
    root)
	echo -e $RED ==== OPENING UP A ROOT SHELL ==== $NC
	chroot $STEAM_ROOT
	;;
    shell)
	echo -e $YELLOW ==== OPENING UP A SHELL ==== $NC
	chroot $STEAM_ROOT su $STEAM_USER
	;;
    *) echo -e $GREEN ==== STEAMING ==== $NC
	chroot $STEAM_ROOT su $STEAM_USER -c "steam"
	;;
esac



# CLEAN UP SESSION
rm -fv $SESSIONS_DIR/$BASHPID
case $1 in
    nocleanup) 
	echo -e $RED ==== SKIP CLEANING UP SESSION AS ASKED TO ==== $NC
	;;
    *) 
	if [ `ls -1 $SESSIONS_DIR/ | wc -l` -lt 1 ]; then
	    echo -e $GREEN ==== CLEANING UP SESSION ==== $NC
            # run twice umount in case of race conditions
	    for bind in $BINDS $BINDS; do
		umount -v $STEAM_ROOT$bind;
	    done
	    rm -fv $STEAM_ROOT/is-session-up
	    umount -v $STEAM_ROOT
	else 
	    echo -e $YELLOW ==== SKIP CLEANING UP SESSION, AT LEAST ONE STILL EXISTS ==== $NC
	fi
	;;
esac


echo -e $YELLOW ==== OVER/EOF ==== $NC
echo "For the record, valids args are: nocleanup root shell"
# EOF




