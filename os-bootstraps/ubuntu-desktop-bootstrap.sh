#!/bin/bash
#shellcheck disable=SC1090
if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    else
        DOTFILES_ROOT="${PWD}"
    fi
fi

if [ -z "${OS_BOOTSTRAP_ROOT}" ]; then
    if [ -f "${DOTFILES_ROOT}"/debian-bootstrap.sh ]; then
        OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"
        if command -v realpath >/dev/null 2>&1; then
            DOTFILES_ROOT="$(realpath "${DOTFILES_ROOT}"/..)"
        fi
    else
        OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"/os-bootstraps
        if [ -f "${DOTFILES_ROOT}"/debian-bootstrap.sh ]; then
            echo Cannot find OS bootstraps
            exit 1
        fi
    fi
fi

. "${OS_BOOTSTRAP_ROOT}/debian-common.sh"

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
        #curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - >/dev/null
        curl -sS https://download.spotify.com/debian/pubkey_0D811D58.gpg | _sudo apt-key add -
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
        _apt update && _apt install -y spotify-client >/dev/null 2>&1
    fi
}

main() {
    CALLBACKS+=(
        install_apt_packages
        install_spotify
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
