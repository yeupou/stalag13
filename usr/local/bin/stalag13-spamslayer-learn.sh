#
# FILE DISCONTINUED HERE
# UPDATED VERSION AT
#         https://gitlab.com/yeupou/stalag13/raw/master/usr/local/bin/stalag13-spamslayer-learn.sh
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
#!/bin/sh
#
# Copyright (c) 2010-2015 Mathieu Roy <yeupou--gnu.org>
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

VALID_USER="Debian-exim"
if [ `whoami` != $VALID_USER ]; then echo "Only for "$VALID_USER && exit; fi

MAILDIR="/home/klink/.Maildir/"
SPAM_DIRS="$MAILDIR/Bruit/cur/ $MAILDIR/Bruit/new/"
HAM_DIRS=`find $MAILDIR -mindepth 2 -type d | grep --invert-match Brouillons | grep --invert-match Poubelle | grep --invert-match Bruit | grep --invert-match new`

# SpamAssassin keeps tracks, so we can pass him everything as it comes
/usr/bin/sa-learn --spam $SPAM_DIRS > /dev/null
/usr/bin/sa-learn --ham $HAM_DIRS > /dev/null

# Bogofilter: not able to clean inappropriate cues from spamd, will do it       
# by removing:                                                                  
#  - informational SpamAssassin headers                                         
#  - SpamAssassin score and decision (irrelevant)
# Bogofilter: keeps no tracks of already learned spams, so we take into account
# only recent files (last time file status changed)
for file in `find $SPAM_DIRS -type f -ctime -1`; do 
    if [ -r $file ]; then
	cat $file | grep -v -E "^X-Spam-(Checker|Flag|Level|Report)" | sed s/"^X-Spam-Status.*score.*required.*tests="//g | /usr/bin/bogofilter --register-spam
    fi
done
for file in `find $HAM_DIRS -type f -ctime -1`; do 
    # ham may stay for long in the inbox, so we only take into account recent
    # files, as bogofilter keep no tracks of already learned files
    if [ -r $file ]; then
	cat $file | grep -v -E "^X-Spam-(Checker|Flag|Level|Report)" | sed s/"^X-Spam-Status.*score.*required.*tests="//g | /usr/bin/bogofilter --register-ham
    fi
done


# EOF
