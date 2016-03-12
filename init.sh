#!/bin/zsh

for dotfile (
	zshrc
	vimrc
	bashrc
	vimrc
	muttrc
	screenrc
	tmux.conf
	gitconfig
) ln -fs $HOME/dotfiles/$dotfile $HOME/.$dotfile
