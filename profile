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

# Load any local config first (aliases should go in _local file)
if [ -f "$HOME/.profile_config" ]; then
	. "$HOME/.profile_config"
fi


# =============
# Shell Options
# =============
# Various options, features and keybinds that make life a little bit better...

# Don't put duplicate lines in the history
#set -o noclobber	# Require '>|' instead of '>' to overwrite a file
#set -o emacs		# Run in EMACS compatible mode (ctrl-a/e)

# History management
HISTSIZE=25000
HISTFILE=~/.sh_history
SAVEHIST=10000S
HISTCONTROL=ignoredups
export HISTSIZE HISTFILE SAVEHIST HISTCONTROL

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# Load basic aliases from common set (zsh & bash compatible)
if [ -f "$HOME/.shell_common" ]; then
	. "$HOME/.shell_common"
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell
#
hostname=`hostname`
if [ -z $hostname ]; then
	hostname=`cat /etc/hostname`
	if [ -z $hostname ]; then
		hostname='(none)'
	fi
fi
shorthost=`echo $hostname | sed 's/\..*//'`

# Dynamic prompt
# Some bourne shells don't support variables in the prompt, act to the lowest common denominator:
PS1="$USER@$shorthost$ "

dynamic_shell=0
if command -v readlink > /dev/null 2>&1; then
	case `readlink /bin/sh 2>/dev/null` in
		*busybox)
			# Enable a dynamic shell
			PS1=$USER'@\h:\w\$ '
			export PS1
			;;
		*bash)
			dynamic_shell=1
			;;
		*dash)
			dynamic_shell=0
			;;
		*)
			dynamic_shell=0
			;;
	esac
fi
if [ dynamic_shell = 1 ] || [ -f "$HOME/.full_shell" ]; then
	if [ $colours -ge 8 ]; then
		yellow="\033[01;33m"
		green="\033[01;32m"
		cyan="\033[01;36m"
		grey="\033[01;30m"
		end="\033[00m" 

		if [ "$USER" = "matt" ]; then
			PS1='$(echo "$yellow$shorthost$end:$cyan\c";if [ "${PWD#$HOME}" = "$PWD" ]; then echo "$PWD\c"; else echo "~${PWD#$HOME}\c";fi;echo "$end$ ")'
		else
			PS1='$(echo "$green$USER$end@$yellow$shorthost$end:$cyan\c";if [ "${PWD#$HOME}" = "$PWD" ]; then echo "$PWD\c"; else echo "~${PWD#$HOME}\c";fi;echo "$end$ ")'
		fi
	else
		if [ "$USER" = "matt" ]; then
			PS1='$(echo "$shorthost:\c";if [ "${PWD#$HOME}" = "$PWD" ]; then echo "$PWD\c"; else echo "~${PWD#$HOME}\c";fi;echo "$ ")'
		else
			PS1='$(echo "$USER@$shorthost:\c";if [ "${PWD#$HOME}" = "$PWD" ]; then echo "$PWD\c"; else echo "~${PWD#$HOME}\c";fi;echo "$ ")'
		fi
	fi
	export PS1
fi
# Check if OpenStack RC file exists:
if [ -f "$HOME/.openstack_credentials" ]; then
	. "$HOME/.openstack_credentials"
fi

# Local bourne shell config (paths etc) (should be the last thing loaded)
if [ -f "$HOME/.profile_local" ]; then
	. "$HOME/.profile_local"
fi

# vim: syntax=sh
