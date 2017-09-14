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
fi

# Perhaps a Red Hattish?
if [ -f "/etc/os-release" ]; then
	RELEASE=`cat /etc/os-release | grep '^ID=' | awk -F= '{print $2}' | sed 's/"//g'`
	if [ "$RELEASE" = centos ] || [ $RELEASE = rhel ] || [ $RELEASE = fedora ]; then
		if [ -f ./centos-bootstrap.sh ]; then
			./centos-bootstrap.sh
			exit
		fi
	fi
fi

