#!/bin/bash
#shellcheck disable=SC1090

if [[ -z "${DOTFILES_ROOT}" ]]; then
  if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
    DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
  elif command -v dirname >/dev/null 2>&1; then
    DOTFILES_ROOT="$(
      cd "$(dirname "$0")" || return
      pwd
    )"
  else
    echo >&2 '[Error] cannot determine root (try running from working directory)'
    exit 1
  fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

# Load Debian common functions (from common.sh)
load_debian_common

get_apt_packages() {
  # APT_PACKAGES+=(libreoffice-qt5 okular sddm-theme-debian-breeze lightdm)
  APT_PACKAGES+=(google-cloud-sdk google-cloud-sdk-anthos-auth google-cloud-sdk-gke-gcloud-auth-plugin)
  APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl)
  APT_PACKAGES+=(golang openjdk-25-jdk npm code)
}

passwordless_sudo() {
  # Only enable as a non-root user
  if command -v id >/dev/null 2>&1; then
    if [[ "$(id -u)" = 0 ]]; then
      return
    fi
  else
    warn Cannot determine if user is root
    return
  fi
  if [[ ! -f /etc/sudoers.d/nopasswd-"${USER}" ]] && [[ "${NO_SUDO}" != 1 ]]; then
    info Setting up passwordless sudo
    echo "${USER}"' ALL=(ALL:ALL) NOPASSWD:ALL' | _sudo tee /etc/sudoers.d/nopasswd-"${USER}"
    _sudo AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true >/dev/null 2>&1
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

docker_setup() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Setting up Docker
    _apt update >/dev/null || warn Failed to update repo
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
    install_kubectx
    docker_setup
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
