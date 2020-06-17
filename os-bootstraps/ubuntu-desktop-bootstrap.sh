#!/bin/bash

# TODO install spotify

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

main() {
    CALLBACKS+=(
        passwordless_sudo
        install_apt_packages
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
