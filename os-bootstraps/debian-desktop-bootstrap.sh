#!/bin/bash
# Generic bootstrapping for any debian-derived desktop (e.g. Ubuntu, Neon, Rodete, ...)
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
  APT_PACKAGES+=(plasma-widgets-addons plasma-wallpapers-addons plasma-nm xdg-desktop-portal-kde xdg-desktop-portal-gtk)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer kamoso kdegraphics-thumbnailers ark skanlite dialog)
  APT_PACKAGES+=(kde-spectacle vlc kdegames ksshaskpass unrar wbritish libappindicator3-1 kdialog)
  APT_PACKAGES+=(konsole dolphin dolphin-plugins kate gwenview baloo-kf5 libnss-mdns)
  APT_PACKAGES+=(plasma-workspace-wayland kate)
}

# Install pipewire support on Linux
pipewire() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/pipewire.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/pipewire.sh
  fi
}

syncthing() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/syncthing.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/syncthing.sh
  fi
}

ssh_configuration() {
  SSH_FILE="${HOME}"/.config/autostart-scripts/ssh.sh
  if [[ ! -f "${SSH_FILE}" ]]; then
    mkdir -p "${HOME}"/.config/autostart-scripts/ || error Cannot create ssh dir
    info Setting up ssh with ksshaskpass
    cat <<'EOF' | tee "${SSH_FILE}" >/dev/null
#!/bin/bash
sleep 5
SSH_ASKPASS=/usr/bin/ksshaskpass ssh-add "${HOME}/.ssh/id_rsa" </dev/null
EOF
    chmod +x "${SSH_FILE}"
  fi

  SSH_FILE="${HOME}"/.config/plasma-workspace/env/ssh-agent-startup.sh
  if [[ ! -f "${SSH_FILE}" ]]; then
    mkdir -p "${HOME}"/.config/plasma-workspace/env || error Cannot create ssh dir
    info Setting up ssh agent autostart
    cat <<'EOF' | tee "${SSH_FILE}" >/dev/null
#!/bin/sh
[ -n "${SSH_AGENT_PID}" ]] || eval "$(ssh-agent -s)"
export SSH_ASKPASS=/usr/bin/ksshaskpass
EOF
    chmod +x "${SSH_FILE}"
  fi
}

configure_fonts() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh
  fi
}

baloo_config() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}/kde-desktop.sh" ]]; then
    "${OS_BOOTSTRAP_ROOT}/kde-desktop.sh"
  fi
}

emoji() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}/linux-emoji.sh" ]]; then
    "${OS_BOOTSTRAP_ROOT}/linux-emoji.sh"
  fi
}

zsh() {
  if [[ -x /bin/zsh ]] && [[ -f "${OS_BOOTSTRAP_ROOT}/zsh.sh" ]]; then
    "${OS_BOOTSTRAP_ROOT}/zsh.sh"
  fi
}

main() {
  CALLBACKS+=(
    emoji
    configure_fonts
    ssh_configuration
    baloo_config
    pipewire
    syncthing
    zsh
  )
  get_apt_packages

  # If we're not being sourced
  # shellcheck disable=SC2154
  if [[ -z "${_debian_bootstrap_mattsday}" ]]; then
    for callback in "${CALLBACKS[@]}"; do
      "${callback}"
    done
    install_apt_packages
  fi
}

main "$@"
