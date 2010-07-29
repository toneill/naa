#!/bin/bash

#This script requires the dmenu package from the wmii window manager. Install it with your distro's package management tool.
#You can then put this script somewhere and add a shortcut key in your desktop environment to call it.

#dsTo exclude anything from the PATH (like perl modules, etc) then add another variable and then add to PATHS.

ERL="sed s/[a-zA-Z0-9\/]*perl[a-zA-Z0-9\/]*//g"

PATHS="`echo $PATH |sed 's/:/ /g' |$NOPERL`"

$(find $PATHS -type f -executable |dmenu -b -i)
