#!/bin/bash

# Copyright 2009-2010 "Christopher Smart" <mail@christophersmart.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the temms of the GNU General Public License as published by
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

#Variables
VERSION=0.4
COUNTDOWN_TIMEOUT=5
FEDORA_RELEASE="`cat /etc/fedora-release 2>/dev/null`"

#These variables are set later, once we know the user
CLAMD_USER=""
CLAMD_CONFIG=""
CLAMD_SYSCONFIG=""
CLAMD_INIT=""
CLAMD_LOGROTATE=""
CLAMD_PID=""
CLAMD_LOG=""
CLAMD_DATABASE=""
FRESHCLAM_LOG=""
FRESHCLAM_CONF=""
FRESHCLAM_USER_CONF=""

#These variables are set later, once we know clamav-server version
CLAMD_VERSION=""
CLAMD_CONFIG_TEMPLATE=""
CLAMD_SYSCONFIG_TEMPLATE=""
CLAMD_INIT_TEMPLATE=""
CLAMD_LOGROTATE_TEMPLATE=""

#Functions
countdown() {
	i=$1
	echo "If you do NOT want to proceed, hit CTRL+C within $i seconds..."
	while [ $i -gt 0 ]
	do
		sleep 1
		echo -ne "$i.. "
		let i=i-1
	done
}

#Make this more pretty by adding an extra blank line at the beginning
echo ""

#Print help, if requested
if [ "$1" == "help" -o "$1" == "-help" -o "$1" == "--help" -o "$1" == "-h" -o "$1" == "--h" ]
then
	echo "This script configures clamav-server (clamd) on Fedora."
	echo "Version $VERSION"
	echo ""
	echo "Usage:"
	echo " $0 [option] [username] [port]"
	echo ""
	echo "Options:"
	echo " -c creates an instance, overwriting if already exists."
	echo " -r removes an instance."
	echo ""
	echo "Parameters (optional):"
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
if [ -z "$FEDORA_RELEASE" ]
then
	echo "You don't appear to be running Fedora, sorry!"
	echo "Exiting."
	echo ""
	exit 1
fi

#We're running Fedora, so make sure we're root
if [ $EUID -ne 0 ]
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

#Variables for config files, now that we know the user
CLAMD_CONFIG="/etc/clamd.d/$CLAMD_USER.conf"
CLAMD_INIT="/etc/init.d/clamd.$CLAMD_USER"
CLAMD_LOGROTATE="/etc/logrotate.d/clamd-$CLAMD_USER"
CLAMD_PID="/var/run/clamd.$CLAMD_USER"
CLAMD_LOG="/var/log/clamd.$CLAMD_USER"
CLAMD_SYSCONFIG="/etc/sysconfig/clamd.$CLAMD_USER"
CLAMD_CHKCONFIG="/sbin/chkconfig clamd.$CLAMD_USER"
CLAMD_DATABASE="/var/lib/clamav/$CLAMD_USER"
FRESHCLAM_CONF="/etc/freshclam.conf"
FRESHCLAM_USER_CONF="/etc/freshclam-$CLAMD_USER.conf"
FRESHCLAM_LOG="/var/log/freshclam-$CLAMD_USER.log"

