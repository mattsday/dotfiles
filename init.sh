#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...

# Load dependencies
. ./dependencies

mkdir backup >/dev/null 2>&1

for dotfile in $dotfiles; do
	verb=Updating
	if [ -f "$HOME/.$dotfile" ] && [ ! -L "$HOME/.$dotfile" ]; then
		echo Backing up local ."$dotfile" to "${PWD}/backup/local-$dotfile"
		mv -f "$HOME/.$dotfile" "${PWD}/backup/local-$dotfile"
		verb="Creating"
	elif [ ! -f "$HOME/.$dotfile" ]; then
		verb="Creating"
	fi
	echo "$verb $HOME/.$dotfile"
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

verb=Updating
if [ ! -d "$HOME/.config/git" ]; then
	mkdir -p "$HOME/.config/git"
	verb=Creating
fi
if [ -f "$HOME/.config/git/ignore" ] && [ ! -L "$HOME/.config/git/ignore" ]; then
	echo "Backing up local gitignore config to ${PWD}/backup/local-ignore"
	mv -f "$HOME/.config/git/ignore" "${PWD}/backup/local-ignore"
fi
echo "$verb $HOME/.config/git/ignore"
ln -fs "$PWD/gitignore" "$HOME/.config/git/ignore"

# Add nvim config file (same as vimrc):
verb=Updating
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
	verb=Creating
elif [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
	echo "Backing local nvim config to ${PWD}/backup/local-init.vim"
	mv -f "$HOME/.config/nvim/init.vim" "${PWD}/backup/local-init.vim"
	verb=Creating
elif [ ! -f "$HOME/.config/nvim/init.vim" ]; then
	verb=Creating
fi
echo "$verb $HOME/.config/nvim/init.vim"
ln -fs "$PWD/vimrc" "$HOME/.config/nvim/init.vim"

# Add fish config file
verb=Updating
if [ ! -d "$HOME/.config/fish" ]; then
	mkdir -p "$HOME/.config/fish"
	verb=Creating
elif [ -f "$HOME/.config/fish/config.fish" ] && [ ! -L "$HOME/.config/fish/config.fish" ]; then
	echo "Backing up local fish config to ${PWD}/backup/local-config.fish"
	mv -f "$HOME/.config/fish/config.fish" "${PWD}/backup/local-config.fish"
	verb=Creating
elif [ ! -f "$HOME/.config/fish/config.fish" ]; then
	verb=Creating
fi
ln -fs "$PWD/config.fish" "$HOME/.config/fish/config.fish"
echo "$verb $HOME/.config/fish/config.fish"

verb=Updating
if [ -f "$FF_PROFILE_INI" ] && [ -d "$FF_PROFILE_PATH" ]; then
	if [ ! -d "$FF_PROFILE_PATH/chrome" ]; then
		mkdir -p "$FF_PROFILE_PATH/chrome"
		verb=Creating
	fi
	if [ -f "$USER_CHROME" ] && [ ! -L "$USER_CHROME" ]; then
		echo Backing up local "$USER_CHROME" to "${PWD}/backup/userChrome.css"
		mv "$USER_CHROME" "${PWD}/backup/local-userChrome.css"
		verb=Creating
	fi
	if [ ! -f "$USER_CHROME" ]; then
		verb=Creating
	fi
	echo "$verb" "$USER_CHROME"
	ln -fs "$LOCAL_CHROME" "$USER_CHROME"
fi

# Visual studio code
verb=Updating
if [ "$VS_DIR" ]; then
	VS_SETTINGS="$VS_DIR/settings.json"
	if [ -f "$VS_SETTINGS" ] && [ ! -L "$VS_SETTINGS" ]; then
		echo Backing up local "$VS_SETTINGS" to "${PWD}"/backup/local-settings.json
		mv "$VS_SETTINGS" "${PWD}/backup/local-settings.json"
		verb=Creating
	elif [ ! -f "$VS_SETTINGS" ]; then
		verb=Creating
	fi
	echo "$verb" "$VS_SETTINGS"
	ln -fs "$PWD/settings.json" "$VS_SETTINGS"
fi

sh ./update_aliases force
echo Done.
