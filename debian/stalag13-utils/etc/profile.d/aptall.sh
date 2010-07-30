#!/bin/sh
#
# Copyright (c) 2005 Mathieu Roy <yeupou--gnu.org>
# http://yeupou.coleumes.org
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
#
# $Id: aptall.sh,v 1.2 2005-10-03 07:41:52 moa Exp $



# Function to update every systems
function all-apt-get {
  # run on the main system
    echo "----  MAIN: `hostname` ----------------------------------------"
    apt-get $@
  # run on partitions
    for system in /chroot/*; do
        echo "---- SUBSYSTEM: $system ----------------------------------------"
        chroot $system mount proc /proc -t proc
        chroot $system apt-get $@
        # no longer adequate since sarge  chroot $system umount /proc
    done
}
