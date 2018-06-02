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

# Update homebrew
echo Updating homebrew
brew update >/dev/null
echo Updating system
brew upgrade >/dev/null
brew cleanup >/dev/null

# Set up some taps
echo Setting up brew taps
brew tap caskroom/cask >/dev/null
brew tap cloudfoundry/tap >/dev/null


installed=$(brew list)
features=(
	gawk
	grep
	coreutils
	zsh
	bash
	htop
	gnu-sed
	gnu-tar
	gnu-which
	maven
	multimarkdown
	flac
	jq
	fish
	findutils
	tmux
	unrar
	vim
	wget
	youtube-dl
	cf-cli
	dash
	watch
	kubernetes-cli
	cmake
	awscli
	bosh-init
	gradle
	mutt
	node
	python
	python3
	sqlite
	tcsh
	azure-cli
	mkvtoolnix
)
for feature in $features; do
	exists=$(echo $installed | grep -w $feature)
	if [[ -z $exists ]]; then
		echo Installing $feature
		brew install $feature > /dev/null 
	fi
done

# Install casks
installed=$(brew cask list)
features=(
	android-sdk
	google-cloud-sdk
	xquartz
	fly
	qlmarkdown
	quicklook-json
	qlcolorcode
	qlstephen
	qlimagesize
	qlvideo
)
for feature in $features; do
	exists=$(echo $installed | grep -w $feature)
	if [[ -z $exists ]]; then
		echo Installing $feature
		brew cask install $feature > /dev/null 
	fi
done

if [[ -x "$HOME/.update_aliases" ]]; then
	$HOME/.update_aliases force
fi

