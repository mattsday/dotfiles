#!/bin/bash
#shellcheck disable=SC2154
DEBIAN_DESKTOP_BOOTSTRAP=debian-desktop-bootstrap.sh

# Load generic desktop bootstraps
if [ -f ./os-bootstraps/"$DEBIAN_DESKTOP_BOOTSTRAP" ]; then
    echo Detected generic Debian-derived desktop
    . ./os-bootstraps/"$DEBIAN_DESKTOP_BOOTSTRAP"
elif [ -f "$DEBIAN_DESKTOP_BOOTSTRAP" ]; then
    . ./"$DEBIAN_DESKTOP_BOOTSTRAP"
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

get_apt_packages() {
    APT_PACKAGES+=(openjdk-8-jdk openjdk-11-jdk)
}

get_snap_packages() {
    SNAP_PACKAGES+=("code --classic")
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

passwordless_sudo() {
    if [ ! -f /etc/sudoers.d/nopasswd ]; then
        echo "$USER"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd
    fi
}

install_spotify() {
    if ! dpkg-query -W -f='${Status}' spotify-client 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
        curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add - >/dev/null
        echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list >/dev/null
        sudo apt-get update && sudo apt-get install -y spotify-client >/dev/null 2>&1
    fi
}

main() {
    CALLBACKS+=(
        passwordless_sudo
        install_apt_packages
        install_spotify
    )
    get_apt_packages
    get_snap_packages

    # If we're not being sourced
    if [ -z "$_debian_bootstrap_mattsday" ]; then
        install_apt_packages
        for callback in "${CALLBACKS[@]}"; do
            "$callback"
        done
    fi
}

main "$@"
