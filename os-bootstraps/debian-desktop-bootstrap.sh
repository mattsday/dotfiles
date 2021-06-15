#!/bin/bash
# Generic bootstrapping for any debian-derived desktop (e.g. Ubuntu, Neon, Rodete, ...)
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

get_apt_packages() {
  APT_PACKAGES+=(plasma-widgets-addons plasma-wallpapers-addons plasma-nm xdg-desktop-portal-kde)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer kamoso kdegraphics-thumbnailers ark skanlite)
  APT_PACKAGES+=(kde-spectacle vlc kdegames ksshaskpass flatpak unrar wbritish libappindicator3-1)
}

get_snap_packages() {
  # deprecated
  SNAP_PACKAGES+=(signal-desktop)
}

install_snap_packages() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if command -v snap >/dev/null 2>&1; then
    for snap in "${SNAP_PACKAGES[@]}"; do
      pkg_name="$(echo "${snap}" | cut -d ' ' -f 1)"
      if ! snap info "${pkg_name}" | grep installed: >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        _sudo snap install ${snap} >/dev/null || warn "Failed to install ${snap}"
      fi
    done
  fi
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

get_flatpak_packages() {
  #FLATPAK_PACKAGES+=(org.signal.Signal org.gtk.Gtk3theme.Breeze-Dark)
  FLATPAK_PACKAGES+=(org.gtk.Gtk3theme.Breeze-Dark)
}

install_flatpak_packages() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  if ! command -v flatpak >/dev/null 2>&1; then
    fail Flatpak not installed
  fi
  # Add flathub
  _sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  for package in "${FLATPAK_PACKAGES[@]}"; do
    if ! flatpak info "${package}" >/dev/null 2>&1; then
      info Installing Flatpak packages "${package}"
      if ! _sudo flatpak -y install "${package}" >/dev/null; then
        echo Flatpak installation failed for "${package}"
        return
      fi
    fi
  done
}

fix_signal_flatpak_desktop_entry() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  # if Snap is installed, remove the signal desktop snap and the desktop entry
  if command -v snap >/dev/null 2>&1; then
    if snap info signal-desktop | grep installed: >/dev/null 2>&1; then
      _sudo snap remove signal-desktop >/dev/null
    fi
  fi
  # Remove local file
  if [[ -f "${HOME}"/.local/share/applications/signal-desktop_signal-desktop.desktop ]]; then
    rm "${HOME}"/.local/share/applications/signal-desktop_signal-desktop.desktop
  fi

  FLATPAK_FILE=/var/lib/flatpak/exports/share/applications/org.signal.Signal.desktop
  LOCAL_FILE="${HOME}"/.local/share/applications/org.signal.Signal.desktop
  if [[ ! -d "${HOME}"/.local/share/applications ]]; then
    mkdir -p "${HOME}"/.local/share/applications
  fi
  # if we exist just return
  if [[ -f "${LOCAL_FILE}" ]]; then
    return
  fi
  if [[ ! -f "${FLATPAK_FILE}" ]]; then
    echo Warning "${FLATPAK_FILE}" does not exist
    return
  fi
  cp "${FLATPAK_FILE}" "${LOCAL_FILE}"
  sed -i 's|Exec=/usr/bin/flatpak|Exec=GTK_THEME="Breeze-Dark" /usr/bin/flatpak|g;' "${LOCAL_FILE}"
}

ssh_configuration() {
  SSH_FILE="${HOME}"/.config/autostart-scripts/ssh.sh
  if [[ ! -f "${SSH_FILE}" ]]; then
    mkdir -p "${HOME}"/.config/autostart-scripts/ || fail Cannot create ssh dir
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
    mkdir -p "${HOME}"/.config/plasma-workspace/env || fail Cannot create ssh dir
    info Setting up ssh agent autostart
    cat <<'EOF' | tee "${SSH_FILE}" >/dev/null
#!/bin/sh
[ -n "${SSH_AGENT_PID}" ]] || eval "$(ssh-agent -s)"
export SSH_ASKPASS=/usr/bin/ksshaskpass
EOF
    chmod +x "${SSH_FILE}"
  fi
}

