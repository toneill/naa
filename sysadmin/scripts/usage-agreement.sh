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


## This script creates a dialog to prompt the user to agree to terms of usage when loggin in.
## It will use either kdialog, Xdialog or GNOME's zenity.
## The desktop itself doesn't matter, this works with KDE, GNOME, Xfce, etc.

## Put this file in /usr/local/bin/ and call it from the Xsession file.
## Under Fedora, this at /etc/X11/xinit/Xsession - simply add it as the first thing to call in the file.
## Now when users log in, they need to agree, or get kicked out!

## This might extend to SSH and terminal logins, hence the checking for DISPLAY, etc, but it's not done yet.

TITLE="Usage Agreement"
MESSAGE="Do you declare that; DigiPres is awesome?"

if [ -n "`env |grep DISPLAY`" ]
then
	if [ -f "`which kdialog 2>/dev/null`" ]
	then
		kdialog --title "$TITLE" --yesno "$MESSAGE"
	elif [ -f "`which zenity 2>/dev/null`" ]
	then
		zenity --title "$TITLE" --question --text "$MESSAGE"
	elif [ -f "`which Xdialog 2>/dev/null`" ]
	then
		Xdialog --title "$TITLE" --yesno "$MESSAGE" 10 60
	else
		echo "`date`" >> ~/LOGIN-ERROR.txt
		echo "Could not log in becasue no suitable dialog program found." >> LOGIN-ERROR.txt
		echo "" >> ~/LOGIN-ERROR.txt
		kill -HUP $PPID
	fi

	if [ $? -ne 0 ]
	then
		kill -HUP $PPID
	fi
else
	echo "$MESSAGE (y/N): "
	read answer
	if [ "$answer" != "y" -a "$answer" != "Y" ]
	then
		kill -HUP $PPID
	fi
fi
