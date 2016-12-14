# Matt Day's custom .cshrc file
# This should work on any csh based shell including tcsh
# Latest copy always here: https://github.com/mattsday/dotfiles/

# ==========
# Shell Init
# ==========
# Without these some options later may break...

# Load any local config first (aliases should go in _local file)
if ( -e "$HOME/.cshrc_config" ) then
	source "$HOME/.cshrc_config"
endif

# Set some local utilities as default (this must be top of this file)

if ( -d /usr/local/bin) then
	set path = (/usr/local/bin $path)
	# Create a homebrew update alias
	if (-x /usr/local/bin/brew) then
		alias update "brew update; brew upgrade; brew cleanup; brew doctor"
	endif
endif

# If running on OS X check for coreutils and use them with colour
if ( -x `sh -c 'which gls 2>/dev/null'` ) then
	alias ls "`which gls` --color=auto"
# Otherwise check if /usr/bin/dircolors exists which is a good sign it's GNU ls
else if ( -x /usr/bin/dircolors ) then
	alias ls 'ls --color=auto'
endif

# =================
# Alias definitions
# =================
# Check the presence of various utilities and alias them to give them
# preference ahead of lesser system defaults

# Always prefer vim!
if ( -x `sh -c 'which vim 2>/dev/null'` ) then
	setenv VISUAL `which vim`
	setenv USE_EDITOR $VISUAL
	setenv EDITOR $VISUAL
	# Some systems are cruel and have vi + vim installed side-by-side
	alias vi $VISUAL
endif
# Set less as the default pager
if ( -x `sh -c 'which less 2>/dev/null'` ) then
	setenv PAGER `which less`
endif
# If we can sudo dodo!
if ( -x /usr/bin/sudo || -x /usr/local/bin/sudo ) then
	# Debian based systems
	if ( -x /usr/bin/apt-get ) then
		# I prefer aptitude over apt-get but muscle memory sucks
		if ( -x /usr/bin/aptitude ) then
			alias aptitude 'sudo aptitude'
			alias apt-get 'aptitude'
			alias apt-cache "aptitude -F '%1p %40d# (%C) %D %10V'"
		else
			alias apt-get 'sudo apt-get'
		endif
		alias update 'apt-get update && apt-get upgrade'
	endif
	# Same if using RPM-based distributions
	if ( -x /usr/bin/yum ) then
		alias yum 'sudo yum'
		alias update 'yum update'
	endif
	# Oh Fedora you special little turkey...
	if ( -x /usr/bin/dnf ) then
		alias dnf 'sudo dnf'
		alias yum 'dnf'
		alias update 'dnf update'
	endif
	# SUSE based distributions
	if ( -x /usr/bin/zypper ) then
		alias zypper 'sudo zypper'
		alias update 'zypper update'
	endif

	# FreeBSD
	if ( -x /usr/sbin/pkg ) then
		alias pkg 'sudo pkg'
		alias update 'pkg update && pkg upgrade'
	endif

	if ( -x /usr/sbin/freebsd-update ) then
		alias freebsd-update 'sudo /usr/sbin/freebsd-update'
	endif

	# Always restart services as root
	if ( -x /usr/sbin/service ) then
		alias service 'sudo service'
	endif
endif
# Colour grep output (more proof csh sucks!)
set grep_ver = `sh -c 'grep --version 2>&1 | grep -m 1 -o "GNU" 2>/dev/null' | awk '{print length($0)}'`
if ( $grep_ver > 0 ) then
	alias grep 'grep --color=auto'
	alias egrep 'egrep --color=auto'
	alias fgrep 'fgrep --color=auto'
endif
setenv GREP_COLORS "ms=01;32:mc=01;31:sl=:cx=:fn=35:ln=32:bn=32:se=36"
unset grep_ver

# Meh, shit happens:
alias cd.. 'cd ..'
alias cd~ 'cd ~'
alias tmuxa 'tmux a'

# Common shortcuts
alias ll 'ls -lah'
alias l 'ls -aCF'
alias l. 'ls -d .*'

# find function to quickly look for things in pwd
alias f "find . -iname \*\!:1\*"

# Grep find
alias gf 'grep -Ri "\!:1"'


# =====================
# Environment variables
# =====================
# These affect most systems and are (usually) harmless if run without...

# Sets ls and various commands to use yyyy-mm-dd as the date format
setenv TIME_STYLE "long-iso"

# OS X ls colouring (non-gnu ls)
setenv CLICOLOR "yes"
setenv LSCOLORS "gxhxfxcxcxdxcxcxcxgxgx"

# Do we need to load proxy settings?
if ( -e "$HOME/.enable_proxy" ) then
	source $HOME/.proxy_settings_csh
endif

# Opt out of homebrew fucking analytics
setenv HOMEBREW_NO_ANALYTICS 1

# =============
# Shell Options
# =============
# Various options, features and keybinds that make life a little bit better...

# Auto CD
set implicitcd
# No clobber
set noclobber
# Autocomplete with colour
set autolist
set color
set colorcat
# Nobeeps
set nobeep
# No clobber (require >! to overwrite a file)
set noclobber
# Don't log out on ctrl-D
set ignoreeof
# Don't autologout either...
unset autologout
# 24 hour time please
unset ampm
# Add zeros to hours (e.g. 8:02 ==> 08:02)
set padhour
# Allow file completion on legacy
set filec

# History management
set history = 25000
set histfile = ~/.csh_history
set savehist = ($history merge)

set HOSTNAME = `hostname|awk -F \. '{print $1}'`
set prompt = "$USER@$HOSTNAME> "

# Load tcsh specific stuff
if ( $?tcsh ) then
	source "$HOME/.tcsh_settings"
endif

# Local system stuff (PATH, aliases etc)
if ( -e $HOME/.cshrc_local ) then
	source $HOME/.cshrc_local
endif

# vim: syntax=tcsh
