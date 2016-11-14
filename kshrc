# Matt Day's custom .kshrc file
# Not sure where I got all this from, it showed up along the way!
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# If a terminal is bold enough to claim XTERM let's assume it can do 256 colours!
[ "$TERM" == "xterm" ] && export TERM=xterm-256color

# =======================
# Environment and Aliases
# =======================
# Check the environment and add aliases across various platforms

# Load basic aliases from common set (zsh & bash compatible)
if [ -f "$HOME/.shell_common" ]; then
	. "$HOME/.shell_common"
fi

shorthost=$(echo `hostname` | sed 's/\..*//')

if (( $colours >= 8 )); then
	yellow="\033[01;33m"
	green="\033[01;32m"
	cyan="\033[01;36m"
	grey="\033[01;30m"
	end="\033[00m" 

	if [ $USER = "matt" ]; then
		PS1='$(print -n "$yellow$shorthost$end:$cyan";if [ "${PWD#$HOME}" = "$PWD" ]; then print -n $PWD; else print -n "~${PWD#$HOME}";fi;print "$end$ ")'

	else
		PS1='$(print -n "$green$USER$end@$yellow$shorthost$end:$cyan";if [ "${PWD#$HOME}" = "$PWD" ]; then print -n $PWD; else print -n "~${PWD#$HOME}";fi;print "$end$ ")'
	fi
	unset yellow green cyan grey end
else
	if [ $USER = "matt" ]; then
		PS1='$(print -n "$shorthost:";if [ "${PWD#$HOME}" = "$PWD" ]; then print -n "$PWD"; else print -n "~${PWD#$HOME}";fi;print "$ ")'

	else
		PS1='$(print -n "$USER@$shorthost:";if [ "${PWD#$HOME}" = "$PWD" ]; then print -n "$PWD"; else print -n "~${PWD#$HOME}";fi;print "$ ")'
	fi
fi

# Set emacs style editing (makes life SO MUCH BETTER in ksh!)
set -o emacs
# Disable EOF (ctrl-d to quit terminal)
set -o ignoreeof
set -o noclobber

# For some environments where this doesn't get set by default:
alias __A=`echo "\020"` # up arrow = ^p = back a command
alias __B=`echo "\016"` # down arrow = ^n = down a command
alias __C=`echo "\006"` # right arrow = ^f = forward a character
alias __D=`echo "\002"` # left arrow = ^b = back a character
alias __H=`echo "\001"` # home = ^a = start of line
stty erase ^?		# bind backspace

# History management
export HISTSIZE=25000
export HISTFILE=~/.ksh_history
export SAVEHIST=10000

# If this is an xterm set the title to host:dir
case "$TERM" in xterm*|rxvt*)
    PROMPT_COMMAND='echo -ne "\033]0;$HOSTNAME:${PWD/$HOME/~}\007"' ;; *)  ;;
esac

# Local bashrc config (paths etc) (should be the last thing loaded)
if [ -f "$HOME/.kshrc_local" ]; then
    . "$HOME/.kshrc_local"
fi

# vim: syntax=sh
