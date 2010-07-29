#!/bin/bash

STATUS_OPTION="status"
REVISION_OPTION="revision"

OPTION="$1"

CVS_DIR="$2"

if [ -n "$3" ] 
then
	FILENAME="$3"
else
	FILENAME="None"
fi

if [ -n "$4" ] 
then
	REV="$4"
else
	REV="None"
fi

function get_status() {
	if [ -e $CVS_DIR ]
	then
		cd $CVS_DIR
		cvs status 
	fi
}

function get_latest_revision_info() {
	if [ $FILENAME == "None" -o $REV == "None" ]
	then
		exit 1
	fi

	if [ -e $CVS_DIR ]
	then
		cd $CVS_DIR
		cvs log -r$REV $FILENAME
	fi
}

function error() {
	echo "$1"
	exit -1
}

if [ $OPTION == $STATUS_OPTION ]
then
	if [ -z $CVS_DIR ]
	then
		error "NEED TO PASS A DIRECTORY"
	fi

	get_status

elif [ $OPTION == $REVISION_OPTION ]
then
	if [ -z $CVS_DIR -o $FILENAME == "None" -o $REV == "None" ]
	then
		error "ERROR 2"
	fi
	
	get_latest_revision_info

else 
	error "ERROR"
fi

