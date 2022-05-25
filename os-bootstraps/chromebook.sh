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

install_gcp_sdk() {
  # TODO
  APT_PACKAGES+=(google-cloud-sdk google-cloud-sdk-anthos-auth google-cloud-sdk-gke-gcloud-auth-plugin)
  APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl openjdk-8-jdk openjdk-11-jdk)
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
  info Installing GCP SDK
}

install_vs_code() {
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

main() {
  CALLBACKS+=(
    install_vs_code
    install_gcp_sdk
    install_kubectx
    setup_ssh_agent
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
