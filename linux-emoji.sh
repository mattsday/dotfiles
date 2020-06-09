#!/bin/sh
sudo apt -y install fonts-noto'*'

mkdir -p "$HOME"/.config/fontconfig

if [ -f "$HOME"/.config/fontconfig/fonts.conf ]; then
    echo Backing up local fonts.conf
    cp "$HOME"/.config/fontconfig/fonts.conf "$PWD"/backup/local-fonts.conf
fi

ln -fs "$PWD"/fonts.conf "$HOME"/.config/fontconfig

fc-cache -f -v

echo Done


