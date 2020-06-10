#!/bin/bash

fail() {
>&2 echo '[Failure]' "$@"
exit 1
}

warn() {
>&2 echo '[Warning]' "$@"
}

info() {
echo '[Info]' "$@"
}


test_root() {
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        warn This must be run as root - attempting to use sudo
        if ! sudo "$0" "$@"; then
            fail This must be run as root - e.g. "'sudo $0'"
        fi
        # Was successful as sudo so just exit
        exit
    fi
    fail This must be run as root
fi
}

install_apt_packages() {
APT_PACKAGES=(snapd kde-plasma-desktop plasma-widgets-addons plasma-wallpapers-addons)
APT_PACKAGES+=(libffmpegthumbnailer4v5 ffmpegthumbs ffmpegthumbnailer pulseaudio-module-bluetooth)
APT_PACKAGES+=(spotify-client sddm-theme-debian-breeze)

apt -y install "${APT_PACKAGES[@]}"
}

install_snaps() {
snap install chromium
snap install code --classic
snap install intellij-idea-ultimate --classic
}

passwordless_sudo() {
echo 'mattsday ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/nopasswd
AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true
}

main() {
test_root
# Install apt packages
install_apt_packages
install_snaps
passwordless_sudo

}


main