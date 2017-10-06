#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...

# horrible but I want it over multiple lines and usable by standard shells...
dotfiles="
alias_list
update_aliases
update_proxy
zshrc
cshrc
tcsh_settings
vimrc
bashrc
kshrc
muttrc
screenrc
profile
tmux.conf
shell_common
bash_profile
"

mkdir backup > /dev/null 2>&1

for dotfile in $dotfiles; do
	verb=Updating
	if [ -f "$HOME/.$dotfile" ] && [ ! -L "$HOME/.$dotfile" ]; then
		echo Backing up local ."$dotfile" to $PWD/backup/local-$dotfile
		mv -f "$HOME/.$dotfile" "backup/local-$dotfile"
		verb=Creating
	elif [ ! -f "$HOME/.$dotfile" ]; then
		verb=Creating
	fi
	echo "$verb $HOME/.$dotfile"
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

# Add nvim config file (same as vimrc):
verb=Updating
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
	verb=Creating
elif [ -f "$HOME/.config/nvim/init.vim" ] && [ ! -L "$HOME/.config/nvim/init.vim" ]; then
	echo "Backing local nvim config to backup/local-init.vim"
	mv -f "$HOME/.config/nvim/init.vim" "backup/local-init.vim"
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
	echo "Backing up local fish config to backup/local-config.fish"
	mv -f "$HOME/.config/fish/config.fish" "backup/local-config.fish"
	verb=Creating
elif [ ! -f "$HOME/.config/fish/config.fish" ]; then
	verb=Creating
fi
ln -fs "$PWD/config.fish" "$HOME/.config/fish/config.fish"
echo "$verb $HOME/.config/fish/config.fish"

# Firefox userChrome.css file
if [ -d "$HOME/Library/Application Support/Firefox" ]; then
	FF_PROFILE_PATH="$HOME/Library/Application Support/Firefox"
elif [ -d "$HOME/.mozilla/firefox" ]; then
	FF_PROFILE_PATH="$HOME/.mozilla/firefox"
fi
FF_PROFILE_INI="$FF_PROFILE_PATH/profiles.ini"


verb=Updating
if [ -f "$FF_PROFILE_INI" ]; then
	if [ `grep '\[Profile[^0]\]' "$FF_PROFILE_INI" 2>/dev/null` ]; then
		FF_PROFILE=`tr < "$FF_PROFILE_INI" -s '\n' '|' | sed 's/\[Profile[0-9]\]/\x0/g; s/$/\x0/; s/.*\x0\([^\x0]*Default=1[^\x0]*\)\x0.*/\1/; s/.*Path=\([^|]*\)|.*/\1/'`
	else
		FF_PROFILE=`grep 'Path=' "$FF_PROFILE_INI" 2>/dev/null | sed 's/^Path=//' 2>/dev/null`
	fi
	FF_PROFILE_PATH="$FF_PROFILE_PATH/$FF_PROFILE"

	if [ -d "$FF_PROFILE_PATH" ]; then
		if [ ! -d "$FF_PROFILE_PATH/chrome" ]; then
			mkdir -p "$FF_PROFILE_PATH/chrome"
			verb=Creating
		fi
		USER_CHROME="$FF_PROFILE_PATH/chrome/userChrome.css"
		if [ -f "$USER_CHROME" ] && [ ! -L "$USER_CHROME" ]; then
			echo Backing local up $USER_CHROME to "backup/userChrome.css"
			mv "$USER_CHROME" "backup/userChrome.css"
			verb=Creating
		fi
		echo $verb $USER_CHROME
		ln -fs "$PWD/userChrome.css" "$USER_CHROME"
	fi
fi

# Visual studio code
verb=Updating
if [ -d "$HOME/Library/Application Support/Code/User" ]; then
	VS_DIR="$HOME/Library/Application Support/Code/User"
elif [ -d "$HOME/.config/Code/User" ]; then
	VS_DIR="$HOME/.config/Code/User"
fi
if [ "$VS_DIR" ]; then
	VS_SETTINGS="$VS_DIR/settings.json"
	if [ -f "$VS_SETTINGS" ] && [ ! -L "$VS_SETTINGS" ]; then
		echo Backing up local $VS_SETTINGS to backup/local_settings.json
		mv "$VS_SETTINGS" "backup/local_settings.json"
		verb=Creating
	elif [ ! -f "$VS_SETTINGS" ]; then
		verb=Creating
	fi
	echo $verb $VS_SETTINGS
	ln -fs "$PWD/settings.json" "$VS_SETTINGS"
fi

sh ./update_aliases force
echo Done.
