#!/bin/bash
# Generic bootstrapping for any debian-derived desktop (e.g. Ubuntu, Neon, Rodete, ...)
#shellcheck disable=SC1090

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    elif command -v dirname >/dev/null 2>&1; then
        DOTFILES_ROOT="$(cd "$(dirname "$0")" || return; pwd)"
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
  APT_PACKAGES+=(plasma-widgets-addons plasma-wallpapers-addons plasma-nm xdg-desktop-portal-kde)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer kamoso kdegraphics-thumbnailers ark skanlite)
  APT_PACKAGES+=(kde-spectacle vlc kdegames ksshaskpass unrar wbritish libappindicator3-1)
}

# Install pipewire support on Linux
pipewire() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  info Setting up Pipewire
  # Back up current packages
  BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
  # Install build packages immediately
  APT_PACKAGES=(libldacbt-abr2 libldacbt-enc2 pipewire-bin pipewire-audio-client-libraries libpipewire-0.3-0 dbus-user-session libspa-0.2-bluetooth libspa-0.2-jack gstreamer1.0-pipewire)
  # Check they exist (they won't in older Debian or Ubuntu versions)
  for package in "${APT_PACKAGES[@]}"; do
    if ! apt-cache show "${package}" >/dev/null 2>&1; then
      fail "Pipewire not supported on this OS ${package} not found"
      APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
      return 1
    fi
  done
  install_apt_packages
  APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")

  if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service ]]; then
    # Enable pulseaudio via pipwire
    if [[ ! -f /etc/pipewire/media-session.d/with-pulseaudio ]]; then
      _sudo touch /etc/pipewire/media-session.d/with-pulseaudio
    fi
    if [[ ! -f /etc/pipewire/media-session.d/with-alsa ]]; then
      _sudo touch /etc/pipewire/media-session.d/with-alsa
    fi
    if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service ]]; then
      _sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service /etc/systemd/user/ || warn Failed to copy pipewire-pulse service
    fi
    if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.socket ]]; then
      _sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.socket /etc/systemd/user/ || warn Failed to copy pipewire-pulse socket
    fi
    if [[ -f /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf ]]; then
      _sudo cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/ || warn Failed to copy alsa config
    fi
    # Use Pipewire for JACK
    if [[ ! -f /etc/pipewire/media-session.d/with-jack ]]; then
      _sudo touch /etc/pipewire/media-session.d/with-jack
    fi
    if [[ -f /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-x86_64-linux-gnu.conf ]]; then
      _sudo cp /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-x86_64-linux-gnu.conf /etc/ld.so.conf.d/
      _sudo ldconfig
    fi
    if ! systemctl -q is-active --user pipewire || ! systemctl -q is-active --user pipewire-pulse; then
      info Starting pipewire user service
      systemctl --user daemon-reload
      systemctl --user --now disable pulseaudio.service pulseaudio.socket
      systemctl --user mask pulseaudio
      systemctl --user --now enable pipewire pipewire-pulse
    fi
  fi

  # Protect against future pipewire-media-session.service changes
  if [[ "$(systemctl list-unit-files pipewire-media-session.service | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user pipewire-media-session.service; then
    systemctl --user --now enable pipewire-media-session.service
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

main() {
  CALLBACKS+=(
    emoji
    configure_fonts
    ssh_configuration
    baloo_config
    pipewire
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