#Removing existing instance of clamd for specified user, if told to do so
if [ "$1" == "-r" ]
then
	echo "**WARNING** Removing clamd instance for user '$CLAMD_USER'."
	countdown $COUNTDOWN_TIMEOUT
	echo ""
	echo "OK then, proceeding.."
	echo ""

	#Check to see if there's a configuration for that user already
	if [ ! -e $CLAMD_CONFIG ]
	then
		echo "No clamd instance found for user '$CLAMD_USER'."
		echo "Exiting."
		echo ""
		exit 1
	fi	

	#Stop and disable daemon
	$CLAMD_INIT stop &>/dev/null
	if [ $? -ne 0 ]
	then
		echo "Could not stop service, sorry."
		echo ""
		echo "====================================================="
		echo "Instance of clamd for user '$CLAMD_USER' NOT removed."
		echo "====================================================="
		echo ""
		exit 1
	fi

	#Turn off daemon
	$CLAMD_CHKCONFIG off &>/dev/null
	
	#Remove configs and logs, etc
	rm -f $CLAMD_CONFIG 2>/dev/null
	rm -f $CLAMD_INIT 2>/dev/null
	rm -f $CLAMD_LOGROTATE 2>/dev/null
	rm -rf $CLAMD_PID 2>/dev/null
	rm -f $CLAMD_LOG 2>/dev/null
	rm -f $CLAMD_SYSCONFIG 2>/dev/null
	rm -f $FRESHCLAM_USER_CONF 2>/dev/null
	rm -rf $CLAMD_DATABASE 2>/dev/null
	unlink /usr/sbin/clamd.$CLAMD_USER 2>/dev/null
	#unset freshclam alias
	sed -i 's/^alias\ freshclam=.*//' `cat /etc/passwd |grep ^$CLAMD_USER: |awk -F ":" {'print $6'}`/.bashrc
	
	#Remove user?
	if [ -n "`id $CLAMD_USER 2>/dev/null`" ]
	then
		#User exists, so ask if it should be removed
		echo -e "**WARNING** Do you want to REMOVE THE USER from the system? (y/N): "
		echo -e "**NOTE** This will also delete the user's home directory. \c "
		read answer
		echo ""
		if [ "$answer" == "y" -o "$answer" == "Y" ]
		then
			#Remove user and confirm success
			echo "OK, removing user '$CLAMD_USER' from the system."
			userdel -rf $CLAMD_USER 2>/dev/null
			if [ $? -eq 0 -o $? -eq 12 ]
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

	#Remove packages?
	if [ -n "`rpm -qa |grep clamav`" -a "`rpm -qa |grep clamav-update`" -a "`rpm -qa |grep clamav-server`" ]
	then
		#Ask if we want to remove packages too.
		echo -e "Do you want to uninstall the ClamAV packages from the system? (y/N): \c "
		read answer
		echo ""
		if [ "$answer" == "y" -o "$answer" == "Y" ]
		then
			yum -y erase clamav clamav-server clamav-update
		fi
	fi

	#Exit
	echo ""
	echo "======================================================================="
	echo "Instance of clamd for user '$CLAMD_USER' has been successfully removed."
	echo "======================================================================="
	echo ""
	exit 0
fi

#Creating
echo "Configuring clamd to run as user '$CLAMD_USER' on port '$CLAMD_PORT'."
echo ""
countdown $COUNTDOWN_TIMEOUT
echo ""
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
		echo "Instance of clamd for user '$CLAMD_USER' NOT created successfully."
		echo "Exiting."
		echo ""
		exit 1
	fi
fi

#Get version of clamd, now that it's installed
CLAMD_VERSION="`rpm -qa |grep clamav-server |awk -F "-" {'print $3'} |grep -v "sysvinit" 2>/dev/null`"

#Variables for template files now that we know the version of clamav-server installed
CLAMD_CONFIG_TEMPLATE="/usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.conf"
CLAMD_SYSCONFIG_TEMPLATE="/usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.sysconfig"
CLAMD_INIT_TEMPLATE="/usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.init"
CLAMD_LOGROTATE_TEMPLATE="/usr/share/doc/clamav-server-$CLAMD_VERSION/clamd.logrotate"

#Create clamav user if doesn't exist
#This should be the user who wants to talk to clamd, else user clamav must have read (and possibly write) access on the files.
echo "Checking for clamav user, '$CLAMD_USER'.."

if [ -z "`id $CLAMD_USER 2>/dev/null`" ]
then
	#original - we didn't create home dirs, but this is needed if we're checking for and setting up a proxy (and executing freshclam)
	#useradd $CLAMD_USER -r -c "User for clamd" -d /dev/null -M -s /sbin/nologin 2>/dev/null
	useradd $CLAMD_USER -c "User for clamd" 2>/dev/null
	if [ $? -ne 0 ]
	then
		echo "Unable to create new clamd user, '$CLAMD_USER', sorry."
		echo ""
		echo "Instance of clamd for user '$CLAMD_USER' NOT created successfully."
		echo "Exiting."
		echo ""
		exit 1
	else
		echo "Created new user."
		echo ""
	fi
else
	echo "User already exists, not creating."
	echo ""
fi

#Set any proxy variables now that we know the user exists
PROXY_CHECK=`su - $CLAMD_USER -c 'echo $http_proxy' 2>/dev/null`

if [ -n "`echo $PROXY_CHECK |grep http://`" ]
then
	PROXY=`echo $PROXY_CHECK |awk -F "http://" {'print $2'}`
else
	PROXY=$PROXY_CHECK
fi

