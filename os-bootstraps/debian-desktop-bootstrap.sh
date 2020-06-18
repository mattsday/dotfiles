#!/bin/bash
# Generic bootstrapping for any debian-derived desktop (e.g. Ubuntu, Neon, Rodete, ...)
#shellcheck disable=SC2154

fail() {
  echo >&2 '[Failure]' "$@"
  exit 1
}

warn() {
  echo >&2 '[Warning]' "$@"
}

info() {
  echo "$@"
}

get_apt_packages() {
  APT_PACKAGES+=(snapd kde-plasma-desktop plasma-widgets-addons plasma-wallpapers-addons plasma-nm)
  APT_PACKAGES+=(ffmpegthumbs ffmpegthumbnailer pulseaudio-module-bluetooth blueman kamoso)
  APT_PACKAGES+=(sddm-theme-debian-breeze kde-spectacle)
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
    sudo apt-get -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
  fi
}

install_snaps() {
  install_snap chromium
  install_snap code --classic
  install_snap intellij-idea-ultimate --classic
}

install_snap() {
  if ! snap info "${1}" | grep installed: >/dev/null 2>&1; then
    sudo snap install "${@}" >/dev/null || warn "Failed to install $1"
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
    emoji
    ferdi
    install_snaps
    fix_chromium_desktop_entry
    configure_fonts
  )
  get_apt_packages

  # If we're not being sourced
  if [ -z "$_debian_bootstrap_mattsday" ]; then
    install_apt_packages
    for callback in "${CALLBACKS[@]}"; do
      "$callback"
    done
  fi
}

main "$@"
