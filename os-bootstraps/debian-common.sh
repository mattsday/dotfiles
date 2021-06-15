#!/bin/bash

# Set DOTFILES_COMMON so this doesn't get called too much
[ -n "${DOTFILES_DEBIAN_COMMON}" ] && return
DOTFILES_DEBIAN_COMMON=1

if [ -z "${DOTFILES_ROOT}" ]; then
	echo >&2 '[Failure]' "Cannot find dotfiles root directory"
	exit 1
fi

_apt() {
	DEBIAN_FRONTEND="noninteractive" _sudo apt-get "$@"
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
