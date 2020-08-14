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

# Update
function update
    # Debian-based
    if test -x /usr/bin/apt && test -x /usr/bin/dpkg
        apt update && apt full-upgrade
        # OS X
    else if test -x /usr/local/bin/brew
        brew update
        brew upgrade
        brew cleanup
        brew doctor
        # Arch-based
    else if test -x /usr/bin/pacman
        # Arch linux use yay if it's there
        if test -x /usr/bin/yay
            yay -Syu
        else
            pacman -Syu
        end
        # Fedora-based
    else if test -x /usr/bin/dnf
        dnf update
        # Red Hat-based
    else if test -x /usr/bin/yum
        yum update
        # OpenBSD
    else if test -x /usr/sbin/pkg_add
        pkg_add -uvi
        # FreeBSD
    else if test -x /usr/sbin/pkg
        pkg update && pkg upgrade
        # SuSE
    else if test -x /usr/bin/zypper
        zypper update
    end
    # If there are any callbacks process them
    if test -n "$_UPDATE_CALLBACKS"
        set updates (string split : $_UPDATE_CALLBACKS)
        for i in $updates
            eval "$i"
        end
    end
end

# Set colours
set -u fish_color_cwd cyan
set -u fish_color_user green
set -u fish_color_host yellow
set -u fish_color_autosuggestion 808080
set -u fish_color_comment 00ff5f
set -u fish_color_redirection afffff
