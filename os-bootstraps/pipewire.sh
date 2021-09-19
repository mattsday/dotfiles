#!/bin/bash
# Sets up pipewire, currently on Debian-based desktops but maybe others in the future

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

install_pipewire_packages() {
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(libldacbt-abr2 libldacbt-enc2 pipewire-bin pipewire-audio-client-libraries libpipewire-0.3-0 dbus-user-session libspa-0.2-bluetooth libspa-0.2-jack gstreamer1.0-pipewire pipewire-pulse pipewire-media-session)
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
}

disable_pulseaudio() {
    if systemctl -q is-active --user "pulseaudio.service"; then
        info Disabling pulseuadio
        systemctl --user --now disable pulseaudio.service pulseaudio.socket
        systemctl --user mask pulseaudio
    fi
}

# Configure Systemd services for the local user
configure_pipewire_services() {
    # Enable pulseaudio and JACK via pipwire
    if [[ ! -f "${PIPEWIRE_CONFIG_ROOT}"/with-pulseaudio ]]; then
        _sudo touch "${PIPEWIRE_CONFIG_ROOT}"/with-pulseaudio
    fi
    if [[ ! -f "${PIPEWIRE_CONFIG_ROOT}"/with-alsa ]]; then
        _sudo touch "${PIPEWIRE_CONFIG_ROOT}"/with-alsa
    fi
    if [[ ! -f "${PIPEWIRE_CONFIG_ROOT}"/with-jack ]]; then
        _sudo touch "${PIPEWIRE_CONFIG_ROOT}"/with-jack
    fi

    # Install systemd services
    for service in pipewire pipewire-media-session pipewire-pulse; do
        if [[ "$(systemctl list-unit-files --user "${service}.service" | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user "${service}.service"; then
            systemctl enable --now --user "${service}.service" "${service}.socket"
        fi
    done
}

main() {
    # Don't run this if we can't run as root
    if [[ "${NO_SUDO}" = 1 ]]; then
        fail "Installation of Pipewire failed - cannot run as root"
        return 1
    fi
    if [ -d /usr/share/pipewire ]; then
        PIPEWIRE_CONFIG_ROOT=/usr/share/pipewire/media-session.d
    else
        PIPEWIRE_CONFIG_ROOT=/etc/pipewire/media-session.d
    fi
    info Setting up Pipewire
    install_pipewire_packages
    configure_pipewire_services
}

main
