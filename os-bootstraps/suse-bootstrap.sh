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

# Only run on SuSE and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -d '=' -f 2 | sed 's/"//g')"
	case "${RELEASE}" in
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

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [[ "$(id -u)" = 0 ]]; then
			echo Installing sudo
			zypper --non-interactive install sudo >/dev/null
		else
			echo "User is not root and sudo isn't installed. Install sudo first"
			exit
		fi
	fi
elif sudo [[ ! -f /etc/sudoers.d/nopasswd-"${USER}" ]]; then
	echo "${USER}"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd-"${USER}" >/dev/null
fi

# Check for mixins
export _suse_bootstrap_mattsday=1
# Are we running a desktop?
if rpm -q plasma5-desktop >/dev/null 2>&1 || rpm -q plasma6-desktop >/dev/null 2>&1; then
	if [[ -f ./os-bootstraps/suse-desktop-bootstrap.sh ]]; then
		echo Detected Desktop
		. ./os-bootstraps/suse-desktop-bootstrap.sh
	fi
fi

echo Refreshing package list
sudo zypper -n refresh >/dev/null

RPM_PACKAGES+=(
	zsh
	rsync
	curl
	htop
	jq
	vim-data
	vim
	findutils
	coreutils
	git
	wget
	xz
	zip
	tmux
	hostname
	ShellCheck
)

INSTALL_PACKAGES=()
for package in "${RPM_PACKAGES[@]}"; do
	if ! rpm -q "${package}" >/dev/null 2>&1; then
		INSTALL_PACKAGES+=("${package}")
	fi
done
if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
	info Installing packages "${INSTALL_PACKAGES[@]}"
	sudo zypper -n install "${INSTALL_PACKAGES[@]}" >/dev/null || error "Failed installing packages"
fi

if command -v flatpak >/dev/null 2>&1; then
	# Add Flatpak repo
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
	INSTALL_PACKAGES=()
	for package in "${FLATPAK_PACKAGES[@]}"; do
		if ! flatpak info "${package}" >/dev/null 2>&1; then
			INSTALL_PACKAGES+=("${package}")
		fi
	done
	if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
		info Installing packages "${INSTALL_PACKAGES[@]}"
		sudo flatpak -y install "${INSTALL_PACKAGES[@]}" >/dev/null || error "Failed installing packages"
	fi
fi

if [[ -x "${HOME}/.update_aliases" ]]; then
	"${HOME}/.update_aliases" force
fi

if [[ -n "${CALLBACKS}" ]]; then
	echo Running platform specific callbacks
	for callback in "${CALLBACKS[@]}"; do
		"${callback}"
	done
fi
