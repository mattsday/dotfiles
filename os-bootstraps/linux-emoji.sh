#!/bin/sh
echo Setting up linux emoji
if [ -x /usr/bin/apt-get ]; then
    sudo apt-get -y install fonts-noto'*' >/dev/null
fi

if [ -d "$HOME"/.config/fontconfig ]; then
    mkdir -p "$HOME"/.config/fontconfig
fi

if [ -f "$HOME"/.config/fontconfig/fonts.conf ] && [ ! -L "$HOME"/.config/fontconfig/fonts.conf ]; then
    echo Backing up local fonts.conf
    cp "$HOME"/.config/fontconfig/fonts.conf "$PWD"/backup/local-fonts.conf
fi

ln -fs "$PWD"/fonts.conf "$HOME"/.config/fontconfig

fc-cache -f -v >/dev/null