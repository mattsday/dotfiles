# dotfiles
I use this to sync my various dotfiles between systems. It's not intended for people to use this, but no harm if they do.

1. zshrc
2. vimrc
3. bashrc
4. muttrc
5. screenrc
6. tmux.conf

There's a small bash compatible `init.sh` file to create the symlinks and off it goes. Nothing fancy, most of the logic is in the files themselves.

I maintain the `.zshrc` and `.vimrc` quite aggressively and manage the others if/when I have time.

In particular, the `.bashrc` is designed to be as compatible with my `.zshrc` as possible, especially if logging on to a system for a short amount of time (where installing zsh is too much of a pain)
