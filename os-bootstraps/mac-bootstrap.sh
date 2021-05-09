#!/bin/bash

fail_exit() {
	echo >&2 '[Failure]' "$@"
	exit 1
}

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

configure_homebrew() {
	# Is homebrew installed?
	if [[ ! -x /usr/local/bin/brew ]]; then
		# Install homebrew
		info Installing homebrew
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	fi

	# NOW is homebrew installed?
	if [[ ! -x /usr/local/bin/brew ]]; then
		fail Homebrew installation failed. Aborting
	fi

	# Update homebrew
	info Updating homebrew
	brew update >/dev/null
	info Updating system
	brew upgrade >/dev/null
	brew cleanup >/dev/null

	installed="$(brew list --formula)"
	features="
	gawk
	grep
	shellcheck
	coreutils
	bash
	htop
	gnu-sed
	gnu-tar
	gnu-which
	multimarkdown
	jq
	findutils
	tmux
	wget
	ffmpeg
	youtube-dl
	watch
"
	for feature in ${features}; do
		exists="$(echo "${installed}" | grep -w "${feature}")"
		if [[ -z "${exists}" ]]; then
			info Installing "${feature}"
			brew install "${feature}" >/dev/null
		fi
	done
}

configure_ferdi() {

	if [ -d /Applications/Ferdi.app ]; then
		info Adding Ferdi features
		FERDI_HOME="${HOME/Library/Application Support/Ferdi/recipes}"
		export FERDI_DEV_BASE_DIR="${FERDI_HOME}"/dev
		if [ -x ferdi-anylist.sh ]; then
			./ferdi-anylist.sh
		elif [ -x os-bootstraps/ferdi-anylist.sh ]; then
			./os-bootstraps/ferdi-anylist.sh
		fi
		CONFIG_FILE="${FERDI_HOME/hangoutschat/index.js}"
		if [ -f "${CONFIG_FILE}" ] && command -v gsed >/dev/null 2>&1; then
			info Fixing up Hangouts Chat Config
			gsed -i 's|https://chat.google.com|https://dynamite-preprod.sandbox.google.com|g' "${CONFIG_FILE}"
			gsed -i 's|Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:72.0) Gecko/20100101 Firefox/72.0|Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36|' "${CONFIG_FILE}"
		fi
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
		fail_exit Not OS X, stopping
	fi

	configure_homebrew
	configure_ferdi
	configure_git
	configure_fonts
	configure_sudo
}

main
