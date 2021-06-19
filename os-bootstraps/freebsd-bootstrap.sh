#!/bin/sh

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    else
        DOTFILES_ROOT="${PWD}"
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

OS="$(uname)"

if [ "${OS}" != FreeBSD ]; then
	error Not FreeBSD, stopping
fi

info Disabling clever prompt for /bin/sh
touch "${HOME}/.simple_shell"

# Can I find pkg?
if [ ! -x "/usr/sbin/pkg" ]; then
	error Cannot find package manager, stopping
fi

# Check if sudo is installed
if [ ! -x "/usr/bin/sudo" ] && [ ! -x "/usr/local/bin/sudo" ]; then
	if command -v id >/dev/null 2>&1; then
		if [ "$(id -u)" = 0 ]; then
			info Installing sudo
			pkg install -q sudo
		else
			error "User is not root and sudo isn't installed. Install sudo first"
		fi
	fi
fi

# Update
info Updating system
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
		info Installing "${utility}"
		sudo pkg install -yq "${utility}"
	fi
done
