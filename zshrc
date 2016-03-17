# Matt Day's custom .zshrc file
# Not sure where I got all this from, it showed up along the way!
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# Load colour names so they can be referred to as green, yellow etc
autoload -U colors && colors

# Initialise the autocompletion library
zmodload zsh/complist
autoload -U complist
autoload -Uz compinit && compinit

# Load some utilities such as zstyle and zformat
autoload -U zutil

# 256 colour support pls
[[ "$TERM" == "xterm" ]] && export TERM=xterm-256color

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life that little bit better...

for option (
	noautomenu 	# don't select stuff automatically when tabbing if there are options
	auto_cd 	# Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
	extendedglob 	# Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
	noclobber 	# Require '>!' instead of '>' to overwrite a file
	correct		# Correct common errors
	prompt_subst	# Allow dynamic prompt
) setopt $option

# Ensure ctrl-a/ctrl-e for home/end respectively (emacs compatibility):
bindkey -e

# Map delete key (fn+backspace) on OS X correctly:
bindkey "^[[3~" delete-char

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

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# If vim exists somewhere, make it the default editor:
if [[ -x $(which vim 2> /dev/null) ]]; then
	export VISUAL=$(which vim)
	export USE_EDITOR=$VISUAL
	export EDITOR=$VISUAL
	# Some systems are cruel and have vi + vim installed side-by-side
	alias vi=$VISUAL
fi

# If we can sudo dodo!
if [[ -f /usr/bin/sudo ]]; then
	# Debian based systems
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
	if [[ -f /bin/launchctl ]]; then
		alias launchctl='sudo launchctl'
	fi
fi

if [[ -f /usr/local/bin/brew ]]; then
	alias update='brew update && brew upgrade'
fi

# Meh, shit happens:
alias 'cd..=cd ..'
alias 'cd~=cd ~'

# Common shortcuts
alias ll='ls -lah'
alias l='ls -aCF'

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

# Set some completion styles and features
zstyle ':completion:*:descriptions' format "- %d -"
zstyle ':completion:*:corrections' format "- %d - (errors %e})"
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
zstyle ':completion:*' menu select
zstyle ':completion:*' verbose yes
zstyle ':completion:*' rehash yes

# Native Git directory information
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a]'
zstyle ':vcs_info:*' formats       '(%s)-[%b]'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%r'

# Custom prompt (coloured in yellow and cyan): user@host:~%
PROMPT="%{$fg_bold[yellow]%}%n@%m%{$reset_color%}:%{$fg_bold[cyan]%}%~%{$reset_color%}%# %{$reset_color%}"

# Date on right-side including return code + git info [0][09:30:00]
RPROMPT='%{$reset_color%}%F{green}${vcs_info_msg_0_}%{$reset_color%}[%?]%{$fg_bold[grey]%}[%D{%H:%M:%S}]%{$reset_color%}'

# Update the terminal title and version control info
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

# ======================
# Plug-ins and Resources
# ======================
# Check for (and source) additional plugins and resources, such as local config files

# Check if OpenStack RC file exists:
if [[ -f .openstack_credentials ]]; then
	source .openstack_credentials
fi

# Fish style syntax highlighting
if [[ -f .zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source .zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Load local system stuff (local PATH, aliases etc) - this should be loaded last
if [[ -f .zsh_local ]]; then
	source .zsh_local
fi

