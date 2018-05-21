#!/bin/sh

echo Running init
if [ -f ./init.sh ]; then
	./init.sh
fi

# Check if we're running OS X
SYSTEM=`uname`
if [ "$SYSTEM" = Darwin ]; then
	if [ -f ./mac-bootstrap.sh ]; then
		echo Detected Mac OS X
		./mac-bootstrap.sh
	fi
elif [ "$SYSTEM" = FreeBSD ]; then
	if [ -f ./freebsd-bootstrap.sh ]; then
		echo Detected FreeBSD
		./freebsd-bootstrap.sh
	fi
fi

# Maybe Debian?
if [ -f "/etc/debian_version" ] && [ -x "/usr/bin/apt-get" ]; then
	if [ -f ./debian-bootstrap.sh ]; then
		echo Detected Debian flavoured
		./debian-bootstrap.sh
	fi
fi

if [ -f "/etc/os-release" ]; then
	RELEASE=`cat /etc/os-release | grep '^ID=' | awk -F= '{print $2}' | sed 's/"//g'`
	# Perhaps a Red Hattish?
	if [ "$RELEASE" = centos ] || [ $RELEASE = rhel ] || [ $RELEASE = fedora ]; then
		if [ -f ./centos-bootstrap.sh ]; then
			echo Detected Red Hat flavoured
			./centos-bootstrap.sh
		fi
	elif [ "$RELEASE" = suse ] || [ $RELEASE = opensuse ]; then
	        if [ -f ./suse-bootstrap.sh ]; then
	            echo Detected SuSE flavoured
	            ./suse-bootstrap.sh
	        fi
	fi
fi