# Deprecated
fix_signal_desktop_entry() {
  SNAP_FILE=/var/lib/snapd/desktop/applications/signal-desktop_signal-desktop.desktop
  LOCAL_FILE="${HOME}"/.local/share/applications/signal-desktop_signal-desktop.desktop
  if [[ ! -d "${HOME}"/.local/share/applications ]]; then
    mkdir -p "${HOME}"/.local/share/applications
  fi
  # if we exist just return
  if [[ -f "${LOCAL_FILE}" ]]; then
    return
  fi
  if [[ ! -f "${SNAP_FILE}" ]]; then
    warn "Signal desktop entry not found in ${SNAP_FILE}"
    return
  fi
  cp "${SNAP_FILE}" "${LOCAL_FILE}"
  sed -i 's/Exec=env/Exec=env GTK_THEME="Breeze-Dark"/g; s|Icon=.*|Icon=/snap/signal-desktop/current/usr/share/icons/hicolor/512x512/apps/signal-desktop.png|g' "${LOCAL_FILE}"
}

configure_fonts() {
  if [[ -f "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh ]]; then
    "${OS_BOOTSTRAP_ROOT}"/jetbrains-mono-font.sh
  fi
}

rambox() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  RAMBOX_VERSION=1.5.1
  if ! dpkg-query -W -f='${Status}' ramboxpro 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Installing Rambox Pro
    UPDATE_RAMBOX=true
  else
    CURRENT_RAMBOX_VERSION="$(apt-cache policy ramboxpro | grep Installed: | cut -d ':' -f 2 | xargs)"
    if [[ "${CURRENT_RAMBOX_VERSION}" != "${RAMBOX_VERSION}" ]]; then
      info "Updating Rambox Pro to ${RAMBOX_VERSION} (from ${CURRENT_RAMBOX_VERSION})"
      UPDATE_RAMBOX=true
    fi
  fi
  if [[ -n "${UPDATE_RAMBOX}" ]]; then
    # TODO - needs a lot of TLC
    RAMBOX_FILE=/tmp/RamboxPro-"${RAMBOX_VERSION}"-linux-x64.deb
    RAMBOX_URL=https://github.com/ramboxapp/download/releases/download/v"${RAMBOX_VERSION}"/RamboxPro-"${RAMBOX_VERSION}"-linux-x64.deb
    if ! wget -O "${RAMBOX_FILE}" "${RAMBOX_URL}"; then
      fail Could not download Rambox Pro
    fi
    _sudo dpkg -i "${RAMBOX_FILE}" || fail Could not install Ferdi
  fi
}

# Deprecated, use rambox now
ferdi() {
  # Don't run this if we can't run as root
  if [[ "${NO_SUDO}" = 1 ]]; then
    return
  fi
  FERDI_VERSION=5.6.0-beta.5
  FERDI_COMPARE_VERSION="${FERDI_VERSION}"-2741
  if ! dpkg-query -W -f='${Status}' ferdi 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Installing Ferdi
    UPDATE_FERDI=true
  else
    CURRENT_FERDI_VERSION="$(apt-cache policy ferdi | grep Installed: | cut -d ':' -f 2 | xargs)"
    if [[ "${CURRENT_FERDI_VERSION}" != "${FERDI_COMPARE_VERSION}" ]]; then
      info "Updating Ferdi to ${FERDI_VERSION} (from ${CURRENT_FERDI_VERSION})"
      UPDATE_FERDI=true
    fi
  fi
  if [[ -n "${UPDATE_FERDI}" ]]; then
    # TODO - needs a lot of TLC
    FERDI_URL=https://github.com/getferdi/ferdi/releases/download/v"${FERDI_VERSION}"/ferdi_"${FERDI_VERSION}"_amd64.deb
    if ! wget -O /tmp/ferdi-"${FERDI_VERSION}".deb "${FERDI_URL}"; then
      FERDI_URL=https://github.com/getferdi/ferdi/releases/download/"${FERDI_VERSION}"/ferdi_"${FERDI_VERSION}"_amd64.deb
      wget -O /tmp/ferdi-"${FERDI_VERSION}".deb "${FERDI_URL}" || fail Could not download Ferdi
    fi
    _sudo dpkg -i /tmp/ferdi-"${FERDI_VERSION}".deb || fail Could not install Ferdi
  fi
  if [[ -f "${OS_BOOTSTRAP_ROOT}/ferdi-anylist.sh" ]]; then
    "${OS_BOOTSTRAP_ROOT}/ferdi-anylist.sh"
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
    #ferdi
    #rambox
    install_flatpak_packages
    fix_signal_flatpak_desktop_entry
    configure_fonts
    ssh_configuration
    baloo_config
    pipewire
  )
  get_apt_packages
  get_flatpak_packages

  install_flatpak_packages
  # If we're not being sourced
  # shellcheck disable=SC2154
  if [[ -z "${_debian_bootstrap_mattsday}" ]]; then
    for callback in "${CALLBACKS[@]}"; do
      "${callback}"
    done
    install_apt_packages
    install_snap_packages
  fi
}

main "$@"
