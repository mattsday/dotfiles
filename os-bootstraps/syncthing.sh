#!/bin/bash
# Sets up syncthing - currently Debian-based systems only, but could work for others in the future

if [ -z "${DOTFILES_ROOT}" ]; then
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

if [ ! -x /usr/bin/systemctl ] || ! systemctl status --user >/dev/null 2>&1; then
    error Cannot setup syncthing without systemd
    exit
fi

install_syncthing() {
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(syncthing)
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
}

# Configure Systemd services for the local user
configure_syncthing_service() {
    # Only enable syncthing as a non-root user
    if command -v id >/dev/null 2>&1; then
        if [ "$(id -u)" = 0 ]; then
            return
        fi
    else
        warn Cannot determine if user is root - not enabling syncthing service
        return
    fi
    # Install systemd services
    if [[ "$(systemctl list-unit-files --user syncthing.service | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user syncthing.service; then
        info Enabling syncthing service
        systemctl enable --now --user syncthing.service
    fi
}

main() {
    info Setting up syncthing
    install_syncthing
    configure_syncthing_service
}

main
