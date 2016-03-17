# Matt Day's custom .bashrc file
# Not sure where I got all this from, it showed up along the way!
# As bash is the poor cousin to zsh, so this rcfile is to my zshrc...
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

[[ "$TERM" == "xterm" ]] && export TERM=xterm-256color

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life that little bit better...

# Don't put duplicate lines in the history
export HISTCONTROL=ignoredups

# Update lines and columns
shopt -s checkwinsize


shopt -s extglob         # Expanded globbing (i.e. allow 'ls -d ^*.jpg' to show non-jpg files)
shopt -s cdspell         # Mispelled directory names
set -o noclobber         # Require '>|' instead of '>' to overwrite a file

# Apple bundle a ridiculously old version of bash with OSX due to their objection to GPL3...
# Guess us users must write crappy hacks to work around it... thanks Apple!
if [[ $BASH_VERSION == 4* ]]; then
	shopt -s autocd		# Auto CD (i.e. can type '..' to change to parent directory, or 'bin' to change to ./bin)
	shopt -s dirspell	# Correct spelling on directory names during globbing
fi

# Make auto completion more zsh-like
bind 'set show-all-if-ambiguous on'

# Extended globbing
shopt -s extglob

# Bash completion (check homebrew first on OS X)
if [[ -f /usr/local/etc/bash_completion ]]; then
	. /usr/local/etc/bash_completion
elif [[ -f /etc/bash_completion ]]; then
	. /etc/bash_completion
fi

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# Load basic aliases from common set (zsh & bash compatible)
if [[ -f .shell_common ]]; then
	source .shell_common
fi

# ===========
# Look & Feel
# ===========
# Specific options that affect the L&F of the shell

# Custom prompt (coloured in yellow and cyan): user@host:~%
PS1='\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;36m\]\w\[\033[00m\]\$ '

# If this is an xterm set the title to user@host:dir
case "$TERM" in xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;${USER}: ${PWD/$HOME/~}\007"' ;; *)  ;;
esac

# Check if OpenStack RC file exists:
if [[ -f .openstack_credentials ]]; then
	source .openstack_credentials
fi

# DEPRECATED: Alias definitions.
if [ -f ~/.bash_aliases ]; then
    echo "bash_aliases is deprecated; move to .bash_local"
    . ~/.bash_aliases
fi

# Local bashrc config (paths etc) (should be the last thing loaded)
if [ -f ~/.bash_local ]; then
    . ~/.bash_local
fi


