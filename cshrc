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

# Load alias definitions
if ( -e "$HOME/.update_aliases" ) then
	sh "$HOME/.update_aliases"
endif

if ( -e "$HOME/.csh_aliases" ) then
	source "$HOME/.csh_aliases"
endif

# Set some local utilities as default (this must be top of this file)

if ( -d /usr/local/bin) then
	set path = (/usr/local/bin $path)
endif
if ( -d /usr/local/sbin) then
	set path = (/usr/local/sbin $path)
endif

# =================
# Alias definitions
# =================
# Check the presence of various utilities and alias them to give them
# preference ahead of lesser system defaults

# find function to quickly look for things in pwd
alias f "find . -iname \*\!:1\*"

# Grep find
alias gf 'grep -Ri "\!:1"'

# =====================
# Environment variables
# =====================
# These affect most systems and are (usually) harmless if run without...

# Check if proxy settings have been created
if ( -f "$HOME/.csh_proxy_settings" ) then
	source "$HOME/.csh_proxy_settings"
endif

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
# Always rehash the PATH environment
set autorehash

# History management
set history = 25000
set histfile = ~/.csh_history
set savehist = ($history merge)

set HOSTNAME=localhost

if ( `where hostname` != "") then
    set HOSTNAME = `hostname|awk -F\. '{print $1}'`
endif

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
