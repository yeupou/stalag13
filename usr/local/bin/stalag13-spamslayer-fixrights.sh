#!/bin/sh
#
# Copyright (c) 2010 Mathieu Roy <yeupou--gnu.org>
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

if [ "`id -u`" != 0 ]; then echo "Only for root" && exit; fi

MAILDIR="/home/klink/.Maildir/"
AFFECTED_DIRS="$MAILDIR/.Poubelle.Spam/cur/ $MAILDIR/.Poubelle.Spam/new/ $MAILDIR/cur/ $MAILDIR/new/"

for file in `find $AFFECTED_DIRS -type f`; do 
    chmod 640 $file; 
done

# EOF