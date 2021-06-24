#!/bin/bash
#shellcheck disable=SC1090

if [ -z "${DOTFILES_ROOT}" ]; then
  if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
    DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
  else
    DOTFILES_ROOT="${PWD}"
  fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

# Load Debian common functions (from common.sh)
load_debian_common

DEBIAN_DESKTOP_BOOTSTRAP=debian-desktop-bootstrap.sh

# Load generic desktop bootstraps
if [[ -f "${OS_BOOTSTRAP_ROOT}"/"${DEBIAN_DESKTOP_BOOTSTRAP}" ]]; then
  info Detected generic Debian-derived desktop
  . "${OS_BOOTSTRAP_ROOT}"/"${DEBIAN_DESKTOP_BOOTSTRAP}"
else
  info Could not find "${DEBIAN_DESKTOP_BOOTSTRAP}"
fi

get_apt_packages() {
  APT_PACKAGES+=(google-cloud-sdk google-cloud-sdk-anthos-auth flatpak)
  APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl openjdk-8-jdk openjdk-11-jdk)
  APT_PACKAGES+=(print-manager avahi-discover avahi-utils okular sddm-theme-debian-breeze)
}

passwordless_sudo() {
  if [[ ! -f /etc/sudoers.d/nopasswd-"${USER}" ]] && [[ "${NO_SUDO}" != 1 ]]; then
    info Setting up passwordless sudo
    echo "${USER}"' ALL=(ALL:ALL) NOPASSWD:ALL' | _sudo tee /etc/sudoers.d/nopasswd-"${USER}"
    _sudo AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true >/dev/null 2>&1
  fi
}

install_brave() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/brave.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/brave.sh
  else
    warn Could not find "${OS_BOOTSTRAP_ROOT}"/brave.sh
  fi
}

install_kubectx() {
  if ! command -v kubectx >/dev/null 2>&1 || ! command -v kubens >/dev/null 2>&1; then
    info Installing Kubectx
    if [[ -f "${OS_BOOTSTRAP_ROOT}"/kubectx.sh ]]; then
      "${OS_BOOTSTRAP_ROOT}"/kubectx.sh
    else
      fail Could not find kubectx.sh
    fi
  fi
}

install_spotify_flatpak() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! command -v flatpak >/dev/null 2>&1; then
    return
  fi
  # Install spotify flatpak
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  package=com.spotify.Client
  if ! flatpak info "${package}" >/dev/null 2>&1; then
    info "Installing Spotify (flatpak)"
    if ! sudo flatpak -y install "${package}" >/dev/null; then
      fail Flatpak installation failed for "${package}"
      return 1
    fi
  fi
  # Remove spotify-client debian package
  if dpkg-query -W -f='${Status}' spotify-client 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Removing spotify-client from apt
    sudo apt-get -y remove spotify-client >/dev/null 2>&1
  fi
}

install_vs_code() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! dpkg-query -W -f='${Status}' code 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    sudo glinux-add-repo -b typescript stable >/dev/null || error Failed to add Typescript repo
    _apt update >/dev/null 2>&1
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(code)
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
  fi
  if [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
    sudo rm /etc/apt/sources.list.d/vscode.list
  fi
}

install_sdk_man() {
  if [[ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
    info Installing sdkman
    curl -s "https://get.sdkman.io?rcupdate=false" | bash >/dev/null
    . "${HOME}/.sdkman/bin/sdkman-init.sh"
  fi
  if [[ -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
    . "${HOME}/.sdkman/bin/sdkman-init.sh"
    if ! command -v gradle >/dev/null 2>&1; then
      info Installing gradle
      sdk install gradle >/dev/null
    fi
    if ! command -v mvn >/dev/null 2>&1; then
      info Installing maven
      sdk install maven >/dev/null
    fi
  fi
}

docker_setup() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Setting up Docker
    sudo glinux-add-repo -b docker-ce-"$(lsb_release -cs)" >/dev/null || fail Failed to add Docker repo
    _apt update >/dev/null || fail Failed to update
    _apt -y install docker-ce >/dev/null || error Failed to install Docker
    sudo service docker stop
    sudo ip link set docker0 down
    sudo ip link del docker0
    if ! grep -q docker /etc/group >/dev/null 2>&1; then
      sudo addgroup docker >/dev/null
    fi
    sudo adduser "${USER}" docker >/dev/null
    if [[ ! -f /etc/docker/daemon.json ]]; then
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
    docker_setup
    install_vs_code
    install_sdk_man
    #fix_ferdi_chat
    install_kubectx
    install_brave
    install_spotify_flatpak
  )
  get_apt_packages

  # If we're not being sourced
  #shellcheck disable=SC2154
  if [[ -z "${_debian_bootstrap_mattsday}" ]]; then
    install_apt_packages
    for callback in "${CALLBACKS[@]}"; do
      "${callback}"
    done
  fi
}

main "$@"
