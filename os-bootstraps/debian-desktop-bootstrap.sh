#!/bin/bash
# Generic bootstrapping for any debian-derived desktop (e.g. Ubuntu, Neon, Rodete, ...)
#shellcheck disable=SC1090

fail() {
  echo >&2 '[Failure]' "$@"
  return 1
}

warn() {
  echo >&2 '[Warning]' "$@"
}

info() {
  echo "$@"
}

# Ensure apt runs in non-interactive mode
_apt() {
  DEBIAN_FRONTEND="noninteractive" sudo apt-get "$@"
}

get_apt_packages() {
  APT_PACKAGES+=(plasma-widgets-addons plasma-wallpapers-addons plasma-nm xdg-desktop-portal-kde)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer blueman kamoso kdegraphics-thumbnailers)
  APT_PACKAGES+=(kde-spectacle vlc kdegames ksshaskpass flatpak unrar wbritish libappindicator3-1)
}

install_apt_packages() {
  get_apt_packages
  INSTALL_PACKAGES=()
  for package in "${APT_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
      INSTALL_PACKAGES+=("${package}")
    fi
  done
  if [[ -n "${INSTALL_PACKAGES[*]}" ]]; then
    info Installing packages "${INSTALL_PACKAGES[@]}"
    _apt -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
  fi
}

get_snap_packages() {
  # deprecated
  SNAP_PACKAGES+=(signal-desktop)
}

install_snap_packages() {
  if command -v snap >/dev/null 2>&1; then
    for snap in "${SNAP_PACKAGES[@]}"; do
      pkg_name="$(echo "${snap}" | cut -d ' ' -f 1)"
      if ! snap info "${pkg_name}" | grep installed: >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        sudo snap install ${snap} >/dev/null || warn "Failed to install ${snap}"
      fi
    done
  fi
}

