#!/bin/bash

DEBIAN_FRONTEND=noninteractive

# Only run on Debian and derivatives
if [[ ! -f "/etc/debian_version" ]]; then
	echo Not Debian, stopping
	exit
fi
# Use apt and assume somewhat recent versions
if [[ ! -x "/usr/bin/apt-get" ]] || [[ ! -x "/usr/bin/dpkg" ]]; then
	echo "You need apt to run this"
	exit
fi

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
	    if [ `id -u` = 0 ]; then
			echo Installing sudo
			apt-get install -y sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

# Install standard tmux
tmux=tmux

# Are we using trusty?
if [ -f "/etc/os-release" ]; then
	OS_VER=$(cat /etc/os-release | grep '^VERSION_ID' | awk -F= '{print $2}' | xargs)
	if [ ! -z "$OS_VER" ] && [ "$OS_VER" = "14.04" ]; then
		echo Adding PPA repository
		if [ ! -x "/usr/bin/apt-add-repository" ]; then
			apt-get -y install software-properties-common > /dev/null
		fi
		sudo add-apt-repository -y ppa:pi-rho/dev > /dev/null
		# Install tmux-next instead
		tmux=tmux-next
	fi
fi

echo Updating system
sudo apt-get -y update >/dev/null && sudo apt-get -y upgrade >/dev/null

# Get list of installed apps
installed=$(dpkg --get-selections | grep -v deinstall |awk '{print $1}' 2>/dev/null)

list="
dnsutils
dialog
apt-utils
zsh
vim
aptitude
findutils
coreutils
git
htop
tcsh
openssh-client
wget
jq
xz-utils
zip
$tmux
"
for utility in $list; do
	exists=$(echo $installed | tr " " "\n" | grep -wx $utility)
	if [[ -z $exists ]]; then
		echo Installing $utility
		sudo apt-get -y install $utility >/dev/null
	fi
done
if [[ -x "$HOME/.update_aliases" ]]; then
	$HOME/.update_aliases force
fi
