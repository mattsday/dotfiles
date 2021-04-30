#!/bin/bash

_pacman() {
	sudo pacman "$@"
}

# Only run on Arch and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
	case "$RELEASE" in
	arch*)
		echo Detected Arch Linux
		;;
	manjaro*)
		echo Detected Manjaro
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
			pacman -Sy --noconfirm sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

echo Updating System
_pacman -Syuq --noconfirm >/dev/null

# Get list of installed apps
installed="$(pacman -Qe | cut -d ' ' -f 1 2>/dev/null) "
installed+="$(pacman -Qg | cut -d ' ' -f 1 2>/dev/null) "

list=(
	base-devel
	openssh
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
	unrar
	tmux
	shellcheck
	base-devel
)

to_install=()

for utility in "${list[@]}"; do
	if ! pacman -Qs "$utility" >/dev/null 2>&1; then
		to_install+=("$utility")
	fi
done
if ((${#to_install[@]})); then
	echo Installing "${to_install[@]}"
	_pacman -Sq --noconfirm "${to_install[@]}" >/dev/null
fi

if ! command -v yay >/dev/null 2>&1; then
	echo Installing yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay >/dev/null 2>&1
	pushd /tmp/yay >/dev/null 2>&1 || return
	makepkg -si --noconfirm >/dev/null 2>&1
	popd >/dev/null 2>&1 || return
	rm -fr /tmp/yay
fi

# Only run yay if not root
if [ "$(id -u)" != 0 ]; then
	if command -v yay >/dev/null 2>&1; then
		echo Updating yay
		yay -Syuq --noconfirm >/dev/null 2>&1
	fi
fi
