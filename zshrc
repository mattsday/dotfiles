# Matt Day's custom .zshrc file
# Few bits made up, others thrown together etc
# Put in public domain for anyone to copy!

# Load colour names
autoload -U colors && colors

# 256 colour support pls
if [[ $TERM != *256color* ]]; then
	export TERM=xterm-256color;
fi

# Essentials...
# If vim exists somewhere, make it the default editor:
if [[ -x $(which vim 2> /dev/null) ]]; then
	export VISUAL=$(which vim)
	export USE_EDITOR=$VISUAL
	export EDITOR=$VISUAL
fi

# A few nice settings
for option (
	noautomenu 	# don't select stuff automatically when tabbing if there are options
	auto_cd 	# Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
	extendedglob 	# Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
	noclobber 	# Require '>!' instead of '>' to overwrite a file
	correct		# Correct common errors
	prompt_subst	# Allow dynamic prompt
) setopt $option

# If a command takes longer than 15 seconds, print its duration
export REPORTTIME=15

# Bash style word deletion (i.e. /usr/local/bin^w would just delete 'bin')
autoload -U select-word-style && select-word-style bash

# History management
export HISTSIZE=25000
export HISTFILE=~/.zsh_history
export SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Fancy command completion and style:
zmodload zsh/complist
autoload -U complist
autoload -U zutil
autoload -Uz compinit && compinit

# And set some styles...
zstyle ':completion:*:descriptions' format "- %d -"
zstyle ':completion:*:corrections' format "- %d - (errors %e})"
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*' rehash yes

# Ensure ctrl-a/ctrl-e for home/end respectively (emacs compatibility):
bindkey -e

# Map delete key (fn+backspace) on OS X correctly:
bindkey "^[[3~" delete-char

# Native Git directory information
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
zstyle ':vcs_info:*' formats       '(%s)-[%b]'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%r'

# Aliases
# First if sudo exists on the system then use it by default for some commands
if [[ -f /usr/bin/sudo ]]; then
	if [[ -f /usr/bin/apt-get ]]; then
		# I prefer aptitude over apt-get but muscle memory sucks
		if [[ -e /usr/bin/aptitude ]]; then
			alias apt-get='sudo aptitude'
			alias apt-cache='sudo aptitude'
		else
			alias apt-get='sudo apt-get'
		fi
		alias update='apt-get update && apt-get upgrade'
	fi
	# Same if using RPM-based distributions
	if [[ -f /usr/bin/yum ]]; then
		alias yum='sudo yum'
		alias update='yum update'
	fi
	# Always restart services as root
	if [[ -f /usr/sbin/service ]]; then
		alias service='sudo service'
	fi
fi

if [[ -f /usr/local/bin/brew ]]; then
	alias update='brew update && brew upgrade'
fi

# wget enforces certificates by default and I almost never care (dangerous I know)
alias wget='wget --no-check-certificate'

# Meh, shit happens:
alias 'cd..=cd ..'
alias 'cd~=cd ~'
# Common shortcuts
alias ll='ls -lah'
alias l='ls -CF'

# Custom prompt (coloured in yellow and cyan): user@host:~%
PROMPT="%{$fg_bold[yellow]%}%n@%m%{$reset_color%}:%{$fg_bold[cyan]%}%~%{$reset_color%}%# "

# Date on right-side including return code + git info [0][09:30:00]
RPROMPT='%F{green}${vcs_info_msg_0_}%{$reset_color%}'"[%?]%{$fg_bold[grey]%}[%D{%H:%M:%S}]%{$reset_color%}"

case $TERM in
    xterm*)
        precmd () {
		# Check directory for git etc
		vcs_info
		# Print xterm title (user@host:~)
		print -Pn "\e]0;%n@%m: %~\a"
	}
        ;;
esac

# Check if OpenStack RC file exists:
if [[ -f .openstack_credentials ]]; then
	source .openstack_credentials
fi

# Fish style syntax highlighting
if [[ -f .zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source .zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Load local system stuff (local PATH, aliases etc)
if [[ -f .zsh_local ]]; then
	source .zsh_local
fi

