#!/bin/sh
# Set up passwordless sudo based on the username

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    else
        DOTFILES_ROOT="${PWD}"
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

if ! command -v id >/dev/null 2>&1; then
    error '[Failure] Command "id" not found'
    exit 1
fi

if [ -n "${USER}" ]; then
    username="${USER}"
else
    username="$(id -un)"
fi

if [ -z "${username}" ]; then
    error '[Failure] Cannot determine username'
fi

if [ "$(id -u)" -ne 0 ] && [ -x /usr/bin/sudo ] && [ "${NO_SUDO_CONFIG}" = 0 ]; then
    if [ ! -f /etc/sudoers.d/nopasswd-"${username}" ]; then
        info Setting up passwordless sudo
        echo "${username}"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd-"${username}" >/dev/null
    fi
fi
