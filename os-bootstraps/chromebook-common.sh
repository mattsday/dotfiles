#!/bin/bash
# Common between Bruschetta and Crostini
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
    configure_fonts
    configure_chromebook_git
  )
  if [[ -f chromebook.sh ]]; then
    . ./chromebook-common.sh
  fi
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
