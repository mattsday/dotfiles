#!/bin/bash

# Only run on SuSE and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE=$(cat /etc/os-release | grep '^ID=' | awk -F= '{print $2}' | sed 's/"//g')
	case "$RELEASE" in
		suse*)
			echo Detected SuSE
			;;
		opensuse*)
			echo Detected OpenSuSE
			;;
		*)
			echo Cannot detect supported OS, stopping
			exit
			;;
	esac
else
	echo Cannot detect OS, stopping
	exit
fi

package_mgr=zypper

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
	    if [ `id -u` = 0 ]; then
			echo Installing sudo
			$package_mgr --non-interactive install sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

echo Updating system
sudo $package_mgr update -y >/dev/null

# Get list of installed apps
installed=$(zypper packages -i | tail -n +5 | awk -F\| '{print $3}'|xargs)

list="
zsh
vim-data
vim
findutils
coreutils
git
tcsh
wget
xz
zip
tmux
hostname
"
for utility in $list; do
	exists=$(echo $installed | tr " " "\n" | grep -wx $utility)
	if [[ -z $exists ]]; then
		echo Installing $utility
		sudo $package_mgr --non-interactive install $utility >/dev/null
	fi
done
if [[ -x "$HOME/.update_aliases" ]]; then
	$HOME/.update_aliases force
fi
