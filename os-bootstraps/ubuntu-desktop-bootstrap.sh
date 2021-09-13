#!/bin/bash
#shellcheck disable=SC1090

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

DEBIAN_DESKTOP_BOOTSTRAP=debian-desktop-bootstrap.sh

# Load generic desktop bootstraps
if [[ -f "${OS_BOOTSTRAP_ROOT}"/"${DEBIAN_DESKTOP_BOOTSTRAP}" ]]; then
    echo Detected generic Debian-derived desktop
    . "${OS_BOOTSTRAP_ROOT}"/"${DEBIAN_DESKTOP_BOOTSTRAP}"
else
    echo Could not find debian-desktop.sh
fi

get_apt_packages() {
    APT_PACKAGES+=(openjdk-8-jdk openjdk-11-jdk python-is-python3 zenity)
}

get_snap_packages() {
    SNAP_PACKAGES+=("code --classic")
}

install_spotify() {
    # Don't run this if we can't run as root
    if [[ "${NO_SUDO}" = 1 ]]; then
        return
    fi
    if ! dpkg-query -W -f='${Status}' spotify-client 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
        curl -fsSL https://download.spotify.com/debian/pubkey_0D811D58.gpg | sudo gpg --dearmor -o /usr/share/keyrings/spotify-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg]deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
        _apt update && _apt install -y spotify-client >/dev/null 2>&1
    fi
}

# Install pipewire PPA for older Ubuntu versions
pipewire_ppa() {
    UBUNTU_VERSION="$(grep UBUNTU_CODENAME /etc/os-release | cut -d = -f 2)"
    if [ "${UBUNTU_VERSION}" = focal ]; then
        if [ ! -f /etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-"${UBUNTU_VERSION}".list ]; then
            info Adding Pipewire PPA
            sudo add-apt-repository -y ppa:pipewire-debian/pipewire-upstream >/dev/null
        fi
    fi
}

main() {
    CALLBACKS+=(
        install_apt_packages
        install_spotify
        pipewire_ppa
    )
    get_apt_packages
    get_snap_packages

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
