#!/bin/zsh

for dotfile (
	zshrc
	vimrc
	bashrc
	vimrc
	muttrc
	screenrc
	tmux.conf
) ln -fs $HOME/dotfiles/$dotfile $HOME/.$dotfile
