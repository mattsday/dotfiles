# Load and update aliases
if test -e ~/.update_aliases
	~/.update_aliases
end
if test -e ~/.fish_aliases
	source ~/.fish_aliases
end

# Useful functions
function f
	find . -iname "*$argv*"
end

function gf
	grep -Ri "$argv"
end

# Set colours
set -u fish_color_cwd cyan
set -u fish_color_user green
set -u fish_color_host yellow
set -u fish_color_autosuggestion 808080
set -u fish_color_comment 00ff5f
set -u fish_color_redirection afffff
