#!/bin/bash
#shellcheck disable=SC2154
DEBIAN_DESKTOP_BOOTSTRAP=debian-desktop-bootstrap.sh

# Load generic desktop bootstraps
if [ -f ./os-bootstraps/"$DEBIAN_DESKTOP_BOOTSTRAP" ]; then
  echo Detected generic Debian-derived desktop
  . ./os-bootstraps/"$DEBIAN_DESKTOP_BOOTSTRAP"
elif [ -f "$DEBIAN_DESKTOP_BOOTSTRAP" ]; then
  . ./"$DEBIAN_DESKTOP_BOOTSTRAP"
else
  echo Could not find debian-desktop.sh
fi

fail() {
  echo >&2 '[Failure]' "$@"
  exit 1
}

warn() {
  echo >&2 '[Warning]' "$@"
}

info() {
  echo "$@"
}

get_apt_packages() {
  APT_PACKAGES+=(spotify-client google-cloud-sdk google-cloud-sdk-anthos-auth)
  APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl openjdk-8-jdk openjdk-11-jdk)
  APT_PACKAGES+=(gnucash print-manager avahi-discover avahi-utils)
}

install_apt_packages() {
  get_apt_packages
  INSTALL_PACKAGES=()
  for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
      INSTALL_PACKAGES+=("$package")
    fi
  done
  if [ -n "${INSTALL_PACKAGES[*]}" ]; then
    info Installing packages "${INSTALL_PACKAGES[@]}"
    sudo apt-get -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
  fi
}

passwordless_sudo() {
  if [ ! -f /etc/sudoers.d/nopasswd ]; then
    info Setting up passwordless sudo
    echo "$USER"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd
    sudo AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true >/dev/null 2>&1
  fi
}

bluetooth_setup() {
  if [ ! -f "$HOME/.config/pulse/default.pa" ]; then
    info Setting up bluetooth
    cat >"$HOME/.config/pulse/default.pa" <<EOF
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
  info Setting up Docker
  if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    sudo glinux-add-repo -b docker-ce-"$(lsb_release -cs)" >/dev/null || fail Failed to add Docker repo
    sudo apt-get update >/dev/null || fail Failed to update
    sudo apt-get -y install docker-ce >/dev/null || fail Failed to install Docker
    sudo service docker stop
    sudo ip link set docker0 down
    sudo ip link del docker0
    if ! grep -q docker /etc/group >/dev/null 2>&1; then
      sudo addgroup docker >/dev/null
    fi
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
    sudo service docker restart
  fi
}

main() {
  CALLBACKS+=(
    passwordless_sudo
    bluetooth_setup
    docker_setup
  )
  get_apt_packages

  # If we're not being sourced
  if [ -z "$_debian_bootstrap_mattsday" ]; then
    install_apt_packages
    for callback in "${CALLBACKS[@]}"; do
      "$callback"
    done
  fi
}

main "$@"