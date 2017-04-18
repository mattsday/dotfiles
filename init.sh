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
vimrc
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
	if [ -f "$HOME/.$dotfile" ] && [ ! -L "$HOME/.$dotfile" ]; then
		echo Backing up local "$dotfile"
		mv -f "$HOME/.$dotfile" "backup/local-$dotfile"
	fi
	echo "Creating $HOME/.$dotfile"
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

# Add ssh config file:
if [ -d "$HOME/.ssh" ]; then
	if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
		echo Backing up old ssh config
		mv -f "$HOME/.ssh/config" "backup/local-ssh-config"
	fi
	echo "Creating $HOME/.ssh/config"
	ln -fs "$PWD/ssh_config" "$HOME/.ssh/config"
	chmod 600 "$HOME/.ssh/config"
fi

# Add nvim config file (same as vimrc):
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
fi
ln -fs "$PWD/vimrc" "$HOME/.config/nvim/init.vim"

# Visual studio code
if [ -d "$HOME/Library/Application Support/Code/User" ]; then
	VS_DIR="$HOME/Library/Application Support/Code/User"
elif [ -d "$HOME/.config/Code/User" ]; then
	VS_DIR="$HOME/.config/Code/User"
fi
if [ "$VS_DIR" ]; then
	VS_SETTINGS="$VS_DIR/settings.json"
	if [ -f "$VS_SETTINGS" ]  && [ ! -L "$VS_SETTINGS" ]; then
		echo Backing up $VS_SETTINGS
		mv "$VS_SETTINGS" "backup/local_settings.json"
	fi
	ln -fs "$PWD/settings.json" "$VS_SETTINGS"
	echo Creating $VS_SETTINGS
fi

echo Setting up aliases
sh ./update_aliases force
echo Done.
