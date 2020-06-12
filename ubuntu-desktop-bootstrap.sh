#!/bin/bash

# TODO install spotify

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


install_apt_packages() {
APT_PACKAGES=(snapd kde-plasma-desktop plasma-widgets-addons plasma-wallpapers-addons)
APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer pulseaudio-module-bluetooth)
APT_PACKAGES+=(kde-spectacle openjdk-8-jdk openjdk-11-jdk)
INSTALL_PACKAGES=()
for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg -l "$package" >/dev/null 2>&1; then
        INSTALL_PACKAGES+=("$package")
    fi
done
if [ -z "${INSTALL_PACKAGES[*]}" ]; then
    echo Installing packages "${INSTALL_PACKAGES[@]}"
    sudo apt-get -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
fi
}

install_snaps() {
sudo snap install chromium >/dev/null || warn "Failed to install chromium"
sudo snap install code --classic >/dev/null || warn "Failed to install code"
sudo snap install intellij-idea-ultimate --classic >/dev/null || warn "Failed to install intellij-idea-ultimate"
}

passwordless_sudo() {
if [ ! -f /etc/sudoers.d/nopasswd ]; then
echo "$USER"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd
fi
}

bluetooth_setup() {
if [ ! -f "$HOME/.config/pulse/default.pa" ]; then
cat > "$HOME/.config/pulse/default.pa" <<EOF
.include /etc/pulse/default.pa

# Switch all audio playback to Bluetooth headphones when they are connected
.ifexists module-switch-on-connect.so
load-module module-switch-on-connect
.endif

# Enable automatic switching between A2DP and HSP/HFP
.ifexists module-bluetooth-policy.so
unload-module module-bluetooth-policy
load-module module-bluetooth-policy auto_switch=2
.endif

# Fix bluetooth headphones bug
.ifexists module-bluetooth-discover.so
unload-module module-bluetooth-discover
load-module module-bluetooth-discover
.endif
EOF
fi
}

emoji() {
    echo Setting up emoji
    if [ -f "$PWD/linux-emoji.sh" ]; then
        "$PWD/linux-emoji.sh"
    fi
}

main() {
passwordless_sudo
install_apt_packages
install_snaps
bluetooth_setup
emoji
}


main "$@"