# Install pipewire support on Linux
pipewire() {
  info Setting up Pipewire
  # Back up current packages
  BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
  # Install build packages immediately
  APT_PACKAGES=(libldacbt-abr2 libldacbt-enc2 pipewire-bin pipewire-audio-client-libraries libpipewire-0.3-0 dbus-user-session libspa-0.2-bluetooth libspa-0.2-jack gstreamer1.0-pipewire)
  install_apt_packages
  APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")

  if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service ]]; then
    info Starting pipewire user service
    # Enable pulseaudio via pipwire
    if [[ ! -f /etc/pipewire/media-session.d/with-pulseaudio ]]; then
      sudo touch /etc/pipewire/media-session.d/with-pulseaudio
    fi
    if [[ ! -f /etc/pipewire/media-session.d/with-alsa ]]; then
      sudo touch /etc/pipewire/media-session.d/with-alsa
    fi
    if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service ]]; then
      sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.service /etc/systemd/user/ || warn Failed to copy pipewire-pulse service
    fi
    if [[ -f /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.socket ]]; then
      sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.socket /etc/systemd/user/ || warn Failed to copy pipewire-pulse socket
    fi
    if [[ -f /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf ]]; then
      sudo cp /usr/share/doc/pipewire/examples/alsa.conf.d/99-pipewire-default.conf /etc/alsa/conf.d/ || warn Failed to copy alsa config
    fi
    # Use Pipewire for JACK
    if [[ ! -f /etc/pipewire/media-session.d/with-jack ]]; then
      sudo touch /etc/pipewire/media-session.d/with-jack
    fi
    if [[ -f /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-x86_64-linux-gnu.conf ]]; then
      sudo cp /usr/share/doc/pipewire/examples/ld.so.conf.d/pipewire-jack-x86_64-linux-gnu.conf /etc/ld.so.conf.d/
      sudo ldconfig
    fi
    if ! systemctl -q is-active --user pipewire || ! systemctl -q is-active --user pipewire-pulse; then
      systemctl --user daemon-reload
      systemctl --user --now disable pulseaudio.service pulseaudio.socket
      systemctl --user mask pulseaudio
      systemctl --user --now enable pipewire pipewire-pulse
    fi
    # Protect against future pipewire-media-session.service changes
    if [[ "$(systemctl list-unit-files pipewire-media-session.service | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user pipewire-media-session.service; then
      systemctl --user --now enable pipewire-media-session.service
    fi
  fi
  # Rename devices
  if [[ ! -f /etc/pipewire/media-session.d/alsa-monitor.conf ]] || ! grep Jabra /etc/pipewire/media-session.d/alsa-monitor.conf >/dev/null; then
    CONF_FILE=dotfiles/special/alsa-monitor.conf
    if [[ ! -f "${CONF_FILE}" ]]; then
      ORIG_CONF_FILE="${CONF_FILE}"
      CONF_FILE=../dotfiles/special/alsa-monitor.conf
      if [[ ! -f "${CONF_FILE}" ]]; then
        fail Cannot find Alsa Monitor config file in "${CONF_FILE}" or "${ORIG_CONF_FILE}"
      fi
    fi
    sudo cp "${CONF_FILE}" /etc/pipewire/media-session.d/alsa-monitor.conf
    sudo chmod 644 /etc/pipewire/media-session.d/alsa-monitor.conf
    sudo chown root:root /etc/pipewire/media-session.d/alsa-monitor.conf
  fi
}

get_flatpak_packages() {
  FLATPAK_PACKAGES+=(org.signal.Signal org.gtk.Gtk3theme.Breeze-Dark)
}

install_flatpak_packages() {
  if ! command -v flatpak >/dev/null 2>&1; then
    fail Flatpak not installed
  fi
  # Add flathub
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  for package in "${FLATPAK_PACKAGES[@]}"; do
    if ! flatpak info "${package}" >/dev/null 2>&1; then
      info Installing Flatpak packages "${package}"
      if ! sudo flatpak -y install "${package}" >/dev/null; then
        echo Flatpak installation failed for "${package}"
        return
      fi
    fi
  done
}

fix_signal_flatpak_desktop_entry() {
  # if Snap is installed, remove the signal desktop snap and the desktop entry
  if command -v snap >/dev/null 2>&1; then
    if snap info signal-desktop | grep installed: >/dev/null 2>&1; then
      sudo snap remove signal-desktop >/dev/null
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

# Deprecated
install_gnucash() {
  if ! command -v flatpak >/dev/null 2>&1; then
    return
  fi

  info Installing GnuCash
  if dpkg-query -W -f='${Status}' "${package}" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    _apt -y remove gnucash >/dev/null
  fi
  if [[ ! -d "${HOME}"/.local/share/applications ]]; then
    mkdir -p "${HOME}"/.local/share/applications
  fi
  if [[ -f "${HOME/.local/share/applications/gnucash.desktop}" ]]; then
    rm "${HOME/.local/share/applications/gnucash.desktop}"
  fi
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  sudo flatpak install --noninteractive --or-update flathub org.gnucash.GnuCash org.gtk.Gtk3theme.Adwaita-dark \
    org.gtk.Gtk3theme.Breeze-Dark org.gtk.Gtk3theme.Breeze >/dev/null

  # Create local icon entry
  FLATPAK_FILE=/var/lib/flatpak/exports/share/applications/org.gnucash.GnuCash.desktop
  LOCAL_FILE="${HOME}"/.local/share/applications/org.gnucash.GnuCash.desktop
  # if we exist just return
  if [[ -f "${LOCAL_FILE}" ]]; then
    return
  fi
  if [[ ! -f "${FLATPAK_FILE}" ]]; then
    warn "GnuCash desktop entry not found in ${FLATPAK_FILE}"
    return
  fi
  cp "${FLATPAK_FILE}" "${LOCAL_FILE}"
  # Set theme to Adwaita-dark due to GnuCash theme bug and explicitly set icon location
  sed -i 's|Exec=/usr/bin/flatpak|Exec=env GTK_THEME="Adwaita-dark" /usr/bin/flatpak|g; s|Icon=.*|Icon=/var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/org.gnucash.GnuCash.svg|g' "${LOCAL_FILE}"
}

# Deprecated
configure_logitech_mouse() {
  if lsusb | grep 'Logitech, Inc. Unifying Receiver' >/dev/null 2>&1; then
    if [[ -f "${HOME/.logitech-installed-mattsday}" ]]; then
      info Logitech mouse already configured - delete "${HOME/.logitech-installed-mattsday}" to force
      return
    fi
    info Setting up Logitech Mouse Configuration
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(cmake libevdev-dev libudev-dev libconfig++-dev solaar build-essential)
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
    if [[ ! -d /tmp/logiops ]]; then
      git clone https://github.com/PixlOne/logiops /tmp/logiops >/dev/null || fail Failed to download Logitech options
    else
      cd /tmp/logiops || fail Failed to change to /tmp/logiops
      git pull >/dev/null || fail Failed to pull latest version
    fi
    cd /tmp/logiops || fail Failed to change to /tmp/logiops
    if [[ ! -d release ]]; then
      mkdir release || fail Fail to create release directory
    fi
    cd release || fail Failed to change to release directory
    cmake .. >/dev/null || fail Failed to configure project
    make >/dev/null || fail Failed to build project
    sudo make install >/dev/null || fail Failed to install project
    if [[ ! -f /usr/lib/libhidpp.so ]]; then
      sudo ln -s /usr/local/lib/libhidpp.so /usr/lib/libhidpp.so
    fi
    # Write config file
    cat <<EOF | sudo tee /etc/logid.cfg >/dev/null
devices: ({
  name: "MX Master";
  buttons: (
    // Make thumb button send ctrl-F8 (show desktop grid)
    { cid: 0xc3; action = { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_F8"]; }; }
  );
},{
  name: "Wireless Mouse MX Master";
  buttons: (
    // Make thumb button send ctrl-F8 (show desktop grid)
    { cid: 0xc3; action = { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_F8"]; }; }
  );
});
EOF
    sudo systemctl enable --now logid
    info Success
    touch "${HOME/.logitech-installed-mattsday}"
  fi
}

bluetooth_codecs() {
  # Only do this on Ubuntu
  RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
  if [[ "${RELEASE}" = neon ]] || [[ "${RELEASE}" = ubuntu ]]; then
    sudo add-apt-repository -y ppa:berglh/pulseaudio-a2dp >/dev/null
    APT_PACKAGES+=(pulseaudio-modules-bt libldac)
  else
    APT_PACKAGES+=(pulseaudio-module-bluetooth)
  fi
}

ssh_configuration() {
  SSH_FILE="${HOME}"/.config/autostart-scripts/ssh.sh
  if [[ ! -f "${SSH_FILE}" ]]; then
    mkdir -p "${HOME}"/.config/autostart-scripts/ || fail Cannot create ssh dir
    info Setting up ssh with ksshaskpass
    cat <<'EOF' | tee "${SSH_FILE}" >/dev/null
#!/bin/bash
sleep 5
SSH_ASKPASS=/usr/bin/ksshaskpass ssh-add "${HOME/.ssh/id_rsa}" </dev/null
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
fix_chromium_desktop_entry() {
  SNAP_FILE=/var/lib/snapd/desktop/applications/chromium_chromium.desktop
  LOCAL_FILE="${HOME}"/.local/share/applications/chromium_chromium.desktop
  if [[ ! -d "${HOME}"/.local/share/applications ]]; then
    mkdir -p "${HOME}"/.local/share/applications
  fi
  # if we exist just return
  if [[ -f "${LOCAL_FILE}" ]]; then
    return
  fi
  if [[ ! -f "${SNAP_FILE}" ]]; then
    warn "Chromium desktop entry not found in ${SNAP_FILE}"
    return
  fi
  cp "${SNAP_FILE}" "${LOCAL_FILE}"
  sed -i 's/Exec=env/Exec=env GTK_THEME="Breeze-Dark"/g; s|Icon=.*|Icon=/snap/chromium/current/chromium.png|g' "${LOCAL_FILE}"
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
  if [[ -f jetbrains-mono-font.sh ]]; then
    ./jetbrains-mono-font.sh
  elif [[ -f ./os-bootstraps/jetbrains-mono-font.sh ]]; then
    ./os-bootstraps/jetbrains-mono-font.sh
  fi
}

rambox() {
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
    sudo dpkg -i "${RAMBOX_FILE}" || fail Could not install Ferdi
  fi
}

# Deprecated, use rambox now
ferdi() {
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
    sudo dpkg -i /tmp/ferdi-"${FERDI_VERSION}".deb || fail Could not install Ferdi
  fi
  if [[ -f "${PWD/ferdi-anylist.sh}" ]]; then
    "${PWD/ferdi-anylist.sh}"
  elif [[ -f "${PWD/os-bootstraps/ferdi-anylist.sh}" ]]; then
    "${PWD/os-bootstraps/ferdi-anylist.sh}"
  fi
}

baloo_config() {
  if [[ -f "${PWD/kde-desktop.sh}" ]]; then
    "${PWD/kde-desktop.sh}"
  elif [[ -f "${PWD/os-bootstraps/kde-desktop.sh}" ]]; then
    "${PWD/os-bootstraps/kde-desktop.sh}"
  fi
}

emoji() {
  if [[ -f "${PWD/linux-emoji.sh}" ]]; then
    "${PWD/linux-emoji.sh}"
  elif [[ -f "${PWD/os-bootstraps/linux-emoji.sh}" ]]; then
    "${PWD/os-bootstraps/linux-emoji.sh}"
  fi
}

main() {
  CALLBACKS+=(
    #configure_logitech_mouse
    emoji
    #ferdi
    #rambox
    #fix_chromium_desktop_entry
    install_flatpak_packages
    #fix_signal_desktop_entry
    fix_signal_flatpak_desktop_entry
    configure_fonts
    ssh_configuration
    #install_gnucash
    #bluetooth_codecs
    baloo_config
    pipewire
  )
  get_apt_packages
  #get_snap_packages
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
