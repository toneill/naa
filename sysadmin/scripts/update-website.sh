#!/bin/bash

if [ -n "$1" ]
then
	rsync -PrltgoD --exclude=.hg /var/www/$1/ acunliffe,$1@web.sourceforge.net:htdocs/
else
	echo 'Tell me which website to sync!'
fi
