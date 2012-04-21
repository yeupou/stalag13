#!/bin/sh
# (hum, not .pl!)

cd /mnt/lan/gate.stalag13.ici/watch
newname=`echo "$*" | sed "s/[^a-z|A-Z|0-9]//g;"`
wget -O $newname.torrent "$*"
