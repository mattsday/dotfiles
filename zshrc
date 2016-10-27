# Matt Day's custom .zshrc file
# Not sure where I got all this from, it showed up along the way!
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# If not running interactively, don't do anything
[[ -z "$PS1" ]] && return

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
# Various options, features and keybinds that make life a little bit better...

for option (
	noautomenu 	# don't select stuff automatically when tabbing if there
			# are options
	auto_cd 	# Auto CD (i.e. can type '..' to change to 
			# parent directory, or 'bin' to change to ./bin)
	extendedglob 	# Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show 
			# non-jpg files)
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

# Load basic aliases from common set (zsh & bash compatible)
if [[ -f $HOME/.shell_common ]]; then
	source $HOME/.shell_common
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

# Evalate directory colours if gnu coreutils is present
if [[ -x $(which dircolors 2> /dev/null) ]]; then
	eval `$(which dircolors)` && zstyle ':completion:*' list-colors \
		${(s.:.)LS_COLORS}
elif [[ -x $(which gdircolors 2> /dev/null) ]]; then
	eval `$(which gdircolors)` && zstyle ':completion:*' list-colors \
		${(s.:.)LS_COLORS}
fi

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
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a] (%a)'
zstyle ':vcs_info:*' formats       '(%s)-[%b]'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%r'

# Use the same completion for mosh as ssh:
compdef mosh=ssh

# Enable caching of completion output to speed it up
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh_cache

# Test for number of colours
colours=$(tput colors)

# Check if colour is disabled manually
if [[ -f ~/.disable_shell_colour ]]; then
	colours=7
fi

if (( $colours >= 8 )); then
	# Custom prompt (coloured in yellow and cyan):
	# If the user is 'matt' don't print it
	if [[ $USER == "matt" ]]; then
		PROMPT="%{$fg_bold[yellow]%}%m%{$reset_color%}:%{$fg_bold[cyan]%}%~"
	else
		PROMPT="%{$fg_bold[green]%}%n%{$reset_color%}@%{$fg_bold[yellow]%}%m%{$reset_color%}:%{$fg_bold[cyan]%}%~"
	fi
	# Append directory info
	PROMPT+="%{$reset_color%}%# %{$reset_color%}"
else
	if [[ $USER == "matt" ]]; then
		PROMPT="%m:%~%# "
	else
		PROMPT="%n@%m:%~%# "
	fi
fi

# Date on right-side including return code + git info [0][09:30:00]
RPROMPT='%{$reset_color%}%F{green}${vcs_info_msg_0_}%{$reset_color%}[%?]'
RPROMPT+='%{$fg_bold[grey]%}[%D{%H:%M:%S}]%{$reset_color%}'

# Update the terminal title and version control info
case $TERM in
    xterm*)
        precmd () {
		# Check directory for git etc
		vcs_info
		# Print xterm title (user@host:~)
		print -Pn "\e]0;%m: %~\a"
	}
        ;;
esac

# ======================
# Plug-ins and Resources
# ======================
# Check for (and source) additional plugins and resources, such as local config
# files

# Check if OpenStack RC file exists:
if [[ -f $HOME/.openstack_credentials ]]; then
	source $HOME/.openstack_credentials
fi

# Load local system stuff (local PATH, aliases etc)
if [[ -f $HOME/.zsh_local ]]; then
	source $HOME/.zsh_local
fi

# Finally, load fish style syntax highlighting if available
if [[ -f $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
	source $HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# vim: syntax=zsh
