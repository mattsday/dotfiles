#!/bin/bash

# Only run on Debian and derivatives
if [[ ! -f "/etc/debian_version" ]]; then
	echo Not Debian, stopping
	exit
fi
# Use apt and assume somewhat recent versions
if [[ ! -x "/usr/bin/apt" ]]; then
	echo "You need apt to run this"
	exit
fi

echo Updating system
sudo apt-get -y update >/dev/null && sudo apt-get -y upgrade >/dev/null

# Get list of installed apps
installed=$(dpkg --get-selections | grep -v deinstall |awk '{print $1}' 2>/dev/null)

list="
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
xz-utils
zip
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
