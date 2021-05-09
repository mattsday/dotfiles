#!/bin/bash

# Only run on CentOS/RHEL and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
	case "${RELEASE}" in
	centos*)
		echo Detected CentOS
		;;
	rhel*)
		echo Detected Red Hat

		;;
	fedora*)
		echo Detected Fedora
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

package_mgr=dnf

if [[ ! -x "/usr/bin/dnf" ]]; then
	if [[ ! -x "/usr/bin/yum" ]]; then
		echo Cannot find dnf or yum, stopping
		exit
	else
		echo "Setting package manager to yum"
		package_mgr=yum
	fi
else
	echo "Setting package manager to dnf"
fi

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [ "$(id -u)" = 0 ]; then
			echo Installing sudo
			${package_mgr} install -y sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

echo Updating system
sudo "${package_mgr}" -y update >/dev/null

# Get list of installed apps
installed=$(yum list installed | cut -d ' ' -f 1 | cut -d '.' -f 1)

list="
zsh
vim-enhanced
findutils
git
tcsh
wget
xz
zip
centos
findutils
hostname
"
for utility in ${list}; do
	exists="$(echo "${installed}" | tr " " "\\n" | grep -wx "${utility}")"
	if [[ -z "${exists}" ]]; then
		echo Installing "${utility}"
		sudo "${package_mgr}" -y install "${utility}" >/dev/null
	fi
done
