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
    # Don't run this if we can't run as root
    if [[ "${NO_SUDO}" = 1 ]]; then
        return
    fi
    # Spotify changes its apt key from time to time; keep it up to date here
    KEY_URL=https://download.spotify.com/debian/pubkey_5E3C45D7B312C643.gpg
    KEY_NAME=/usr/share/keyrings/spotify-archive-keyring-5E3C45D7B312C643.gpg
    APT_SOURCE_FILE=/etc/apt/sources.list.d/spotify.list

    if [[ ! -f "${KEY_NAME}" ]]; then
        curl -fsSL "${KEY_URL}" | sudo gpg --dearmor -o "${KEY_NAME}"
        if [[ -f "${APT_SOURCE_FILE}" ]]; then
            sudo rm "${APT_SOURCE_FILE}"
        fi
        echo "deb [arch=amd64 signed-by=${KEY_NAME}] http://repository.spotify.com stable non-free" | sudo tee "${APT_SOURCE_FILE}" >/dev/null
        _apt update >/dev/null 2>&1 && _apt install -y spotify-client >/dev/null 2>&1
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
        sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
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
