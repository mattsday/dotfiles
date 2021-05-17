#!/bin/bash
#shellcheck disable=SC1091

if [ -z "${DOTFILES_ROOT}" ]; then
	if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
		DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
	else
		DOTFILES_ROOT="${PWD}"
	fi
fi

if [ -z "${OS_BOOTSTRAP_ROOT}" ]; then
	if [ -f "${DOTFILES_ROOT}"/debian-bootstrap.sh ]; then
		OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"
	else
		OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"/os-bootstraps
		if [ -f "${DOTFILES_ROOT}"/debian-bootstrap.sh ]; then
			echo Cannot find OS bootstraps
			exit 1
		fi
	fi
fi

_apt() {
	DEBIAN_FRONTEND="noninteractive" sudo apt-get "$@"
}

APT_PACKAGES=()
SNAP_PACKAGES=()

# Check for mixins
export _debian_bootstrap_mattsday=1
RELEASE="$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
if [[ "${RELEASE}" = rodete ]]; then
	if [[ -f "${OS_BOOTSTRAP_ROOT}"/rodete-bootstrap.sh ]]; then
		echo Detected Rodete
		. "${OS_BOOTSTRAP_ROOT}"/rodete-bootstrap.sh
	fi
fi
RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
if [[ "${RELEASE}" = neon ]]; then
	if [[ -f "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh ]]; then
		echo Detected KDE Neon Desktop
		. "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh
	fi
elif [[ "${RELEASE}" = ubuntu ]]; then
	if dpkg-query -W -f='${Status}' kwin-common 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
		echo Detected Kubuntu
		. "${OS_BOOTSTRAP_ROOT}"/ubuntu-desktop-bootstrap.sh
	fi
fi

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
		if [[ "$(id -u)" = 0 ]]; then
			echo Installing sudo
			DEBIAN_FRONTEND="noninteractive" apt-get update >/dev/null
			DEBIAN_FRONTEND="noninteractive" apt-get install -y sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
fi

# Install standard tmux
tmux="tmux"

# Are we using trusty? It's > 2020 so I hope not!
if [[ "${RELEASE}" = ubuntu ]] && [[ -f "/etc/os-release" ]]; then
	OS_VER=$(grep '^VERSION_ID' /etc/os-release | cut -d = -f 2 | xargs)
	if [[ -n "${OS_VER}" ]] && [[ "${OS_VER}" = "14.04" ]]; then
		echo Adding PPA repository
		if [[ ! -x "/usr/bin/apt-add-repository" ]]; then
			_apt -y install software-properties-common >/dev/null
		fi
		sudo add-apt-repository -y ppa:pi-rho/dev >/dev/null
		# Install tmux-next instead
		tmux="tmux-next"
	fi
fi

echo Updating package list
_apt update >/dev/null

APT_PACKAGES+=(
	apt-utils
	bash-completion
	dnsutils
	zsh
	rsync
	curl
	vim
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
	unzip
	"${tmux}"
	shellcheck
	whois
)

INSTALL_PACKAGES=()
for package in "${APT_PACKAGES[@]}"; do
	if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
		INSTALL_PACKAGES+=("${package}")
	fi
done
if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
	echo Installing packages "${INSTALL_PACKAGES[@]}"
	_apt -y install "${INSTALL_PACKAGES[@]}" >/dev/null
fi

if command -v snap >/dev/null 2>&1; then
	for snap in "${SNAP_PACKAGES[@]}"; do
		pkg_name="$(echo "${snap}" | cut -d ' ' -f 1)"
		if ! snap info "${pkg_name}" | grep installed: >/dev/null 2>&1; then
			echo Installing snap package "${snap}"
			# shellcheck disable=SC2086
			sudo snap install ${snap} >/dev/null || warn "Failed to install ${snap}"
		fi
	done
fi

if [[ -n "${CALLBACKS}" ]]; then
	echo Running platform specific callbacks
	for callback in "${CALLBACKS[@]}"; do
		"${callback}"
	done
fi

#shellcheck disable=SC2154
if [[ -z "${_bootstrap_mattsday}" ]] && [[ -x "${HOME}/.update_aliases" ]]; then
	"${HOME}/.update_aliases" force
fi
