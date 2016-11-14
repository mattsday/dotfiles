# dotfiles
These are the configuration files I use for my shells and applications. Most of the work is in maintaining my shell configuration, so I can step between systems with a consistent look and feel.

I maintain for the following shell environments:

1. zsh (primary shell)
2. bash (secondary for linux systems where installing zsh isn't worth it)
3. tcsh (for BSD systems, e.g. FreeBSD)
4. ksh (for BSD systems, e.g. NetBSD)
5. profile (for everything else bourne-compatible, e.g. OpenBSD, SunOS)

The goal is compatibility betwee the look, feel and features of shells (autocd, noclobber, prompt etc)

There's a small bourne compatible `init.sh` file to create symlinks. It will do this without mercy, deleting any rc files in its path.

The profile, bashrc, kshrc and zshrc all launch ```shell_common```, this is a bourne-compatible script that loads everything except shell-specific options. This makes these shells fairly consistent for things like aliases, environment variables etc. This file should work with any bourne compatible shell.

I also maintain various rc files for programs like vim and mutt. I try and document the settings as comments inside each one. These are typically updated less frequently.
