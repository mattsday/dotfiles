# Matt Day's custom .zshrc file
# This sets my favourite zsh features and loads most of my common
# bourne shell settings from .shell_common
# Latest copy always here: https://github.com/mattsday/dotfiles/
#
# shellcheck disable=SC1091,SC2148,SC1090,SC2154,SC2016

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# If not running interactively, don't do anything
[[ -z "$PS1" ]] && return

# If there's a local /etc/profile then evaluate that
if [ -f /etc/profile ]; then
    emulate sh -c '. /etc/profile'
fi

# Load any local config first (aliases should go in _local file)
if [[ -f "$HOME/.zshrc_config" ]]; then
	. "$HOME/.zshrc_config"
fi

# Load colour names so they can be referred to as green, yellow etc
autoload -U colors && colors

# Enable command line editing
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

# Never beep
unsetopt BEEP

# Initialise the autocompletion library
zmodload zsh/complist
autoload -U complist


# Check if autocomplete will work via -Uz
autoload -Uz compinit 2>/dev/null
comp_support=$?
if (( comp_support > 0 )); then
	autoload -U compinit 2>/dev/null
	comp_support=$?
fi
if (( comp_support == 0 )); then
	compinit
    # Enable Kubernetes autocompletion if available
    if command -v kubectl >/dev/null 2>&1; then
        . <(kubectl completion zsh)
    fi
fi

# Load some utilities such as zstyle and zformat
autoload -U zutil

# If a terminal is bold enough to claim XTERM let's assume it can do 256 colours!
[[ "$TERM" == "xterm" ]] && export TERM=xterm-256color

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life a little bit better...

shell_options=(
	noautomenu 	# don't select stuff automatically when tabbing if there are options
	auto_cd 	# Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
	extendedglob 	# Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
	noclobber 	# Require '>!' instead of '>' to overwrite a file
	correct		# Correct common errors
	prompt_subst	# Allow dynamic prompt
)

for o in "${shell_options[@]}"; do
    setopt "$o"
done

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
if [[ -f "$HOME/.shell_common" ]]; then
	. "$HOME/.shell_common"
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

# Evalate directory colours if gnu coreutils is present
if command -v dircolors > /dev/null 2>&1; then
    eval "$(dircolors -b)" && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
elif command -v gdircolors > /dev/null 2>&1; then
    eval "$(gdircolors -b)" && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
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
vcs_support=true
if ! autoload -Uz vcs_info 2>/dev/null; then
	if ! autoload -U vcs_info 2>/dev/null; then
        vcs_support=false
    fi
fi

zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' actionformats '(%s)-[%b|%a] (%a)'
zstyle ':vcs_info:*' formats       '(%s)-[%b]'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b:%r'

# Use the same completion for mosh as ssh:
compdef mosh=ssh

# Enable caching of completion output to speed it up
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh_cache

# Add GCP support
if [ -f "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc" ]; then
	. /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc
elif [ -f "/usr/share/google-cloud-sdk/completion.zsh.inc" ]; then
    . /usr/share/google-cloud-sdk/completion.zsh.inc
fi

if (( colours >= 8 )); then
    unset PROMPT
	# Custom prompt (coloured in yellow and cyan):
	# If the user is 'matt' don't print it
    case "$USER" in
        matt|mattsday)
            ;;
        *)
            PROMPT="%B%F{green}%n%f%b@"
            ;;
    esac
    PROMPT+="%B%F{yellow}%2m%f%b:%B%F{cyan}%~%f%b%# "
    # Append git info
	RPROMPT+='%B%F{green}${vcs_info_msg_0_}%b%f'
else
    case "$USER" in
        matt|mattsday)
    		PROMPT="%2m:%~%# "
            ;;
        *)
		    PROMPT="%n@%2m:%~%# "
            ;;
    esac
    # Append git info
    RPROMPT='${vcs_info_msg_0_}'
fi


# Update the terminal title and version control info
case $TERM in
	xterm*)
		precmd () {
			# Check directory for git etc
			if [[ $vcs_support == true ]]; then
				vcs_info
			fi
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
if [[ -f "$HOME/.zshrc_local" ]]; then
	. "$HOME/.zshrc_local"
fi

# Finally, load fish style syntax highlighting if available
if [[ -f "$HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
	. "$HOME/.zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# vim: syntax=zsh
