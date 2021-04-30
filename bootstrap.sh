#!/bin/sh

echo Running init
if [ -f ./init.sh ]; then
	./init.sh
fi

_bootstrap_mattsday=1
export _bootstrap_mattsday

if [ -f "/etc/os-release" ]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -f 2 -d = | sed 's/"//g')"
	RELEASE_LIKE="$(grep '^ID_LIKE=' /etc/os-release | cut -f 2 -d = | sed 's/"//g')"

	if [ "$RELEASE" = debian ] || [ "$RELEASE_LIKE" = debian ]; then
		if [ -f ./os-bootstraps/debian-bootstrap.sh ]; then
			echo Detected Debian flavoured
			./os-bootstraps/debian-bootstrap.sh
		fi
	elif [ "$RELEASE" = centos ] || [ "$RELEASE" = rhel ] || [ "$RELEASE" = fedora ]; then
		if [ -f ./os-bootstraps/centos-bootstrap.sh ]; then
			echo Detected Red Hat flavoured
			./bootstraps./centos-bootstrap.sh
		fi
	elif [ "$RELEASE" = suse ] || [ "$RELEASE" = opensuse ] || [ "$RELEASE" = "opensuse-tumbleweed" ] || [ "$RELEASE" = "opensuse-leap" ]; then
		if [ -f ./os-bootstraps/suse-bootstrap.sh ]; then
			echo Detected SuSE flavoured
			./os-bootstraps/suse-bootstrap.sh
		fi
	elif [ "$RELEASE" = arch ] || [ "$RELEASE" = manjaro ]; then
		if [ -f ./os-bootstraps/arch-bootstrap.sh ]; then
			echo Detected Arch flavoured
			./os-bootstraps/arch-bootstrap.sh
		fi
	elif [ "$RELEASE" = freebsd ]; then
		if [ -f ./os-bootstraps/arch-bootstrap.sh ]; then
			echo Detected FreeBSD
			./os-bootstraps/freebsd-bootstrap.sh
		fi
	fi
else
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
fi

if command -v git >/dev/null 2>&1; then
	if [ "$(git config --global --get 'pull.rebase')" != true ]; then
		echo Setting git config to merge
		git config --global 'pull.rebase' true
	fi
fi

if [ -x "$HOME/.update_aliases" ]; then
	"$HOME/.update_aliases" force
fi
