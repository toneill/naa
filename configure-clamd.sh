#!/bin/bash

# Copyright 2009 Christopher Smart <mail@christophersmart.com>
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


#This script is for installing and configuring clam-server (clamd) on Fedora

#Make this more pretty by adding an extra blank line at the beginning
echo ""

#Print help, if requested
if [ "$1" == "help" -o "$1" == "-help" -o "$1" == "--help" -o "$1" == "-h" -o "$1" == "--h" ]
then
	echo "This script configures clamav-server (clamd) on Fedora."
	echo ""
	echo "Usage:"
	echo " $0 [option] [username] [port]"
	echo ""
	echo "Options:"
	echo " -c creates an instance, overwriting if already exists."
	echo " -r removes an instance."
	echo ""
	echo "Variables (optional):"
	echo " [username] pass in the username you want clamd to run as, defaults to 'clamav'."
	echo " [port] pass in the port you want clamd to run on, defaults to '3310'."
	echo ""
	echo "Create example:"
	echo " $0 -c me 3311"
	echo ""
	echo "Remove example:"
	echo " $0 -r me 3311"
	echo ""
	echo "Report bugs to mail@christophersmart.com"
	echo ""
	exit 0
fi

#Check that we're running Fedora
FEDORA_RELEASE="`cat /etc/fedora-release 2>/dev/null`"
if [ -z "$FEDORA_RELEASE" ]
then
	echo "You don't appear to be running Fedora, sorry!"
	echo "Exiting."
	echo ""
	exit 1
else
	#We're running Fedora, so make sure we're root
	if [ $EUID != 0 ]
	then
	        echo "You must run this as root. Prepend sudo, or run:"
		echo "su -c '$0 [option] [username] [port]'"
	        echo ""
	        echo "Exiting."
	        echo ""
	        exit 1
	else
		echo "You appear to be running `echo $FEDORA_RELEASE`, excellent."
		echo ""
	fi
fi

#Are we removing or creating?
if [ "$1" == "-r" ]
then
	STATUS=remove
else
	STATUS=create
fi

#Set clamd user and port
if [ "$1" != "-c" -a "$1" != "-r" ]
then
	CLAMD_USER="clamav"
	CLAMD_PORT="3310"
else
	if [ -z "$2" ]
	then
		CLAMD_USER="clamav"
		else
		CLAMD_USER="$2"
	fi
	
	if [ -z "$3" ]
	then
		CLAMD_PORT="3310"
		else
		CLAMD_PORT="$3"
	fi
fi

#Removing
if [ $STATUS == "remove" ]
then
	echo "**WARNING** Removing clamd instance for user '$CLAMD_USER'."
	echo "If you do NOT want to proceed, hit CTRL+C within 5 seconds..."
	echo ""
	sleep 5
	echo "OK then, proceeding.."
	echo ""
	
	#Check to see if there's a configuration for that user already
	if [ ! -e /etc/clamd.d/$CLAMD_USER.conf ]
	then
		echo "No clamd instance found for user '$CLAMD_USER'."
		echo "Exiting."
		echo ""
		exit 1
	else
		#Stop and disable daemon
		/etc/init.d/clamd.$CLAMD_USER stop 2>/dev/null
		if [ $? != 0 ]
		then
			echo "Could not stop service, sorry."
			echo ""
			echo "Instance of clamd for user '$CLAMD_USER' NOT removed."
			echo "Exiting."
			echo ""
			exit 1
		fi
		/sbin/chkconfig clamd.$CLAMD_USER off 2>/dev/null
		#Remove configs and logs, etc
		rm -f /etc/clamd.d/$CLAMD_USER.conf 2>/dev/null
		rm -f /etc/logrotate.d/clamd-$CLAMD_USER 2>/dev/null
		rm -rf /var/run/clamd.$CLAMD_USER 2>/dev/null
		rm -f /var/log/clamd.$CLAMD_USER 2>/dev/null
		unlink /usr/sbin/clamd.$CLAMD_USER 2>/dev/null
		rm -f /etc/init.d/clamd.$CLAMD_USER 2>/dev/null
		#Remove user?
		if [ -n "`cat /etc/passwd |grep ^$CLAMD_USER`" ]
		then
			#User exists, so ask if it should be removed
			echo -e "**WARNING** DO YOU WANT TO REMOVE THE USER FROM THE SYSTEM? (y/N): \c "
			read answer
			echo ""
			if [ "$answer" == "y" -o "$answer" == "Y" ]
			then
				#Remove user and confirm success
				echo "OK, removing user '$CLAMD_USER' from the system."
				userdel -r $CLAMD_USER 2>/dev/null
				if [ "$?" == "0" ]
				then
					echo "User removed successfully."
					echo ""
				else
					echo "**WARNING** Could not remove clamd user from the system. Perform manually."
					echo ""
				fi
			else
				echo "OK, user will NOT be removed."
				echo ""
			fi
		else
			echo "User does not exist in the system, not removing."
			echo ""
		fi
	echo "Instance of clamd for user $CLAMD_USER has been successfully removed."
	echo ""
	fi
