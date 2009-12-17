#!/bin/bash

#Put this somewhere and source it in ~/.bashrc

#Global Variables
HOME_URL="[fqdn]"
PROXY_PORT=3128

#Java stuff for Arch Linux
#export JAVA_HOME=/opt/java/jre
#export PATH=$PATH:/opt/java/jre/bin:/opt/openoffice/program:/usr/share/eclipse
#source /etc/bash_completion

#Terminal stuff
setterm -blength 0

#Get git branch for display in PS1
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

#Colour console
if [ ${EUID} -eq 0 ]
then
        export PS1="\[\033[01;31m\]\h \[\033[01;34m\]\W\[\033[01;32m\]\$(parse_git_branch) \[\033[01;34m\]\$\[\033[00m\] "
else
        export PS1="\[\033[01;32m\]\u\[\033[01;36m\]@\[\033[01;32m\]\h\[\033[01;34m\] \W\[\033[01;32m\]\$(parse_git_branch) \[\033[01;34m\]\$\[\033[00m\] "
fi

#Handy functions
sendhome() {
    if [ -z "$2" ]
    then
        dpath=""
    else
        dpath="$2"
    fi

    if [ -z "$1" ]
    then
        echo "ERROR, You must pass a file"
    else
        src="$1"
    scp $src $HOME_URL:$dpath   
    fi
}

home() {
    ssh $HOME_URL
}

homeproxy() {
    ssh $HOME_URL -N -L $PROXY_PORT:localhost:$PROXY_PORT
}

hometunnel() {

    if [ -z "$1" ]
    then
        echo "Usage: hometunnel <localport> <home port>"
        return
    else
        local_port=$1
    fi

    if [ -z "$2" ]
    then
        home_port=$local_port
    else
        dpath="$2"
    fi

    #Open the tunnel:
    echo "Running: ssh $HOME_URL -N -L $local_port:localhost:$home_port"
    ssh $HOME_URL -N -L $local_port:localhost:$home_port
}
