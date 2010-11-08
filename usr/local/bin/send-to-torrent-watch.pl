#!/bin/sh                                                                       
cd /stockage/torrent/watch
newname=`echo "$*" | sed "s/[^a-z|A-Z|0-9]//g;"`
wget -O $newname.torrent "$*"
