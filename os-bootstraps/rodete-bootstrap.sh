#!/bin/bash
#shellcheck disable=SC1090

DEBIAN_DESKTOP_BOOTSTRAP=debian-desktop-bootstrap.sh

# Load generic desktop bootstraps
if [[ -f ./os-bootstraps/"${DEBIAN_DESKTOP_BOOTSTRAP}" ]]; then
  echo Detected generic Debian-derived desktop
  . ./os-bootstraps/"${DEBIAN_DESKTOP_BOOTSTRAP}"
elif [[ -f "${DEBIAN_DESKTOP_BOOTSTRAP}" ]]; then
  . ./"${DEBIAN_DESKTOP_BOOTSTRAP}"
else
  echo Could not find debian-desktop.sh
fi

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

# Ensure apt runs in non-interactive mode
_apt() {
  DEBIAN_FRONTEND="noninteractive" sudo apt-get "$@"
}

get_apt_packages() {
  APT_PACKAGES+=(google-cloud-sdk google-cloud-sdk-anthos-auth flatpak)
  APT_PACKAGES+=(google-cloud-sdk-kpt google-cloud-sdk-skaffold kubectl openjdk-8-jdk openjdk-11-jdk)
  APT_PACKAGES+=(print-manager avahi-discover avahi-utils okular sddm-theme-debian-breeze)
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

passwordless_sudo() {
  if [[ ! -f /etc/sudoers.d/nopasswd ]]; then
    info Setting up passwordless sudo
    echo "${USER}"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd
    sudo AUTOMATIC_UPDATE=yes glinux-config set custom_etc_sudoers_d true >/dev/null 2>&1
  fi
}

install_kubectx() {
  if ! command -v kubectx >/dev/null 2>&1 || ! command -v kubens >/dev/null 2>&1; then
    echo Installing Kubectx
    if [[ -f ./os-bootstraps/kubectx.sh ]]; then
      ./os-bootstraps/kubectx.sh
    elif [[ -f "./kubectx.sh" ]]; then
      ./kubectx.sh
    else
      echo Could not find kubectx.sh
    fi
  fi
}

install_spotify_flatpak() {
  # Install spotify flatpak
  echo "Installing Spotify (flatpak)"
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  package=com.spotify.Client
  if ! flatpak info "${package}" >/dev/null 2>&1 && ! sudo flatpak -y install "${package}" >/dev/null; then
    echo Flatpak installation failed for "${package}"
    return
  fi
  # Remove spotify-client debian package
  if dpkg-query -W -f='${Status}' spotify-client 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    echo Removing spotify-client from apt
    sudo apt-get -y remove spotify-client >/dev/null 2>&1
  fi
}

install_chromium_flatpak() {
  # if Snap is installed, remove the Chromium snap and the desktop entry
  if command -v snap >/dev/null 2>&1; then
    if snap info chromium | grep installed: >/dev/null 2>&1; then
      sudo snap remove chromium >/dev/null
    fi
  fi
  # Remove local file
  if [[ -f "${HOME}"/.local/share/applications/chromium_chromium.desktop ]]; then
    rm "${HOME}"/.local/share/applications/chromium_chromium.desktop
  fi

  echo "Installing Chromium (flatpak)"
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
  FLATPAK_PACKAGES+=(org.chromium.Chromium org.gtk.Gtk3theme.Breeze-Dark)
  for package in "${FLATPAK_PACKAGES[@]}"; do
    if ! flatpak info "${package}" >/dev/null 2>&1 && ! sudo flatpak -y install "${package}" >/dev/null; then
      echo Flatpak installation failed for "${package}"
      return
    fi
  done

  FLATPAK_FILE=/var/lib/flatpak/exports/share/applications/org.chromium.Chromium.desktop
  LOCAL_FILE="${HOME}"/.local/share/applications/org.chromium.Chromium.desktop
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

install_vs_code() {
  if ! dpkg-query -W -f='${Status}' code 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    sudo glinux-add-repo -b typescript stable >/dev/null || fail Failed to add Typescript repo
    _apt update >/dev/null 2>&1
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(code)
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
  fi
  if [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
    sudo rm /etc/apt/sources.list.d/vscode.list
  fi
}

install_sdk_man() {
  if [[ ! -f "${HOME/.sdkman/bin/sdkman-init.sh}" ]]; then
    info Installing sdkman
    curl -s "https://get.sdkman.io?rcupdate=false" | bash >/dev/null
    . "${HOME/.sdkman/bin/sdkman-init.sh}"
  fi
  if [[ -f "${HOME/.sdkman/bin/sdkman-init.sh}" ]]; then
    . "${HOME/.sdkman/bin/sdkman-init.sh}"
    if ! command -v gradle >/dev/null 2>&1; then
      info Installing gradle
      sdk install gradle >/dev/null
    fi
    if ! command -v mvn >/dev/null 2>&1; then
      info Installing maven
      sdk install maven >/dev/null
    fi
  fi
}

bluetooth_setup() {
  if [[ ! -f "${HOME/.config/pulse/default.pa}" ]]; then
    info Setting up bluetooth
    cat >"${HOME/.config/pulse/default.pa}" <<EOF
.include /etc/pulse/default.pa

# Switch all audio playback to Bluetooth headphones when they are connected
.ifexists module-switch-on-connect.so
  load-module module-switch-on-connect
.endif

# Enable automatic switching between A2DP and HSP/HFP
.ifexists module-bluetooth-policy.so
  unload-module module-bluetooth-policy
  load-module module-bluetooth-policy auto_switch=2
.endif

# Fix bluetooth headphones bug
.ifexists module-bluetooth-discover.so
  unload-module module-bluetooth-discover
  load-module module-bluetooth-discover
.endif
EOF
  fi
}

fix_ferdi_chat() {
  CONFIG_FILE="${HOME}"/.config/Ferdi/recipes/hangoutschat/index.js
  if [[ -f "${CONFIG_FILE}" ]]; then
    info Fixing up Hangouts Chat Config
    sed -i 's|https://chat.google.com|https://dynamite-preprod.sandbox.google.com|g' "${CONFIG_FILE}"
    sed -i 's|Mozilla/5.0 (X11; Linux x86_64; rv:72.0) Gecko/20100101 Firefox/72.0|Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36|' "${CONFIG_FILE}"
  fi
}

docker_setup() {
  info Setting up Docker
  if ! dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    sudo glinux-add-repo -b docker-ce-"$(lsb_release -cs)" >/dev/null || fail Failed to add Docker repo
    _apt update >/dev/null || fail Failed to update
    _apt -y install docker-ce >/dev/null || fail Failed to install Docker
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
    #bluetooth_setup
    docker_setup
    install_vs_code
    install_sdk_man
    fix_ferdi_chat
    install_kubectx
    install_chromium_flatpak
    install_spotify_flatpak
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
