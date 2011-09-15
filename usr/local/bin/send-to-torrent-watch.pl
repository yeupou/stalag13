#!/bin/sh
# (hum, not .pl!)

# handles heterogenous pathes
if [ -d /stockage/torrent/watch ]; then
    cd /stockage/torrent/watch
fi
if [ -d /lan/stalag13.ici/torrent-watch ]; then
    cd /lan/stalag13.ici/torrent-watch
fi

newname=`echo "$*" | sed "s/[^a-z|A-Z|0-9]//g;"`
wget -O $newname.torrent "$*"