if [ -n "`echo $PROXY |grep @`" ]
then
	PROXY_HOST=`echo $PROXY |awk -F "@" {'print $2'} |awk -F ":" {'print $1'}`
	PROXY_PORT=`echo $PROXY |awk -F "@" {'print $2'} |awk -F ":" {'print $2'}`
	PROXY_USER=`echo $PROXY |awk -F "@" {'print $1'} |awk -F ":" {'print $1'}`
	PROXY_PASS=`echo $PROXY |awk -F "@" {'print $1'} |awk -F ":" {'print $2'}`
else
	PROXY_HOST=`echo $PROXY |awk -F ":" {'print $1'}`
	PROXY_PORT=`echo $PROXY |awk -F ":" {'print $2'}`
fi


#Copy and configure clamd configuration file
echo "Configuring clamd to do all the right things.."

#Check that ALL required template files exist before continuing
if [ ! -e "$CLAMD_CONFIG_TEMPLATE" -o  ! -e "$CLAMD_SYSCONFIG_TEMPLATE" -o ! -e "$CLAMD_INIT_TEMPLATE" -o ! -e "$CLAMD_LOGROTATE_TEMPLATE" ]
then
	echo "Could not find required template files under /usr/share/doc/clamav-server-$CLAMD_VERSION/, sorry."
	echo ""
	echo "Instance of clamd for user '$CLAMD_USER' NOT created successfully."
	echo "Exiting."
	echo ""
	exit 1
fi

#Check to see if an instance of clamd for user already exists
if [ -e $CLAMD_CONFIG ]
then
	echo "Instance of clamd already exists, clobbering.."
	#Stop existing daemon to enable new one
	/etc/init.d/clamd.$CLAMD_USER stop &>/dev/null
	#Remove existing config because 'cp' is aliased with -i and we don't want a prompt
	rm -f $CLAMD_CONFIG 2>/dev/null
fi

#Check to see if the port is already in use, if so, increment by one until we find something that's free
PORT_INUSE=0
while [ -n "`netstat -ltn |grep ":$CLAMD_PORT"`" ]
do
	CLAMD_PORT=$(($CLAMD_PORT+1))

	PORT_INUSE=1
done
if [ $PORT_INUSE == 1 ]
then
	echo "Port was already in use, using '$CLAMD_PORT' instead."
fi

#Make sure directory exists, which it should if clamav-server is installed (but you never know)
mkdir -p /etc/clamd.d 2>/dev/null

#Copy over the template file
cp -f $CLAMD_CONFIG_TEMPLATE $CLAMD_CONFIG 2>/dev/null
sed -i 's/clamd.<SERVICE>/clamd.'$CLAMD_USER'/' $CLAMD_CONFIG
sed -i 's/^Example/#Example/' $CLAMD_CONFIG
sed -i 's/^#LogFile/LogFile/' $CLAMD_CONFIG
sed -i 's/^#PidFile/PidFile/' $CLAMD_CONFIG
sed -i 's/^LocalSocket/#LocalSocket/' $CLAMD_CONFIG
sed -i 's/^#TCPSocket\ 3310/TCPSocket\ '$CLAMD_PORT'/' $CLAMD_CONFIG
sed -i 's/^#TCPAddr/TCPAddr/' $CLAMD_CONFIG
sed -i 's/<USER>/'$CLAMD_USER'/' $CLAMD_CONFIG
sed -i 's/^#DatabaseDirectory.*/DatabaseDirectory\ \/var\/lib\/clamav\/'$CLAMD_USER'/' $CLAMD_CONFIG
chown $CLAMD_USER:$CLAMD_USER $CLAMD_CONFIG

#Copy and configure clamd for log rotation
if [ -d /etc/logrotate.d ]
then
	echo "Configuring log rotation for clamd.."

	#Try to remove existing log rotate config, whether it exists or not because 'cp' is aliased with -i
	rm -f $CLAMD_LOGROTATE 2>/dev/null
	cp -f $CLAMD_LOGROTATE_TEMPLATE $CLAMD_LOGROTATE
	sed -i 's/clamd.<SERVICE>/clamd.'$CLAMD_USER'/' $CLAMD_LOGROTATE
fi

#Configuring clamd under sysconfig
echo "Configuring clamd under syconfig.."

#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
rm -f $CLAMD_SYSCONFIG 2>/dev/null

#Copy over the template file
cp -f $CLAMD_SYSCONFIG_TEMPLATE $CLAMD_SYSCONFIG 2>/dev/null
sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_SYSCONFIG
sed -i 's/^#CLAMD/CLAMD/' $CLAMD_SYSCONFIG

