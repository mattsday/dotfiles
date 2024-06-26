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
  APT_PACKAGES+=(golang vlc vlc-plugin-qt maven)
}

syncthing() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/syncthing.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/syncthing.sh
  fi
}

configure_chromebook_git() {
  if [[ "$(git config --global --get 'credential.helper')" != "store" ]]; then
    info Configuring git credential store
    git config --global credential.helper store
  fi
}

configure_fonts() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh
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

setup_ssh_agent() {
  SSH_AGENT_ROOT="${HOME}/.config/systemd/user"
  if [[ ! -f ${SSH_AGENT_ROOT}/ssh-agent.service ]]; then
    info Setting up ssh agent
    if [[ ! -d "${SSH_AGENT_ROOT}" ]]; then
      mkdir -p "${SSH_AGENT_ROOT}" || error Cannot create ssh agent directory "${SSH_AGENT_ROOT}"
    fi
    cat <<'EOF' | tee "${SSH_AGENT_ROOT}/ssh-agent.service" >/dev/null
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a $SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user --now enable ssh-agent
  fi
}

install_gcp_sdk() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! command -v gcloud >/dev/null 2>&1; then
    info Setting up GCP SDK
    # Install apt pre-reqs
    _apt update >/dev/null
    instant_install_apt_packages apt-transport-https ca-certificates gnupg
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | _sudo tee /usr/share/keyrings/cloud.google.asc >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt cloud-sdk main" | _sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    _apt update >/dev/null
    instant_install_apt_packages google-cloud-sdk google-cloud-sdk-anthos-auth google-cloud-sdk-gke-gcloud-auth-plugin google-cloud-cli google-cloud-sdk-kpt \
      google-cloud-sdk-skaffold kubectl
  fi
}

install_vs_code() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! command -v code >/dev/null 2>&1; then
    info Setting up VS Code
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
    _sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | _sudo tee '/etc/apt/sources.list.d/vscode.list' >/dev/null
    rm -f packages.microsoft.gpg
    _apt update >/dev/null
    instant_install_apt_packages code

  fi
}

install_brave() {
  if [[ ! -f /etc/apt/sources.list.d/brave-browser-release.list ]]; then
    info Installing Brave
    _sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | _sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null
    _sudo apt update
    instant_install_apt_packages brave_browser
  fi
}

install_chrome() {
  if ! command -v google-chrome >/dev/null 2>&1; then
    info Installing Chrome for Linux
    curl -fsSLo /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
    _sudo dpkg -i /tmp/chrome.deb
    _sudo rm /tmp/chrome.deb
  fi
}

dark_theme_linux() {
  instant_install_apt_packages adwaita-qt gnome-themes-extra

  DEST_DIR="${HOME}/.config/systemd/user/sommelier-x@0.service.d"
  DEST_FILE="${DEST_DIR}/cros-sommelier-x-override.conf"
  SOURCE_FILE="${DOTFILES_ROOT}"/dotfiles/special/cros/cros-sommelier-x-override.conf

  if [[ ! -f "${SOURCE_FILE}" ]]; then
    error Cannot locate "${SOURCE_FILE}"
    return
  fi

  if [[ ! -d "${DEST_DIR}" ]]; then
    mkdir -p "${DEST_DIR}" || error "Cannot create directory ${DEST_DIR}"
  fi

  # Check if the file is already symlinked, if so we can exit
  if [[ ! -L "${DEST_FILE}" ]]; then
    info Setting dark mode for Linux Apps
    ln -s "${SOURCE_FILE}" "${DEST_FILE}"
    systemctl --user daemon-reload
    systemctl --user restart sommelier-x@0.service
  fi

  DEST_DIR="${HOME}/.config/gtk-3.0"
  DEST_FILE="${DEST_DIR}/settings.ini"
  SOURCE_FILE="${DOTFILES_ROOT}"/dotfiles/special/cros/settings.ini

  if [[ ! -f "${SOURCE_FILE}" ]]; then
    error Cannot locate "${SOURCE_FILE}"
    return
  fi

  if [[ ! -d "${DEST_DIR}" ]]; then
    mkdir -p "${DEST_DIR}" || error "Cannot create directory ${DEST_DIR}"
  fi

  # Check if the file is already symlinked, if so we can exit
  if [[ ! -L "${DEST_FILE}" ]]; then
    info Setting up dark GTK theme
    ln -s "${SOURCE_FILE}" "${DEST_FILE}"
  fi
}

main() {
  CALLBACKS+=(
    dark_theme_linux
    install_vs_code
    install_gcp_sdk
    install_kubectx
    setup_ssh_agent
    syncthing
    configure_fonts
    install_brave
    configure_chromebook_git
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
