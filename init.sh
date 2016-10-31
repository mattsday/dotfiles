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
tmux.conf
shell_common
bash_profile
proxy_settings
"

for dotfile in $dotfiles; do
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

# Add ssh config file:
if [ -d "$HOME/.ssh" ]; then
	ln -fs "$PWD/ssh_config" "$HOME/.ssh/config"
fi

# Add nvim config file (same as vimrc):
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
fi
ln -fs "$PWD/vimrc" "$HOME/.config/nvim/init.vim"
