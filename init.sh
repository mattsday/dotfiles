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
"

for dotfile in $dotfiles
do
	ln -fs $PWD/$dotfile $HOME/.$dotfile
done
