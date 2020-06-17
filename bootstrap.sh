#!/bin/sh

echo Running init
if [ -f ./init.sh ]; then
	./init.sh
fi

# Check if we're running OS X
SYSTEM="$(uname)"
if [ "$SYSTEM" = Darwin ]; then
	if [ -f ./os-bootstraps/mac-bootstrap.sh ]; then
		echo Detected Mac OS X
		./os-bootstraps/mac-bootstrap.sh
	fi
elif [ "$SYSTEM" = FreeBSD ]; then
	if [ -f ./os-bootstraps/freebsd-bootstrap.sh ]; then
		echo Detected FreeBSD
		./os-bootstraps/freebsd-bootstrap.sh
	fi
fi

# Maybe Debian?
if [ -f "/etc/debian_version" ] && [ -x "/usr/bin/apt-get" ]; then
	if [ -f ./os-bootstraps/debian-bootstrap.sh ]; then
		echo Detected Debian flavoured
		./os-bootstraps/debian-bootstrap.sh
	fi
fi

if [ -f "/etc/os-release" ]; then
	RELEASE="$(grep '^ID=' /etc/os-release | awk -F= '{print $2}' | sed 's/"//g')"
	# Perhaps a Red Hattish?
	if [ "$RELEASE" = centos ] || [ "$RELEASE" = rhel ] || [ "$RELEASE" = fedora ]; then
		if [ -f ./os-bootstraps/centos-bootstrap.sh ]; then
			echo Detected Red Hat flavoured
			./bootstraps./centos-bootstrap.sh
		fi
	elif [ "$RELEASE" = suse ] || [ "$RELEASE" = opensuse ]; then
		if [ -f ./os-bootstraps/suse-bootstrap.sh ]; then
			echo Detected SuSE flavoured
			./os-bootstraps/suse-bootstrap.sh
		fi
	elif [ "$RELEASE" = arch ] || [ "$RELEASE" = manjaro ]; then
		if [ -f ./os-bootstraps/arch-bootstrap.sh ]; then
			echo Detected Arch flavoured
			./os-bootstraps/arch-bootstrap.sh
		fi
	fi
fi
