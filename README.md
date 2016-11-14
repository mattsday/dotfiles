# dotfiles
I use this to sync my various dotfiles between systems. It's not intended for people to use this, but no harm if they do.

I maintain for the following shell environments:

1. zsh (primary shell)
2. bash (secondary for linux systems where installing zsh isn't worth it)
3. tcsh (for BSD systems)
4. ksh (for BSD systems)
5. profile (for plain old bourne shells)
6. ```shell_common``` for all bourne shells (i.e. everything except tcsh)

The goal is compatibility betwee the look, feel and features of shells (autocd, noclobber, prompt etc)

There's a small bourne compatible `init.sh` file to create symlinks. It will do this without mercy, deleting any rc files in its path.

The profile, bashrc, kshrc and zshrc all launch ```shell_common```, this is a bourne-compatible script that loads everything except shell-specific options. This makes these shells fairly consistent for things like aliases, environment variables etc. This file should work with any bourne compatible shell.

I also maintain various rc files for programs like vim and mutt. I try and document the settings as comments inside each one. These are typically updated less frequently.
