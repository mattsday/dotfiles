#!/bin/bash
# Sets up pipewire, currently on Debian-based desktops but maybe others in the future

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

if [[ ! -x /usr/bin/systemctl ]] || ! systemctl status --user >/dev/null 2>&1; then
    error Cannot setup pipewire without systemd
    exit
fi

install_pipewire_packages() {
    # Back up current packages
    BACKUP_APT_PACKAGES=("${APT_PACKAGES[@]}")
    # Install build packages immediately
    APT_PACKAGES=(libldacbt-abr2 libldacbt-enc2 pipewire-bin pipewire-audio-client-libraries libpipewire-0.3-0 dbus-user-session libspa-0.2-bluetooth libspa-0.2-jack gstreamer1.0-pipewire pipewire-pulse)
    # Check they exist (they won't in older Debian or Ubuntu versions)
    for package in "${APT_PACKAGES[@]}"; do
        if ! apt-cache show "${package}" >/dev/null 2>&1; then
            fail "Pipewire not supported on this OS ${package} not found"
            APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
            return 1
        fi
    done
    # Now check if wireplumber or media-session is available:
    if [[ "$(apt-cache policy wireplumber | grep 'Candidate:' | cut -f 2 -d : | xargs)" != "(none)" ]]; then
        APT_PACKAGES+=(wireplumber)
        # Remove pipewire-media-session if installed
        systemctl --user --now disable pipewire-media-session.service >/dev/null 2>&1
        systemctl --user --now mask pipewire-media-session.service >/dev/null 2>&1
        _sudo apt-get -y remove pipewire-media-session >/dev/null 2>&1
    elif ! apt-cache show pipewire-media-session >/dev/null 2>&1; then
        APT_PACKAGES+=(pipewire-media-session)
    fi
    install_apt_packages
    APT_PACKAGES=("${BACKUP_APT_PACKAGES[@]}")
}

disable_pulseaudio() {
    # Only enable as a non-root user
    if command -v id >/dev/null 2>&1; then
        if [[ "$(id -u)" = 0 ]]; then
            return
        fi
    else
        warn Cannot determine if user is root
        return
    fi
    if systemctl -q is-active --user "pulseaudio.service"; then
        info Disabling pulseuadio
        systemctl --user --now disable pulseaudio.service pulseaudio.socket
        systemctl --user mask pulseaudio
    fi
}

# Configure Systemd services for the local user
configure_pipewire_services() {
    # Only enable as a non-root user
    if command -v id >/dev/null 2>&1; then
        if [[ "$(id -u)" = 0 ]]; then
            return
        fi
    else
        warn Cannot determine if user is root
        return
    fi
    if [[ -d "${PIPEWIRE_CONFIG_ROOT}" ]]; then
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
    fi

    # Install systemd services
    for service in pipewire pipewire-pulse; do
        if [[ "$(systemctl list-unit-files --user "${service}.service" | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user "${service}.service"; then
            systemctl enable --now --user "${service}.service" "${service}.socket"
        fi
    done
    if [[ "$(systemctl list-unit-files --user "wireplumber.service" | wc -l)" -gt 3 ]] && ! systemctl -q is-active --user "wireplumber.service"; then
        systemctl enable --now --user "wireplumber.service"
    fi

}

main() {
    # Don't run this if we can't run as root
    if [[ "${NO_SUDO}" = 1 ]]; then
        fail "Installation of Pipewire failed - cannot run as root"
        return 1
    fi
    if [[ -d /usr/share/pipewire ]]; then
        PIPEWIRE_CONFIG_ROOT=/usr/share/pipewire/media-session.d
    else
        PIPEWIRE_CONFIG_ROOT=/etc/pipewire/media-session.d
    fi
    info Setting up Pipewire
    install_pipewire_packages
    configure_pipewire_services
}

main
