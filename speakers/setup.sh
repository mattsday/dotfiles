#!/bin/sh

error() {
    echo >&2 "$1"
    exit 1
}

check_file() {
    if [ ! -f "$1" ]; then
        error "Cannot find file $1"
    fi
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Cannot find command $1 - is it installed?"
    fi
}

check_file speaker-keepalive.sh
check_file speaker-keepalive.service
check_file 22000.wav

check_command paplay

mkdir -p "$HOME"/.local/share/systemd/user || error Could not create "$HOME"/.local/share/systemd/user
sudo mkdir -p /usr/local/share/speakers || error Could not create /usr/local/share/speakers

sudo cp speaker-keepalive.sh /usr/local/bin || error Could not copy keepalive runtime to /usr/local/bin
sudo chmod +rx /usr/local/bin/speaker-keepalive.sh || error Could not make script executable
sudo cp 22000.wav /usr/local/share/speakers || error Could not copy audio file
sudo chmod +r /usr/local/share/speakers/22000.wav || error Could not set file permissions on audio file
cp speaker-keepalive.service "$HOME"/.local/share/systemd/user || Could not copy systemd unit file

systemctl --user daemon-reload
systemctl enable --now --user speaker-keepalive.service || error Could not start systemd service
