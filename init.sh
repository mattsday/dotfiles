#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...
# shellcheck disable=SC1091

# Load dependencies
. ./dotfiles/dependencies

mkdir backup >/dev/null 2>&1

# shellcheck disable=SC2154
for i in $dotfiles; do
	verb=Updating
	dotfile="$(basename "$i")"
	if [ -f "$HOME/.$dotfile" ] && [ ! -L "$HOME/.$dotfile" ]; then
		echo Backing up local ."$dotfile" to "${PWD}/backup/local-$dotfile"
		mv -f "$HOME/.$dotfile" "${PWD}/backup/local-$dotfile"
		verb="Creating"
	elif [ ! -f "$HOME/.$dotfile" ]; then
		verb="Creating"
	fi
	echo "$verb $HOME/.$dotfile"
	ln -fs "$PWD/$i" "$HOME/.$dotfile"
done

# shellcheck disable=SC2154
for i in $configdirs; do
	verb=Updating
	destination_dir="$HOME"/.config/"$(basename "$i")"
	if [ -d "$i" ]; then
		if [ ! -d "$destination_dir" ]; then
			mkdir "$destination_dir" || echo Warning failed to create dir "$destination_dir"
		fi
		for j in "$i"/*; do
			destination_file="$destination_dir"/"$(basename "$j")"
			if [ -f "$destination_file" ] && [ ! -L "$destination_file" ]; then
				echo Backing up local "$destination_file" to "${PWD}/backup/local-$(basename "$j")"
				mv -f "$destination_file" "${PWD}/backup/local-$(basename "$j")"
				verb="Creating"
			elif [ ! -f "$destination_file" ]; then
				verb="Creating"
			fi
			echo "$verb $destination_file"
			ln -fs "$PWD/$j" "$destination_file"
		done
	fi
done

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
ln -fs "$PWD/dotfiles/home/vimrc" "$HOME/.config/nvim/init.vim"

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
	ln -fs "$PWD/dotfiles/special/vscode/settings.json" "$VS_SETTINGS"
fi

sh "$HOME"/.update_aliases force
echo Done.
