#!/bin/bash
# Install upstream Docker

# Get OS type
OS_TYPE="$(grep '^ID=' /etc/os-release | cut -f 2 -d=)"

if [[ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(grep '^ID=' /etc/os-release | cut -f 2 -d=) $(grep '^VERSION_CODENAME=' /etc/os-release | cut -f 2 -d =) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    DEBIAN_FRONTEND="noninteractive" sudo apt-get update
fi

if ! dpkg-query -W -f='${Status}' "docker-ce" 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    APT_PACKAGES+=(docker-ce docker-ce-cli containerd.io)
    # If we're not being sourced
    #shellcheck disable=SC2154
    if [[ -z "${_debian_bootstrap_mattsday}" ]]; then
        install_apt_packages
    fi
fi
