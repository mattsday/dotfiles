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
  APT_PACKAGES+=(golang)
}

syncthing() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/syncthing.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/syncthing.sh
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
    APT_PACKAGES_BACKUP=("${APT_PACKAGES[%]}")
    _apt update >/dev/null
    APT_PACKAGES=(apt-transport-https ca-certificates gnupg)
    install_apt_packages
    APT_PACKAGES=("${APT_PACKAGES_BACKUP[%]}")
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | _sudo tee /usr/share/keyrings/cloud.google.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | _sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
    _apt update >/dev/null
    APT_PACKAGES_BACKUP=("${APT_PACKAGES[%]}")
    APT_PACKAGES=(google-cloud-sdk google-cloud-sdk-anthos-auth google-cloud-sdk-gke-gcloud-auth-plugin google-cloud-cli)
    APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl)
    install_apt_packages
    APT_PACKAGES=("${APT_PACKAGES_BACKUP[%]}")
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
    _sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
    rm -f packages.microsoft.gpg
    _apt update >/dev/null
    APT_PACKAGES+=(code)

  fi
}

install_spotify() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  # Spotify changes its apt key from time to time; keep it up to date here
  KEY_URL=https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg
  KEY_NAME=/usr/share/keyrings/spotify-archive-keyring-5E3C45D7B312C643.gpg
  APT_SOURCE_FILE=/etc/apt/sources.list.d/spotify.list

  if [[ ! -f "${KEY_NAME}" ]]; then
    curl -fsSL "${KEY_URL}" | sudo gpg --dearmor -o "${KEY_NAME}"
    if [[ -f "${APT_SOURCE_FILE}" ]]; then
      sudo rm "${APT_SOURCE_FILE}"
    fi
    echo "deb [arch=amd64 signed-by=${KEY_NAME}] http://repository.spotify.com stable non-free" | sudo tee "${APT_SOURCE_FILE}" >/dev/null
    _apt update >/dev/null 2>&1 && _apt install -y spotify-client >/dev/null 2>&1
  fi
}

main() {
  CALLBACKS+=(
    install_vs_code
    install_gcp_sdk
    install_spotify
    install_kubectx
    setup_ssh_agent
    syncthing
    #install_brave
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
