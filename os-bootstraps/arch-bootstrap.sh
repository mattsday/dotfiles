#!/bin/bash

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    elif command -v dirname >/dev/null 2>&1; then
        DOTFILES_ROOT="$(cd "$(dirname "$0")" || return; pwd)"
	else
        echo >&2 '[Error] cannot determine root (try running from working directory)'
        exit 1
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

_pacman() {
	sudo pacman "$@"
}

# Only run on Arch and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
	case "${RELEASE}" in
	arch*)
		info Detected Arch Linux
		;;
	manjaro*)
		info Detected Manjaro
		;;
	*)
		error Cannot detect supported OS, stopping
		;;
	esac
else
	error Cannot detect OS, stopping
fi

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [[ "$(id -u)" = 0 ]]; then
			info Installing sudo
			pacman -Sy --noconfirm sudo >/dev/null
		else
			error "User is not root and sudo isn't installed. Install sudo first"
		fi
	fi
fi

info Updating System
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
	if ! pacman -Qs "${utility}" >/dev/null 2>&1; then
		to_install+=("${utility}")
	fi
done
if ((${#to_install[@]})); then
	info Installing "${to_install[@]}"
	_pacman -Sq --noconfirm "${to_install[@]}" >/dev/null
fi

if ! command -v yay >/dev/null 2>&1; then
	info Installing yay
	git clone https://aur.archlinux.org/yay.git /tmp/yay >/dev/null 2>&1
	pushd /tmp/yay >/dev/null 2>&1 || return
	makepkg -si --noconfirm >/dev/null 2>&1
	popd >/dev/null 2>&1 || return
	rm -fr /tmp/yay
fi

# Only run yay if not root
if [[ "$(id -u)" != 0 ]]; then
	if command -v yay >/dev/null 2>&1; then
		info Updating yay
		yay -Syuq --noconfirm >/dev/null 2>&1
	fi
fi
