#!/bin/bash

# Copyright 2010 Commonwealth of Australia
# "Allan Cunliffe" <allan.cunliffe@naa.gov.au>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
# the following are arguments that can be passed to the script when you are running it.

# This script can be used to create a specified number of text files or to copy a specified input file a specified number of times. 

range=$1
file=$2

# Check for range argument. If there is none given, end the script give usage and tell the user to enter a number next time they run it.
if [ -z "$range" ]
then
    echo "Usage: $0 <number of files> [<file to copy>]"
    echo -e 'You need to specify the number of text files you want to create.\nYou can optionally specify an input file which will be copied to create the specified number of files.'
    exit 1
else
    if [ -n "$file" ] # Check if a file is specified. If it is, find the basename.
    then
        outfilename=`basename $file`
    fi
    for (( i=0; i<$range; i++ )) # Set the range of the for loop - based on the range argument entered by the user.
    do
        if [ -z "$file" ] # If file is not specified, generate text files. If a file is specified, copy the input file.
        then    
            echo "this is text file ${i}" > file${i}.txt
        else
            cat $file > ${i}$outfilename
        fi
    done
fi
