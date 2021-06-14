#!/bin/bash

fail() {
	echo >&2 '[Failure]' "$@"
	return 1
}

warn() {
	echo >&2 '[Warning]' "$@"
}

info() {
	echo "$@"
}

_apt() {
	DEBIAN_FRONTEND="noninteractive" _sudo apt-get "$@"
}

_sudo() {
	echo _sudo
	if [[ "${NO_SUDO}" = 1 ]]; then
		return
	elif [[ "${IS_ROOT}" = 1 ]]; then
		"$@"
	else
		sudo "$@"
	fi
}

sudo_disabled() {
	if [[ "${NO_SUDO}" != 1 ]]; then
		echo Warning - sudo is either not installed or disabled - consider enabling it for all features to work
	fi
	NO_SUDO=1
}

install_apt_packages() {
	get_apt_packages
	INSTALL_PACKAGES=()
	for package in "${APT_PACKAGES[@]}"; do
		if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
			INSTALL_PACKAGES+=("${package}")
		fi
	done
	if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
		info Installing packages "${INSTALL_PACKAGES[@]}"
		_apt -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
	fi
}

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [[ "$(id -u)" = 0 ]]; then
			IS_ROOT=1
		else
			sudo_disabled
		fi
	fi
fi

if [[ -f "${HOME}/.disable_dotfiles_sudo" ]]; then
	sudo_disabled
fi
