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


install_apt_packages() {
APT_PACKAGES=(snapd kde-plasma-desktop plasma-widgets-addons plasma-wallpapers-addons)
APT_PACKAGES+=(libffmpegthumbnailer4v5 ffmpegthumbs ffmpegthumbnailer pulseaudio-module-bluetooth)
APT_PACKAGES+=(spotify-client sddm-theme-debian-breeze blueman google-cloud-sdk google-cloud-sdk-anthos-auth)
APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl openjdk-8-jdk openjdk-11-jdk)
APT_PACKAGES+=(gnucash kde-spectacle)
INSTALL_PACKAGES=()
for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg -l "$package" >/dev/null 2>&1; then
        INSTALL_PACKAGES+=("$package")
    fi
done
if [ -n "${INSTALL_PACKAGES[*]}" ]; then
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
echo 'mattsday ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd
fi
sudo AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true
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

docker_setup() {
echo Setting up Docker
sudo glinux-add-repo -b docker-ce-"$(lsb_release -cs)" >/dev/null || fail Failed to add Docker repo
sudo apt-get update >/dev/null || fail Failed to update
sudo apt-get -y install docker-ce >/dev/null || fail Failed to install Docker
sudo service docker stop
sudo ip link set docker0 down
sudo ip link del docker0
sudo addgroup docker >/dev/null
sudo adduser "$USER" docker >/dev/null
if [ ! -f /etc/docker/daemon.json ]; then
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "/usr/local/google/docker",
  "bip": "192.168.9.1/24",
  "default-address-pools": [
    {
      "base": "192.168.10.0/24",
      "size": 24
    }
  ],
  "storage-driver": "overlay2",
  "debug": true,
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF
fi
sudo service docker start
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
docker_setup
emoji
}


main "$@"
