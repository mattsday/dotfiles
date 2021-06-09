#!/bin/sh
# Set up passwordless sudo based on the username

if ! command -v id >/dev/null 2>&1; then
    echo >&2 '[Failure] Command "id" not found'
    exit 1
fi

if [ -n "${USER}" ]; then
    username="${USER}"
else
    username="$(id -un)"
fi

if [ -z "${username}" ]; then
    echo >&2 '[Failure] Cannot determine username'
    exit 1
fi

if [ "$(id -u)" -ne 0 ] && [ -x /usr/bin/sudo ] && [ "${NO_SUDO_CONFIG}" = 0 ]; then
    if [ ! -f /etc/sudoers.d/nopasswd-"${username}" ]; then
        echo Setting up passwordless sudo
        echo "${username}"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd-"${username}" >/dev/null
    fi
fi
