#!/bin/bash

#Copyright 2009 Christopher Smart <mail@christophersmart.com>, under GPLv3 (a copy included in COPYING)

#This script is for installing and configuring clam-server (clamd) on Fedora

#Make this more pretty by adding an extra blank line at the beginning
clear
echo ""

#Print help, if requested
if [ "$1" == "help" -o "$1" == "-help" -o "$1" == "--help" -o "$1" == "-h" -o "$1" == "--h" ]
then
	echo "This script installs and configures clamav-server (clamvd) on Fedora to listen on a local port."
	echo "Pass in the user to run clamd as and the port to run on, else these will default to 'clamav' on port '3310'. I.e.:"
	echo "su -c ./configure-clamd.sh [username] [port]"
	echo ""
	exit 0
fi

#Check that we're running Fedora
FEDORA_RELEASE="`cat /etc/fedora-release 2>/dev/null`"
if [ -z "$FEDORA_RELEASE" ]
then
	echo "You don't appear to be running Fedora, sorry!"
        echo ""
	echo "Exiting."
	echo ""
	exit 1
else
	#We're running Fedora, so make sure we're root
	if [ $EUID != 0 ]
	then
	        echo "You must run this as root. Prepend sudo, or run:"
		echo "su -c $0 [username] [port]"
	        echo ""
	        echo "Exiting."
	        echo ""
	        exit 1
	else
		echo "You appear to be running `echo $FEDORA_RELEASE`, excellent."
		echo ""
	fi
fi

#Set clamd user and port
if [ -z "$1" ]
then
	CLAMD_USER="clamav"
	else
	CLAMD_USER="$1"
fi

if [ -z "$2" ]
then
	CLAMD_PORT="3310"
	else
	CLAMD_PORT="$2"
fi

#Check to see if the port is already in use, if so, increment by one until we find something that's free
while [ -n "`netstat -ltn |grep ":$CLAMD_PORT"`" ]
do
if [ -n "`netstat -ltn |grep ":$CLAMD_PORT"`" ]
then
	CLAMD_PORT=$(($CLAMD_PORT+1))
fi
done

#Checking to see if required packages are installed or not
echo "Checking for required packages.."
echo ""
if [ -n "`rpm -qa |grep clamav`" -a "`rpm -qa |grep clamav-update`" -a "`rpm -qa |grep clamav-server`" ]
then
	echo "Required packages already installed, continuing.."
	echo ""
else

	#Install required packages
	echo "Installing required clamav packages.."
	echo ""
	yum -y install clamav clamav-server clamav-update
	echo ""

	#Check that the install was successful (or already installed)
	if [ -n "`rpm -qa |grep clamav`" -a "`rpm -qa |grep clamav-update`" -a "`rpm -qa |grep clamav-server`" ]
	then
		echo "Packages successfully installed."
		echo ""
	else
		echo "Problem installing required packages, sorry."
		echo ""
		echo "Exiting."
		echo ""
		exit 1
	fi
fi

#Get version of clamd, now that it's installed
CLAMD_VERSION="`rpm -qa |grep clamav-server |awk -F "-" {'print $3'} 2>/dev/null`"

#Create clamav user if doesn't exist
#This should be the user who wants to talk to clamd, else user clamav must have read (and possibly write) access on the files.
echo "Checking for clamav user, $CLAMD_USER."
echo ""

if [ -z "`id $CLAMD_USER 2>/dev/null`" ]
then
	useradd $CLAMD_USER -r -c "User for clamd" -d /dev/null -M -s /sbin/nologin 2>/dev/null
	if [ $? != 0 ]
	then
		echo "Unable to create new clamd user, $CLAMD_USER, sorry."
		echo ""
		echo "Exiting."
		echo ""
		exit 1
	else
		echo "Created new user, $CLAMD_USER."
		echo ""
	fi
else
	echo "User already exists, continuing."
	echo ""
fi

#Set variable for clamd configuration location (which we know once we get the user)
CLAMD_CONFIG="/etc/clamd.d/$CLAMD_USER.conf"

#Copy and configure clamd configuration file
echo "Configuring clamd to do all the right things.."
echo ""

#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
rm -f $CLAMD_CONFIG 2>/dev/null

