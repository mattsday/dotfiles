#!/bin/bash
#shellcheck disable=SC1091

if [[ -z "${DOTFILES_ROOT}" ]]; then
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

# Load Debian common functions (from common.sh)
load_debian_common

APT_PACKAGES=()
SNAP_PACKAGES=()
NO_SUDO_CONFIG=0
# Check for mixins
export _debian_bootstrap_mattsday=1
RELEASE="$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
if [[ "${RELEASE}" = rodete ]] ; then
    NO_ENV_PRESERVE=true
    if [[ -f /etc/glinux/bruschetta/uuid ]]; then
        NO_SUDO_CONFIG=1
        info Detected Bruschetta
        . "${OS_BOOTSTRAP_ROOT}/bruschetta-bootstrap.sh"
    elif [[ -f "${OS_BOOTSTRAP_ROOT}"/rodete-bootstrap.sh ]]; then
		NO_SUDO_CONFIG=1
		info Detected Rodete
		. "${OS_BOOTSTRAP_ROOT}"/rodete-bootstrap.sh
	fi
fi
RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
if [[ "${RELEASE}" = neon ]]; then
	if [[ -f "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh ]]; then
		info Detected KDE Neon Desktop
		. "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh
	fi
elif [[ "${RELEASE}" = ubuntu ]]; then
	if dpkg-query -W -f='${Status}' kwin-common 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
		info Detected Kubuntu
		. "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh
	fi
fi

if [[ -f /dev/.cros_milestone ]] && [[ "${RELEASE}" != rodete ]]; then
    info Detected Chromebook
    . "${OS_BOOTSTRAP_ROOT}"/chromebook.sh
fi

# Only run on Debian and derivatives
if [[ ! -f "/etc/debian_version" ]]; then
	error Not Debian, stopping
	exit
fi

# Use apt and assume somewhat recent versions
if [[ ! -x "/usr/bin/apt-get" ]] || [[ ! -x "/usr/bin/dpkg" ]]; then
	warn "Cannot find apt"
	NO_SUDO=1
	exit
fi

if [[ "${NO_SUDO}" != 1 ]] && [[ "${IS_ROOT}" != 1 ]]; then
	. "${OS_BOOTSTRAP_ROOT}"/passwordless-sudo.sh
fi

# Install standard tmux
tmux="tmux"

# Are we using trusty? It's > 2020 so I hope not!
if [[ "${RELEASE}" = ubuntu ]] && [[ -f "/etc/os-release" ]]; then
	OS_VER=$(grep '^VERSION_ID' /etc/os-release | cut -d = -f 2 | xargs)
	if [[ -n "${OS_VER}" ]] && [[ "${OS_VER}" = "14.04" ]]; then
		info Adding PPA repository
		if [[ ! -x "/usr/bin/apt-add-repository" ]]; then
			_apt -y install software-properties-common >/dev/null
		fi
		sudo add-apt-repository -y ppa:pi-rho/dev >/dev/null
		# Install tmux-next instead
		tmux="tmux-next"
	fi
fi

if [[ "${NO_SUDO}" != 1 ]]; then
	info Updating package list
	_apt update >/dev/null
fi

get_apt_packages() {
	APT_PACKAGES+=(
		apt-utils
		bash-completion
		zsh
		rsync
		curl
		vim
		findutils
		coreutils
		git
		htop
		openssh-client
		wget
		jq
		xz-utils
		zip
		unzip
		"${tmux}"
		shellcheck
		whois
	)
}

# Make Python 3 default if installed
if dpkg-query -W -f='${Status}' python3 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    if apt-cache show python-is-python3 >/dev/null 2>&1; then
        APT_PACKAGES+=(python-is-python3)
    fi
fi

install_apt_packages

if [[ -n "${CALLBACKS}" ]]; then
	info Running platform specific callbacks
	for callback in "${CALLBACKS[@]}"; do
		"${callback}"
	done
fi

# Setup the keyboard
if [[ "${NO_SUDO}" != 1 ]]; then
	if [[ -f /etc/default/keyboard ]]; then
		# Check if the layout is UK
		if ! grep XKBLAYOUT=\"gb\" /etc/default/keyboard >/dev/null; then
			info Updating keyboard layout to UK Layout
			_sudo sed -i 's/XKBLAYOUT=.*/XKBLAYOUT=\"gb\"/' /etc/default/keyboard
			_sudo service keyboard-setup restart
		fi
	fi
fi

#shellcheck disable=SC2154
if [[ -z "${_bootstrap_mattsday}" ]] && [[ -x "${HOME}/.update_aliases" ]]; then
	"${HOME}/.update_aliases" force
fi
