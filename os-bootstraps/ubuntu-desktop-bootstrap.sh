#!/bin/bash
#shellcheck disable=SC1090,SC2312

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
    if [[ -f "${OS_BOOTSTRAP_ROOT}/spotify.sh" ]]; then
        "${OS_BOOTSTRAP_ROOT}/spotify.sh"
    fi
}

# Install pipewire PPA for older Ubuntu versions
pipewire_ppa() {
    UBUNTU_VERSION="$(grep UBUNTU_CODENAME /etc/os-release | cut -d = -f 2)"
    if [[ "${UBUNTU_VERSION}" = focal ]] || [[ "${UBUNTU_VERSION}" = impish ]]; then
        if [[ ! -f /etc/apt/sources.list.d/pipewire-debian-ubuntu-pipewire-upstream-"${UBUNTU_VERSION}".list ]]; then
            info Adding Pipewire PPA
            _sudo add-apt-repository -y ppa:pipewire-debian/pipewire-upstream >/dev/null
        fi
    fi
}
# Install wireplumber PPA for older Ubuntu versions
wireplumber_ppa() {
    UBUNTU_VERSION="$(grep UBUNTU_CODENAME /etc/os-release | cut -d = -f 2)"
    if [[ "${UBUNTU_VERSION}" = focal ]] || [[ "${UBUNTU_VERSION}" = impish ]]; then
        if [[ ! -f /etc/apt/sources.list.d/pipewire-debian-ubuntu-wireplumber-upstream-"${UBUNTU_VERSION}".list ]]; then
            info Adding Wireplumber PPA
            _sudo apt-add-repository -y ppa:pipewire-debian/wireplumber-upstream >/dev/null
        fi
    fi
}

vs_code() {
    if ! command -v code >/dev/null 2>&1; then
        info Setting up VS Code
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
        _sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        _sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        _apt update >/dev/null
        APT_PACKAGES+=(code)
    fi
}

docker() {
    if [[ -f "${OS_BOOTSTRAP_ROOT}/docker.sh" ]]; then
        "${OS_BOOTSTRAP_ROOT}/docker.sh"
    fi
}

main() {
    CALLBACKS+=(
        vs_code
        install_apt_packages
        install_spotify
        pipewire_ppa
        wireplumber_ppa
        docker
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
