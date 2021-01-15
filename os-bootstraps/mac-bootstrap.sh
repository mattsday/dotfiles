#!/bin/bash

# Only run on a mac
OS="$(uname)"
if [[ "$OS" != "Darwin" ]]; then
	echo Not OS X, stopping
	exit
fi

# Is homebrew installed?
if [[ ! -x /usr/local/bin/brew ]]; then
	# Install homebrew
	echo Installing homebrew
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

# NOW is homebrew installed?
if [[ ! -x /usr/local/bin/brew ]]; then
	echo Homebrew installation failed. Aborting
	exit
fi

# Update homebrew
echo Updating homebrew
brew update >/dev/null
echo Updating system
brew upgrade >/dev/null
brew cleanup >/dev/null

# Set up some taps
#echo Setting up brew taps
#brew tap homebrew/cask-cask >/dev/null

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
for feature in $features; do
	exists="$(echo "$installed" | grep -w "$feature")"
	if [[ -z "$exists" ]]; then
		echo Installing "$feature"
		brew install "$feature" >/dev/null
	fi
done

if [ -d /Applications/Ferdi.app ]; then
	echo Adding Ferdi features
	FERDI_HOME="$HOME/Library/Application Support/Ferdi/recipes"
	export FERDI_DEV_BASE_DIR="$FERDI_HOME"/dev
	if [ -x ferdi-anylist.sh ]; then
		./ferdi-anylist.sh
	elif [ -x os-bootstraps/ferdi-anylist.sh ]; then
		./os-bootstraps/ferdi-anylist.sh
	fi
	CONFIG_FILE="$FERDI_HOME/hangoutschat/index.js"
	if [ -f "$CONFIG_FILE" ] && command -v gsed >/dev/null 2>&1; then
		echo Fixing up Hangouts Chat Config
		gsed -i 's|https://chat.google.com|https://dynamite-preprod.sandbox.google.com|g' "$CONFIG_FILE"
		gsed -i 's|Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0|Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36|' "$CONFIG_FILE"
	fi
fi

# Install casks
#installed="$(brew list --cask)"
#features="
#	qlmarkdown
#	quicklook-json
#	qlcolorcode
#	qlstephen
#	qlimagesize
#	qlvideo
#"
#for feature in $features; do
#	exists="$(echo "$installed" | grep -w "$feature")"
#	if [[ -z "$exists" ]]; then
#		echo Installing "$feature"
#		brew cask install "$feature" >/dev/null
#	fi
#done
