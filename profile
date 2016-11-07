# Matt Day's custom .profile file
# This file is for legacy bourne shells. Really should be using zsh,
# bash or even ksh! Some systems don't and this makes them a little more
# usable...
# Latest copy always here: https://github.com/mattsday/dotfiles/
# If being called from another bourne compatible shell, load those
# specific rc files instead and stop this
case "$0" in
    -zsh)
        if [ -f "$HOME/.zshrc" ]; then
            . "$HOME/.zshrc"
        fi
        return
        ;;
    -bash)
        if [ -f "$HOME/.bashrc" ]; then
            . "$HOME/.bashrc"
        fi
        return
        ;;

    -ksh)
        if [ -f "$HOME/.kshrc" ]; then
            . "$HOME/.kshrc"
        fi
        return
        ;;
    *)
        ;;
esac

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# If not running interactively, don't do anything
[ -z "PS1" ] && return

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life a little bit better...

# Don't put duplicate lines in the history
export HISTCONTROL=ignoredups
set -o noclobber        # Require '>|' instead of '>' to overwrite a file
set -o emacs		    # Run in EMACS compatible mode (ctrl-a/e)

# Bash completion (check homebrew first on OS X)
if [ -f /usr/local/etc/bash_completion ]; then
	. /usr/local/etc/bash_completion
elif [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# History management
export HISTSIZE=25000
export HISTFILE=~/.sh_history
export SAVEHIST=10000

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# Load basic aliases from common set (zsh & bash compatible)
if [ -f $HOME/.shell_common ]; then
	. $HOME/.shell_common
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

if [ $USER = "matt" ]; then
	PS1='\h:\w\$ '
else
	PS1="$USER@\h:\w\$ "
fi

# If this is an xterm set the title to host:dir
case "$TERM" in xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;$HOSTNAME:${PWD/$HOME/~}\007"' ;; *)  ;;
esac

# Check if OpenStack RC file exists:
if [ -f $HOME/.openstack_credentials ]; then
	. $HOME/.openstack_credentials
fi

# Local bourne shell config (paths etc) (should be the last thing loaded)
if [ -f $HOME/.profile_local ]; then
    . $HOME/.profile_local
fi

# vim: syntax=sh
