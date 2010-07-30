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
# $Id: chroot_apache.sh,v 1.2 2005-10-11 10:47:27 moa Exp $

chroot /chroot/apache mount proc /proc -t proc
chroot /chroot/apache /etc/init.d/syslog-ng $1
chroot /chroot/apache /etc/init.d/apache $1
chroot /chroot/apache /etc/init.d/cron $1
chroot /chroot/apache /etc/init.d/exim4 $1

