#!/bin/bash
#
# Copyright (c) 2012 Mathieu Roy <yeupou--gnu.org>
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

# Will go into $CONTENT where two subdirs exists: queue and over
# It will take the first file in queue, post it to $DEST (tumblr post by 
# email address), move it to over then commit the change with git
#   $CONTENT is by default ~/tumblr
#   there is no default for DEST, it must be set in ~/.tumblr-daily-postrc

WHOAMI=`whoami`
RCFILE=/home/$WHOAMI/.tumblr-daily-postrc
CONTENT=/home/$WHOAMI/tumblr
DEST=0

# Wont run as root
if [ `whoami` == "root" ]; then echo "Not supposed to run as root, die here" && exit; fi

# Must have a rcfile to get DEST (could redefine CONTENT)
if [ ! -r $RCFILE ]; then exit; fi
source $RCFILE
if [[ $DEST -eq 0 ]]; then echo "DEST unset after reading $RCFILE, die here" && exit; fi

# Go inside content
if [ ! -d $DEST ]; then echo "$DEST not found/not a directory, die here" && exit; fi
cd $DEST

# Mutt need some empty file to succesfully send a mail without content
FAKECONTENT=`mktemp`

# Select the first file
FILE=`ls -1 --color=no queue/* | head -1`

# Stop silently if the queue is empty
if [ ! -e "$FILE" ]; then exit; fi

# Otherwise, mail it
mutt $DEST -a $FILE < $FAKECONTENT

# Commit the change
mv $FILE over/
git add over/*
git commit -am 'Daily post' >/dev/null
git push  >/dev/null 2>/dev/null

# Cleanup
rm -f $FAKECONTENT


# EOF