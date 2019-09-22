#!/bin/bash

_pacman() {
    sudo pacman "$@"
}

# Only run on Arch and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | awk -F= '{print $2}' | sed 's/"//g')"
	case "$RELEASE" in
	arch*)
		echo Detected Arch Linux
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


# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [ "$(id -u)" = 0 ]; then
			echo Installing sudo
			pacman -Sy sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

echo Updating System
_pacman -Syuq --noconfirm >/dev/null

# Get list of installed apps
installed="$(pacman -Qe | awk '{print $1}' 2>/dev/null)"

list="
dialog
bind-tools
zsh
vim
findutils
coreutils
git
htop
tcsh
wget
jq
zip
tmux
shellcheck
"

to_install=""

for utility in $list; do
	exists="$(echo "$installed" | tr " " "\\n" | grep -wx "$utility")"
	if [[ -z "$exists" ]]; then
        to_install+="$utility "
	fi
done
if [[ ! -z "$to_install" ]]; then
    echo Installing "$to_install"
    _pacman -Sq --noconfirm $to_install >/dev/null
fi

if [[ -x "$HOME/.update_aliases" ]]; then
	"$HOME/.update_aliases" force
fi
