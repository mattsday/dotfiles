#!/bin/sh

# Set DOTFILES_COMMON so this doesn't get called too much
[ -n "${DOTFILES_COMMON}" ] && return
DOTFILES_COMMON=1

# Messages
error() {
    echo >&2 '[Failure]' "$@"
    exit 1
}

fail() {
    echo >&2 '[Failure]' "$@"
    return 1
}

warn() {
    echo >&2 '[Warning]' "$@"
}

info() {
    echo "$@"
}

# Utility commands
_sudo() {
    echo _sudo
    if [ "${NO_SUDO}" = 1 ]; then
        return
    elif [ "${IS_ROOT}" = 1 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

sudo_disabled() {
    if [ "${NO_SUDO}" != 1 ]; then
        echo Warning - sudo is either not installed or is disabled
    fi
    NO_SUDO=1
}

configure_paths() {
    if [ -z "${DOTFILES_ROOT}" ]; then
        if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
            DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
        else
            DOTFILES_ROOT="${PWD}"
        fi
    fi

    if [ -z "${OS_BOOTSTRAP_ROOT}" ]; then
        if [ -f "${DOTFILES_ROOT}"/init.sh ]; then
            OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"/os-bootstraps
        else
            # We're executing from os-bootstraps/
            OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"
            DOTFILES_ROOT="$(realpath "${DOTFILES_ROOT}"/..)"
        fi
    fi
}

load_debian_common() {
    . "${OS_BOOTSTRAP_ROOT}/debian-common.sh"
}

main() {
    configure_paths
    # Check if sudo is installed
    if [ ! -x /usr/bin/sudo ]; then
        if command -v id >/dev/null 2>&1; then
            if [ "$(id -u)" = 0 ]; then
                IS_ROOT=1
            else
                sudo_disabled
            fi
        fi
    fi

    if [ -f "${HOME}/.disable_dotfiles_sudo" ]; then
        sudo_disabled
    fi
}

main
