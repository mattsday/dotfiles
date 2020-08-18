#!/bin/sh
echo Setting up linux emoji
if [ -x /usr/bin/apt-get ]; then
    DEBIAN_FRONTEND="noninteractive" sudo apt-get "$@" -y install fonts-noto'*' >/dev/null
else
    echo Note - you should install fonts-noto-'*' after this
fi

if [ -L "$HOME"/.config/fontconfig ]; then
    rm "$HOME"/.config/fontconfig
fi

if [ ! -d "$HOME"/.config/fontconfig ]; then
    mkdir -p "$HOME"/.config/fontconfig
fi

if [ -f "$HOME"/.config/fontconfig/fonts.conf ] && [ ! -L "$HOME"/.config/fontconfig/fonts.conf ]; then
    echo Backing up local fonts.conf
    cp "$HOME"/.config/fontconfig/fonts.conf "$PWD"/backup/local-fonts.conf
fi

SOURCE_FILE="$PWD"/dotfiles/special/fontconfig/fonts.conf
if [ ! -f "$SOURCE_FILE" ]; then
    BASE="$(dirname "$PWD" | xargs)"
    SOURCE_FILE="$BASE"/dotfiles/special/fontconfig/fonts.conf
fi

ln -fs "$SOURCE_FILE" "$HOME"/.config/fontconfig/fonts.conf >/dev/null

fc-cache -f -v >/dev/null
