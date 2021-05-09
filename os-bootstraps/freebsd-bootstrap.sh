#!/bin/sh

OS="$(uname)"

if [ "${OS}" != FreeBSD ]; then
	echo Not FreeBSD, stopping
	exit
fi

echo Disabling clever prompt for /bin/sh
touch "${HOME}/.simple_shell"

# Can I find pkg?
if [ ! -x "/usr/sbin/pkg" ]; then
	echo Cannot find package manager, stopping
	exit
fi

# Check if sudo is installed
if [ ! -x "/usr/bin/sudo" ] && [ ! -x "/usr/local/bin/sudo" ]; then
	if command -v id >/dev/null 2>&1; then
		if [ "$(id -u)" = 0 ]; then
			echo Installing sudo
			pkg install -q sudo
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

# Update
echo Updating system
sudo pkg update -q
sudo pkg upgrade -qy

installed="$(pkg info -a | cut -f 1 -d ' ' | cut -f 1 -d '-')"

list="
zsh
bash
vim
findutils
coreutils
git
wget
zip
gnugrep
gwhich
gtar
gsed
htop
gawk
tmux
jq
htop
"
for utility in ${list}; do
	exists="$(echo "${installed}" | tr " " "\\n" | grep -wx "${utility}")"
	if [ -z "${exists}" ]; then
		echo Installing "${utility}"
		sudo pkg install -yq "${utility}"
	fi
done
