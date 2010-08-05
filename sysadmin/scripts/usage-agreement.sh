#!/bin/bash

# Copyright 2009 "Christopher Smart" <mail@christophersmart.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


## This script uses kdialog to prompt the user to agree to terms of usage when loggin in.
## Naturally, you need to install kdialog and use KDM, not GDM as the login manager.
## The desktop itself doesn't matter, this works with KDE, GNOME, Xfce, etc.

## Put this file in /usr/local/bin/ and call it from the KDM Xsession file.
## Under Fedora, this at /etc/kde/kdm/Xsession - simply add it as the first thing to call in the file.
## Now when users log in, they need to agree, or get kicked out!

if [ -n "`env |grep DISPLAY`" ]
then
	kdialog --yesno "Do you declare that; DigiPres is awesome?"
	if [ $? -ne 0 ]
	then
		kill -HUP $PPID
	fi
else
	echo "Do you declare that; DigiPres is awesome? (y/N): "
	read answer
	if [ "$answer" != "y" -a "$answer" != "Y" ]
	then
		kill -HUP $PPID
	fi
fi
