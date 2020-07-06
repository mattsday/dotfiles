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
  APT_PACKAGES+=(snapd kde-plasma-desktop plasma-widgets-addons plasma-wallpapers-addons plasma-nm)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer pulseaudio-module-bluetooth blueman kamoso)
  APT_PACKAGES+=(kde-spectacle vlc kdegames ksshaskpass flatpak unrar)
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
    _apt -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
  fi
}

get_snap_packages() {
  SNAP_PACKAGES+=(chromium)
}

install_snap_packages() {
  if command -v snap >/dev/null 2>&1; then
    for snap in "${SNAP_PACKAGES[@]}"; do
      pkg_name="$(echo "$snap" | awk '{print $1}')"
      if ! snap info "${pkg_name}" | grep installed: >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        sudo snap install ${snap} >/dev/null || warn "Failed to install ${snap}"
      fi
    done
  fi
}

install_gnucash() {
  if ! command -v flatpak >/dev/null 2>&1; then
    return
  fi

  info Installing GnuCash
  if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    _apt -y remove gnucash >/dev/null
  fi
  if [ -f "$HOME/.local/share/applications/gnucash.desktop" ]; then
    rm "$HOME/.local/share/applications/gnucash.desktop"
  fi
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  sudo flatpak install --noninteractive --or-update flathub org.gnucash.GnuCash org.gtk.Gtk3theme.Adwaita-dark \
    org.gtk.Gtk3theme.Breeze-Dark org.gtk.Gtk3theme.Breeze >/dev/null

  # Create local icon entry
  FLATPAK_FILE=/var/lib/flatpak/exports/share/applications/org.gnucash.GnuCash.desktop
  LOCAL_FILE="$HOME"/.local/share/applications/org.gnucash.GnuCash.desktop
  # if we exist just return
  if [ -f "$LOCAL_FILE" ]; then
    return
  fi
  if [ ! -f "$FLATPAK_FILE" ]; then
    warn "GnuCash desktop entry not found in $FLATPAK_FILE"
    return
  fi
  cp "$FLATPAK_FILE" "$LOCAL_FILE"
  # Set theme to Adwaita-dark due to GnuCash theme bug and explicitly set icon location
  sed -i 's|Exec=/usr/bin/flatpak|Exec=env GTK_THEME="Adwaita-dark" /usr/bin/flatpak|g; s|Icon=.*|Icon=/var/lib/flatpak/exports/share/icons/hicolor/scalable/apps/org.gnucash.GnuCash.svg|g' "$LOCAL_FILE"
}

configure_logitech_mouse() {
  if lsusb | grep 'Logitech, Inc. Unifying Receiver' >/dev/null 2>&1; then
    if [ -f "$HOME/.logitech-installed-mattsday" ]; then
      info Logitech mouse already configured - delete "$HOME/.logitech-installed-mattsday" to force
      return
    fi
    info Setting up Logitech Mouse Configuration
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(cmake libevdev-dev libudev-dev libconfig++-dev solaar)
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
    if [ ! -d /tmp/logiops ]; then
      git clone https://github.com/PixlOne/logiops /tmp/logiops >/dev/null || fail Failed to download Logitech options
    else
      cd /tmp/logiops || fail Failed to change to /tmp/logiops
      git pull >/dev/null || fail Failed to pull latest version
    fi
    cd /tmp/logiops || fail Failed to change to /tmp/logiops
    if [ ! -d release ]; then
      mkdir release || fail Fail to create release directory
    fi
    cd release || fail Failed to change to release directory
    cmake .. >/dev/null || fail Failed to configure project
    make >/dev/null || fail Failed to build project
    sudo make install >/dev/null || fail Failed to install project
    if [ ! -f /usr/lib/libhidpp.so ]; then
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
});
EOF
    sudo systemctl enable --now logid
    info Success
    touch "$HOME/.logitech-installed-mattsday"
  fi
}

ssh_configuration() {
  SSH_FILE="$HOME"/.config/autostart-scripts/ssh.sh
  if [ ! -f "$SSH_FILE" ]; then
    mkdir -p "$HOME"/.config/autostart-scripts/ || fail Cannot create ssh dir
    info Setting up ssh with ksshaskpass
    cat <<EOF | tee "$SSH_FILE" >/dev/null
#!/bin/bash
SSH_ASKPASS=/usr/bin/ksshaskpass ssh-add "$HOME/.ssh/id_rsa" </dev/null
}
EOF
    chmod +x "$SSH_FILE"
  fi
}

fix_chromium_desktop_entry() {
  SNAP_FILE=/var/lib/snapd/desktop/applications/chromium_chromium.desktop
  LOCAL_FILE="$HOME"/.local/share/applications/chromium_chromium.desktop
  # if we exist just return
  if [ -f "$LOCAL_FILE" ]; then
    return
  fi
  if [ ! -f "$SNAP_FILE" ]; then
    warn "Chromium desktop entry not found in $SNAP_FILE"
    return
  fi
  cp "$SNAP_FILE" "$LOCAL_FILE"
  sed -i 's/Exec=env/Exec=env GTK_THEME="Breeze-Dark"/g; s|Icon=.*|Icon=/snap/chromium/current/chromium.png|g' "$LOCAL_FILE"
}

configure_fonts() {
  if [ -f jetbrains-mono-font.sh ]; then
    ./jetbrains-mono-font.sh
  elif [ -f ./os-bootstraps/jetbrains-mono-font.sh ]; then
    ./os-bootstraps/jetbrains-mono-font.sh
  fi
}

ferdi() {
  if ! dpkg-query -W -f='${Status}' ferdi 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    info Installing Ferdi
    # TODO - needs a lot of TLC
    FERDI_VERSION=5.5.0
    FERDI_URL=https://github.com/getferdi/ferdi/releases/download/v"$FERDI_VERSION"/ferdi_"$FERDI_VERSION"_amd64.deb

    wget -O /tmp/ferdi-"$FERDI_VERSION".deb "$FERDI_URL" || exit 1

    sudo dpkg -i /tmp/ferdi-"$FERDI_VERSION".deb || exit 1
  fi
  if [ -f "$PWD/ferdi-shopping-list.sh" ]; then
    "$PWD/ferdi-shopping-list.sh"
  elif [ -f "$PWD/os-bootstraps/ferdi-shopping-list.sh" ]; then
    "$PWD/os-bootstraps/ferdi-shopping-list.sh"
  fi
}

emoji() {
  if [ -f "$PWD/linux-emoji.sh" ]; then
    "$PWD/linux-emoji.sh"
  elif [ -f "$PWD/os-bootstraps/linux-emoji.sh" ]; then
    "$PWD/os-bootstraps/linux-emoji.sh"
  fi
}

main() {
  CALLBACKS+=(
    configure_logitech_mouse
    emoji
    ferdi
    fix_chromium_desktop_entry
    configure_fonts
    ssh_configuration
    install_gnucash
  )
  get_apt_packages
  get_snap_packages

  # If we're not being sourced
  # shellcheck disable=SC2154
  if [ -z "$_debian_bootstrap_mattsday" ]; then
    install_apt_packages
    install_snap_packages
    for callback in "${CALLBACKS[@]}"; do
      "$callback"
    done
  fi
}

main "$@"
