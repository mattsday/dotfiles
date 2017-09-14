#!/bin/zsh

# Only run on a mac
OS=$(uname)
if [[ "$OS" != "Darwin" ]]; then
	echo Not OS X, stopping
	exit
fi

# Is homebrew installed?
if [[ ! -x /usr/local/bin/brew ]]; then
	# Install homebrew
	echo Installing homebrew
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# NOW is homebrew installed?
if [[ ! -x /usr/local/bin/brew ]]; then
	echo Homebrew installation failed. Aborting
	exit
fi
installed=$(brew list)
features=(
	gawk
	grep
	coreutils
	android-platform-tools
	zsh
	bash
	htop
	gnu-sed
	gnu-tar
	gnu-which
	maven
	multimarkdown
	flac
	fish
	findutils
	tmux
	unrar
	vim
	wget
	youtube-dl
	cf-cli
	dash
	kubernetes-cli
	cmake
	awscli
	bosh-init
	bosh-cli
	gradle
	mutt
	node
	python
	python3
	sqlite
	tcsh
	xz
)
for feature in $features; do
	exists=$(echo $installed | grep -w $feature)
	if [[ -z $exists ]]; then
		echo Installing $feature
		brew install $feature > /dev/null 
	fi
done

if [[ -x "$HOME/.update_aliases" ]]; then
	$HOME/.update_aliases force
fi
