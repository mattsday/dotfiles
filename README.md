# dotfiles
I use this to sync my various dotfiles between systems. It's not intended for people to use this, but no harm if they do.

1. zshrc
2. vimrc
3. bashrc
4. bash_profile
5. muttrc
6. screenrc
7. tmux.conf
8. shell_common

There's a small bash compatible `init.sh` file to create the symlinks and off it goes. Nothing fancy, most of the logic is in the files themselves.

I maintain the `.zshrc` and `.vimrc` quite aggressively and manage the others if/when I have time.

In particular, the `.bashrc` is designed to be as compatible with my `.zshrc` as possible. This is managed via various shell options, a `shell_common` file (which loads aliases and environment variables for both zsh and bash) and similar themes. Compatibility is highest when running bash 4 or later.

The `bash_profile` exists purely to load the `.bashrc`, especially on OS X where the latter isn't loaded by default.
