#!/bin/bash

# horrible but I want it over multiple lines and usable by bash...
dotfiles="
zshrc
vimrc
bashrc
vimrc
muttrc
screenrc
tmux.conf
shell_common
bash_profile
"

for dotfile in $dotfiles
do
	ln -fs $PWD/$dotfile $HOME/.$dotfile
done

# Add ssh config file:
if [[ -d $HOME/.ssh ]]; then
	ln -fs $PWD/ssh_config $HOME/.ssh/config
fi
