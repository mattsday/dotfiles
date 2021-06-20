#!/bin/bash

if [ -z "${DOTFILES_ROOT}" ]; then
	if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
		DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
	else
		DOTFILES_ROOT="${PWD}"
	fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

configure_ports() {
	xcode-select --install 2>/dev/null
	if [ ! -x /opt/local/bin/port ]; then
		fail "Install MacPorts - https://www.macports.org/install.php"
		return 1
	fi
	PORTS=(gawk grep shellcheck coreutils bash htop gsed gnutar multimarkdown jq findutils tmux wget ffmpeg youtube-dl watch)
	for port in "${PORTS[@]}"; do
		if [ ! "$(/opt/local/bin/port -q installed "${port}" | wc -l)" -gt 0 ]; then
			PORTS_INSTALL+=("${port}")
		fi
	done
	if [[ -n "${PORTS_INSTALL[*]}" ]]; then
		info Installing ports "${PORTS_INSTALL[@]}"
		sudo /opt/local/bin/port -q install "${PORTS_INSTALL[@]}"
	fi
}

configure_git() {
	# Store git passwords in keychain
	if command -v git >/dev/null 2>&1 && [ "$(git config --global --get credential.helper)" != osxkeychain ]; then
		info Configuring git to use keychain
		git config --global credential.helper osxkeychain
	fi
}

configure_fonts() {
	# install jetbrains mono
	if [ -f jetbrains-mono-font.sh ]; then
		./jetbrains-mono-font.sh
	elif [ -f ./os-bootstraps/jetbrains-mono-font.sh ]; then
		./os-bootstraps/jetbrains-mono-font.sh
	fi
}

configure_sudo() {
	# passwordless sudo
	if [ ! -f /etc/sudoers.d/nopasswd-"${USER}" ]; then
		info Configuring passwordless sudo
		echo "${USER}"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd-"${USER}"
	fi
}

main() {
	# Only run on a mac
	OS="$(uname)"
	if [[ "${OS}" != "Darwin" ]]; then
		error Not OS X, stopping
	fi

	#configure_homebrew
	#configure_ferdi
	configure_ports
	configure_git
	configure_fonts
	configure_sudo
}

main
