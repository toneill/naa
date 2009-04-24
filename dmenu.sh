#!/bin/bash

#To exclude anything from the PATH (like perl modules, etc) then add another variable and then add to PATHS.
NOPERL="sed s/[a-zA-Z0-9\/]*perl[a-zA-Z0-9\/]*//g"

PATHS="`echo $PATH |sed 's/:/ /g' |$NOPERL`"

echo $PATHS
$(find $PATHS -type f -executable |dmenu -b -i)
