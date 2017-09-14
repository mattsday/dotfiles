#!/bin/sh

echo Running init
if [ -f ./init.sh ]; then
	./init.sh
fi

# Check if we're running OS X
SYSTEM=`uname`
if [ "$SYSTEM" = Darwin ]; then
	if [ -f ./mac-bootstrap.sh ]; then
		./mac-bootstrap.sh
		exit
	fi
fi

# Maybe Debian?
if [ -f "/etc/debian_version" ] && [ -x "/usr/bin/apt-get" ]; then
	if [ -f ./debian-bootstrap.sh ]; then
		./debian-bootstrap.sh
		exit
	fi
	exit
fi