#Check that the template clamd.conf exists
if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.conf ]
then
	#Make sure directory exists, which it should if clamav-server is installed (but you never know)
	mkdir -p /etc/clamd.d 2>/dev/null
	#Copy over the template file
	cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.conf $CLAMD_CONFIG 2>/dev/null
	sed -i 's/clamd.<SERVICE>/clamd.'$CLAMD_USER'/' $CLAMD_CONFIG
	sed -i 's/^Example/#Example/' $CLAMD_CONFIG
	sed -i 's/^#LogFile/LogFile/' $CLAMD_CONFIG
	sed -i 's/^#PidFile/PidFile/' $CLAMD_CONFIG
	sed -i 's/^LocalSocket/#LocalSocket/' $CLAMD_CONFIG
	sed -i 's/^#TCPSocket/TCPSocket/' $CLAMD_CONFIG
	sed -i 's/^#TCPAddr/TCPAddr/' $CLAMD_CONFIG
	sed -i 's/<USER>/'$CLAMD_USER'/' $CLAMD_CONFIG
	echo "Complete."
	echo ""
else
	echo "Could not find clamd.conf template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
	echo ""
	echo "Exiting."
	echo ""
	exit 1
fi

#Copy and configure clamd for log rotation
if [ -d /etc/logrotate.d ]
then
	echo "Configuring log rotation for clamd.."
	echo ""
	CLAMD_LOGROTATE=/etc/logrotate.d/clamd-$CLAMD_USER

	if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.logrotate ]
	then
		#Try to remove existing log rotate config, whether it exists or not because 'cp' is aliased with -i
		rm -f $CLAMD_LOGROTATE 2>/dev/null
		cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.logrotate $CLAMD_LOGROTATE
		sed -i 's/clamd.<SERVICE>/clamd.'$CLAMD_USER'/' $CLAMD_LOGROTATE
		echo "Complete."
		echo ""
	else
		echo "Could not find logrotate template under /usr/share/doc/clamav-server-$CLAMAV_VERSION, sorry."
		echo ""
		echo "Skipping log rotate configuration."
		echo ""
	fi
fi

#Set variable for clamd sysconfig
CLAMD_SYSCONFIG="/etc/sysconfig/clamd.$CLAMD_USER"

#Configuring clamd under sysconfig
echo "Configuring clamd under syconfig.."
echo ""

#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
rm -f $CLAMD_SYSCONFIG 2>/dev/null

#Check that the template exists
if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.sysconfig ]
then
        #Copy over the template file
        cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.sysconfig $CLAMD_SYSCONFIG 2>/dev/null
        sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_SYSCONFIG
        sed -i 's/^#CLAMD/'CLAMD'/' $CLAMD_SYSCONFIG
        echo "Complete."
        echo ""
else
        echo "I can't find the sysconfig template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
        echo ""
        echo "Exiting."
        echo ""
        exit 1
fi

#Set variable for clamd init script
CLAMD_INIT="/etc/init.d/clamd.$CLAMD_USER"

#Configuring clamd init script
echo "Configuring clamd init script.."
echo ""

#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
rm -f $CLAMD_INIT 2>/dev/null

#Check that the template exists
if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.init ]
then
        #Copy over the init script
        cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.init $CLAMD_INIT 2>/dev/null
        sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_INIT
	ln -s /usr/sbin/clamd /usr/sbin/clamd.$CLAMD_USER
	/sbin/chkconfig clamd.$CLAMD_USER on
	#Check that was successful
	if [ $? != 0 ]
	then
		echo "Could not turn service on, sorry."
		echo ""
		echo "Exiting."
		echo ""
		exit 1
	else
	        echo "Complete."
	        echo ""
	fi
else
        echo "I can't find the sysconfig template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
        echo ""
        echo "Exiting."
        echo ""
        exit 1
fi


#Setup logs
CLAMD_LOG=/var/log/clamd.$CLAMD_USER
touch $CLAMD_LOG
chown $CLAMD_USER:$CLAMD_USER $CLAMD_LOG
chmod 0620 $CLAMD_LOG

#Setup run socket
CLAMD_PID=/var/run/clamd.$CLAMD_USER
mkdir $CLAMD_PID
chown $CLAMD_USER:$CLAMD_USER $CLAMD_PID/

#Start services
/etc/init.d/clamd.$CLAMD_USER start
if [ $? != 0 ]
then
	echo "Could not start service, sorry."
	echo ""
	echo "Continuing"
	echo ""
fi

#Print summary
echo "The clamd service has been successfully installed and configured with:"
echo "User '$CLAMD_USER' on port '$CLAMD_PORT'"
echo ""
echo 'Have fun!'
echo ""

