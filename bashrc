#!/bin/bash
# Matt Day's .bashrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Bash completion
if [ -f /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# meh...
if [[ -e /usr/bin/sudo ]]; then
	alias apt-get='sudo apt-get'
	# I prefer aptitude over apt-get but muscle memory sucks
	if [[ -e /usr/bin/aptitude ]]; then
		alias apt-get="sudo aptitude"
		alias apt-cache="sudo aptitude"
	fi
fi

# Colour ls prompt (OS X):
export CLICOLOR="yes"
export LSCOLORS="gxhxfxcxcxdxcxcxcxgxgx"

# 256 colour support pls
if [[ $TERM != *256color* ]]; then
	export TERM=xterm-256color;
fi

# don't put duplicate lines in the history. See bash(1) for more options
export HISTCONTROL=ignoredups

# Update lines and columns
shopt -s checkwinsize

# Colour prompt :)
PS1='\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '

# If this is an xterm set the title to user@host:dir
case "$TERM" in xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}: ${PWD/$HOME/~}\007"' ;; *)  ;;
esac

# Local bashrc config (paths etc)
if [ -f ~/.bash_local ]; then
    . ~/.bash_local
fi

# DEPRECATED: Alias definitions.
if [ -f ~/.bash_aliases ]; then
    echo "bash_aliases is deprecated; move to .bash_local"
    . ~/.bash_aliases
fi
# Meh, shit happens:
alias 'cd..=cd ..'
alias 'cd~=cd ~'
# Common shortcuts
alias ls='ls --color=auto'
alias ll='ls -la'
alias l='ls -CF'
alias wget='wget --no-check-certificate'
alias dir='dir --color=auto'
alias grep='grep --color=auto'
export GREP_COLORS="ms=01;32:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"




# A few nice settings
shopt -s autocd          # Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
shopt -s extglob         # Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
shopt -s cdspell         # Mispelled directory names
set -o noclobber         # Require '>!' instead of '>' to overwrite a file

# Make auto completion more zsh-like
bind 'set show-all-if-ambiguous on'
#bind 'TAB:menu-complete'

# Extended globbing
shopt -s extglob
# 

export PATH=/usr/local/bin:/usr/local/sbin:$PATH