else
	#Creating
	echo "Configuring clamd to run as user '$CLAMD_USER' on port '$CLAMD_PORT'."
	echo "If you do NOT want to proceed, hit CTRL+C within 5 seconds..."
	echo ""
	sleep 5
	echo "OK then, proceeding.."
	echo ""

	#Checking to see if required packages are installed or not
	echo "Checking for required packages.."
	if [ -n "`rpm -qa |grep clamav`" -a "`rpm -qa |grep clamav-update`" -a "`rpm -qa |grep clamav-server`" ]
	then
		echo "Required packages already installed."
		echo ""
	else

		#Install required packages
		echo "Installing required clamav packages.."
		echo ""
		yum -yq install clamav clamav-server clamav-update
		echo ""

		#Check that the install was successful (or already installed)
		if [ -n "`rpm -qa |grep clamav`" -a "`rpm -qa |grep clamav-update`" -a "`rpm -qa |grep clamav-server`" ]
		then
			echo "Packages successfully installed."
			echo ""
		else
			echo "Problem installing required packages, sorry."
			echo "Exiting."
			echo ""
			exit 1
		fi
	fi

	#Get version of clamd, now that it's installed
	CLAMD_VERSION="`rpm -qa |grep clamav-server |awk -F "-" {'print $3'} 2>/dev/null`"

	#Create clamav user if doesn't exist
	#This should be the user who wants to talk to clamd, else user clamav must have read (and possibly write) access on the files.
	echo "Checking for clamav user, $CLAMD_USER.."

	if [ -z "`id $CLAMD_USER 2>/dev/null`" ]
	then
		useradd $CLAMD_USER -r -c "User for clamd" -d /dev/null -M -s /sbin/nologin 2>/dev/null
		if [ $? != 0 ]
		then
			echo "Unable to create new clamd user, $CLAMD_USER, sorry."
			echo "Exiting."
			echo ""
			exit 1
		else
			echo "Created new user."
			echo ""
		fi
	else
		echo "User already exists."
		echo ""
	fi

	#Set variable for clamd configuration location (which we know once we get the user)
	CLAMD_CONFIG="/etc/clamd.d/$CLAMD_USER.conf"

	#Copy and configure clamd configuration file
	echo "Configuring clamd to do all the right things.."

	if [ -e $CLAMD_CONFIG ]
	then
		echo "Instance of clamd already exists, clobbering.."
		#Stop existing daemon to enable new one
		/etc/init.d/clamd.$CLAMD_USER stop &>/dev/null
		#Remove existing config because 'cp' is aliased with -i and we don't want a prompt
		rm -f $CLAMD_CONFIG 2>/dev/null
	fi

	#Check to see if the port is already in use, if so, increment by one until we find something that's free
	while [ -n "`netstat -ltn |grep ":$CLAMD_PORT"`" ]
	do
	if [ -n "`netstat -ltn |grep ":$CLAMD_PORT"`" ]
	then
		CLAMD_PORT=$(($CLAMD_PORT+1))
	fi
	echo "Port was already in use, using '$CLAMD_PORT' instead."
	done

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
		sed -i 's/^#TCPSocket\ 3310/TCPSocket\ '$CLAMD_PORT'/' $CLAMD_CONFIG
		sed -i 's/^#TCPAddr/TCPAddr/' $CLAMD_CONFIG
		sed -i 's/<USER>/'$CLAMD_USER'/' $CLAMD_CONFIG
	else
		echo "Could not find clamd.conf template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
		echo "Exiting."
		echo ""
		exit 1
	fi
	echo "Done."
	echo ""

	#Copy and configure clamd for log rotation
	if [ -d /etc/logrotate.d ]
	then
		echo "Configuring log rotation for clamd.."
		CLAMD_LOGROTATE=/etc/logrotate.d/clamd-$CLAMD_USER

		if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.logrotate ]
		then
			#Try to remove existing log rotate config, whether it exists or not because 'cp' is aliased with -i
			rm -f $CLAMD_LOGROTATE 2>/dev/null
			cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.logrotate $CLAMD_LOGROTATE
			sed -i 's/clamd.<SERVICE>/clamd.'$CLAMD_USER'/' $CLAMD_LOGROTATE
		else
			echo "Could not find logrotate template under /usr/share/doc/clamav-server-$CLAMAV_VERSION, sorry."
			echo ""
			echo "Skipping log rotate configuration."
			echo ""
		fi
	fi
	echo "Done."
	echo ""

	#Set variable for clamd sysconfig
	CLAMD_SYSCONFIG="/etc/sysconfig/clamd.$CLAMD_USER"

	#Configuring clamd under sysconfig
	echo "Configuring clamd under syconfig.."

	#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
	rm -f $CLAMD_SYSCONFIG 2>/dev/null

	#Check that the template exists
	if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.sysconfig ]
	then
		#Copy over the template file
		cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.sysconfig $CLAMD_SYSCONFIG 2>/dev/null
		sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_SYSCONFIG
		sed -i 's/^#CLAMD/'CLAMD'/' $CLAMD_SYSCONFIG
	else
		echo "I can't find the sysconfig template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
		echo "Exiting."
		echo ""
		exit 1
	fi
	echo "Done."
	echo ""

	#Set variable for clamd init script
	CLAMD_INIT="/etc/init.d/clamd.$CLAMD_USER"

	#Configuring clamd init script
	echo "Configuring clamd init script.."

	#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
	rm -f $CLAMD_INIT 2>/dev/null

	#Check that the template exists
	if [ -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.init ]
	then
		#Copy over the init script
		cp -f /usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.init $CLAMD_INIT 2>/dev/null
		sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_INIT
		ln -s /usr/sbin/clamd /usr/sbin/clamd.$CLAMD_USER 2>/dev/null
		/sbin/chkconfig clamd.$CLAMD_USER on
		#Check that was successful
		if [ $? != 0 ]
		then
			echo "Could not turn service on, sorry."
			echo "Exiting."
			echo ""
			exit 1
		fi
	else
		echo "I can't find the sysconfig template under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
		echo "Exiting."
		echo ""
		exit 1
	fi
	echo "Done."
	echo ""

	#Configure freshclam
	FRESHCLAM_CONF=/etc/freshclam.conf
	echo "Enabling freshclam, the clamav updater.."
	sed -i 's/^Example/#Example/' $FRESHCLAM_CONF
	#Should we set the proxy too, if in env?
	echo "Done."
	echo ""

	echo "Creating required directories and starting service.."
	#Setup logs
	CLAMD_LOG=/var/log/clamd.$CLAMD_USER
	touch $CLAMD_LOG
	chown $CLAMD_USER:$CLAMD_USER $CLAMD_LOG
	chmod 0620 $CLAMD_LOG

	#Setup run socket
	CLAMD_PID=/var/run/clamd.$CLAMD_USER
	mkdir $CLAMD_PID 2>/dev/null
	chown $CLAMD_USER:$CLAMD_USER $CLAMD_PID/

	#Start services
	echo ""
	/etc/init.d/clamd.$CLAMD_USER start
	if [ $? != 0 ]
	then
		echo "Could not start service, sorry."
		echo "Continuing."
		echo ""
	fi
	echo "Done."
	echo ""

	#Print summary
	echo "The clamd service has been successfully installed and configured with:"
	echo "User '$CLAMD_USER' on port '$CLAMD_PORT'"
	echo ""
	echo 'Have fun!'
	echo ""
fi
