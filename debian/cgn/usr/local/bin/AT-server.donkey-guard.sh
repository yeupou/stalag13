#!/bin/bash

. /etc/hosts.nib.sh
if [ ! $SERVER ]; then exit ; fi
if [ `hostname` != $SERVER ]; then exit ; fi 


# Stop lamers from scanning my box or polluting my downloads

# Sloppy way of fetching paths

UNZIP=`which unzip`
NC=`which nc`
WGET=`which wget`
MLC=`which mldonkey_command`

# The file you want, before and after unzipping

FILE=guarding_full.p2p.zip
LIST=guarding_full.p2p

# Stick it in the correct location
cd ~/.mldonkey

# Fetch the file if it has changed only
$WGET -N -q http://www.openmedia.info/downloads/$FILE
if [ $? == 0 ] ; then

    $UNZIP -o $FILE >/dev/null 2>&1
    $MLC "set ip_blocking $LIST" >/dev/null 2>&1
fi


