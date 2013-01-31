#!/bin/bash

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

# SET UP SESSION
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
case $1 in
    nocleanup) 
	echo -e $RED ==== SKIP CLEANING UP SESSION ==== $NC
	;;
    *) echo -e $GREEN ==== CLEANING UP SESSION ==== $NC
	# run twice umount in case of race conditions
	for bind in $BINDS $BINDS; do
	    umount -v $STEAM_ROOT$bind;
	done
	umount -v $STEAM_ROOT
	;;
esac


echo -e $YELLOW ==== OVER/EOF ==== $NC
echo "For the record, valids args are: nocleanup root shell"
# EOF