#Configuring clamd init script
echo "Configuring clamd init script.."

#Try to remove existing config, whether it exists or not because 'cp' is aliased with -i
rm -f $CLAMD_INIT 2>/dev/null

#Copy over the init script
cp -f $CLAMD_INIT_TEMPLATE $CLAMD_INIT 2>/dev/null
sed -i 's/<SERVICE>/'$CLAMD_USER'/' $CLAMD_INIT
ln -s /usr/sbin/clamd /usr/sbin/clamd.$CLAMD_USER 2>/dev/null
$CLAMD_CHKCONFIG on
#Check that was successful
if [ $? -ne 0 ]
then
	echo "Could not turn service on, sorry."
	echo "Exiting."
	echo ""
	exit 1
fi

sed -i 's/^#CLAMD/'CLAMD'/' $CLAMD_SYSCONFIG

#Configure freshclam
echo "Configuring freshclam, the clamav updater.."
cp -a $FRESHCLAM_CONF $FRESHCLAM_USER_CONF
chown $CLAMD_USER:$CLAMD_USER $FRESHCLAM_USER_CONF
sed -i 's/^Example/#Example/' $FRESHCLAM_USER_CONF
sed -i 's/^#DatabaseDirectory.*/DatabaseDirectory\ \/var\/lib\/clamav\/'$CLAMD_USER'/' $FRESHCLAM_USER_CONF
sed -i 's/^#UpdateLogFile.*/UpdateLogFile\ \/var\/log\/freshclam-'$CLAMD_USER'.log/' $FRESHCLAM_USER_CONF
#Set alias so that freshclam points to correct config file
echo "alias freshclam='freshclam --config-file=$FRESHCLAM_USER_CONF'" >> `cat /etc/passwd |grep ^$CLAMD_USER: |awk -F ":" {'print $6'}`/.bashrc

#Set proxy for updating clamav, if set in env?
if [ -n "$PROXY_HOST" ]
then
	sed -i 's/^#HTTPProxyServer.*/HTTPProxyServer\ '$PROXY_HOST'/' $FRESHCLAM_USER_CONF
fi

if [ -n "$PROXY_PORT" ]
then
	sed -i 's/^#HTTPProxyPort.*/HTTPProxyPort\ '$PROXY_PORT'/' $FRESHCLAM_USER_CONF
fi

if [ -n "$PROXY_USER" ]
then
	sed -i 's/^#HTTPProxyUsername.*/HTTPProxyUsername\ '$PROXY_USER'/' $FRESHCLAM_USER_CONF
fi

if [ -n "$PROXY_PASS" ]
then
	sed -i 's/^#HTTPProxyPassword.*/HTTPProxyPassword\ '$PROXY_PASS'/' $FRESHCLAM_USER_CONF
fi


echo "Configuring required directories.."
#Set up clamav database directory
mkdir -p $CLAMD_DATABASE 2>/dev/null
chown $CLAMD_USER:$CLAMD_USER $CLAMD_DATABASE

#Setup logs
touch $CLAMD_LOG
chown $CLAMD_USER:$CLAMD_USER $CLAMD_LOG
chmod 0620 $CLAMD_LOG

touch $FRESHCLAM_LOG
chown $CLAMD_USER:$CLAMD_USER $FRESHCLAM_LOG
chmod 0620 $FRESHCLAM_LOG

#Setup run socket
mkdir $CLAMD_PID 2>/dev/null
chown $CLAMD_USER:$CLAMD_USER $CLAMD_PID/


#Configure freshclam
echo "Downloading virus definitions.."
echo ""
su $CLAMD_USER -c "freshclam --config-file=$FRESHCLAM_USER_CONF"
if [ $? -ne 0 ]
then
	echo ""
	echo "WARNING: Could not download definitions, service will fail to start. Continuing."
	echo ""
fi

echo ""
echo "Creating required directories and starting service.."
#Start services
/etc/init.d/clamd.$CLAMD_USER start &>/dev/null
if [ $? -ne 0 ]
then
	echo "Could not start service, sorry. Continuing."
	echo ""
fi

#Print summary
echo ""
echo "======================================================================="
echo "The clamd service has been successfully installed and configured with:"
echo "User '$CLAMD_USER' on port '$CLAMD_PORT'."
echo ""
echo "To update ClamAV definitions, run the 'freshclam' command as user $CLAMD_USER."
echo "======================================================================="
echo ""
echo 'Have fun!'
echo ""
