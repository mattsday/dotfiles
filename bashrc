# Matt Day's custom .bashrc file
# This sets a few useful bash options and loads most of my common
# bourne shell settings from .shell_common
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# If not running interactively, don't do anything
[[ -z "$PS1" ]] && return

# Load any local config first (aliases should go in _local file)
if [[ -f "$HOME/.bashrc_config" ]]; then
	. "$HOME/.bashrc_config"
fi

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life a little bit better...

# Don't put duplicate lines in the history
export HISTCONTROL=ignoredups

# Update lines and columns
shopt -s checkwinsize

shopt -s extglob  # Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
shopt -s cdspell  # Mispelled directory names
set -o noclobber  # Require '>|' instead of '>' to overwrite a file
set +o histexpand # Disable history expansion (i.e. make echo "Hello World!" work!)

# Apple bundle a ridiculously old version of bash with OSX due to their
# objection to GPL3... Guess us users must write crappy hacks to work around
# it... thanks Apple!
if ((BASH_VERSINFO >= 4)); then
	shopt -s autocd   # Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
	shopt -s dirspell # Correct spelling on directory names during globbing
fi

# Make auto completion more zsh-like
bind 'set show-all-if-ambiguous on'

# Bash completion (check homebrew first on OS X)
if [[ -f "/usr/local/etc/bash_completion" ]]; then
	. "/usr/local/etc/bash_completion"
elif [[ -f "/etc/bash_completion" ]]; then
	. "/etc/bash_completion"
fi

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# Load basic aliases from common set (zsh & bash compatible)
if [[ -f "$HOME/.shell_common" ]]; then
	. "$HOME/.shell_common"
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

if ((colours >= 8)); then
	yellow="\\[\\033[01;33m\\]"
	green="\\[\\033[01;32m\\]"
	cyan="\\[\\033[01;36m\\]"
	end="\\[\\033[00m\\]"

	# Custom prompt (coloured in yellow and cyan): user@host:~%
	if [[ $USER == "matt" ]]; then
		PS1="$yellow\\h$end:$cyan\\w$end\$ "
	else
		PS1="$green\\u$end@$yellow\\h$end:$cyan\\w$end\$ "
	fi
	unset yellow cyan green end
else
	if [[ $USER == "matt" ]]; then
		PS1='\h:\w\$ '
	else
		PS1='\u@\h:\w\$ '
	fi
fi

# If this is an xterm set the title to host:dir
case "$TERM" in xterm* | rxvt*)
	PROMPT_COMMAND='echo -ne "\033]0;$HOSTNAME:${PWD/$HOME/~}\007"'
	;;
*) ;;
esac

# Load local system stuff (local PATH, aliases etc)
if [[ -f "$HOME/.bashrc_local" ]]; then
	. "$HOME/.bashrc_local"
fi

# vim: syntax=sh
