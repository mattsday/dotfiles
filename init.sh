#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...

# horrible but I want it over multiple lines and usable by standard shells...
dotfiles="
zshrc
tcshrc
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
proxy_settings
proxy_settings_csh
"

for dotfile in $dotfiles; do
	echo "Creating $HOME/.$dotfile"
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

# Add ssh config file:
if [ -d "$HOME/.ssh" ]; then
	echo "Creating $HOME/.ssh/config"
	ln -fs "$PWD/ssh_config" "$HOME/.ssh/config"
fi

# Add nvim config file (same as vimrc):
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
fi
ln -fs "$PWD/vimrc" "$HOME/.config/nvim/init.vim"
echo Done.
