#!/bin/sh

# Set DOTFILES_COMMON so this doesn't get called too much
[ -n "${DOTFILES_COMMON}" ] && return
DOTFILES_COMMON=1

# Messages

# Exits completely
error() {
    echo >&2 '[Error]' "$@"
    exit 1
}

# Prints a failure message but the caller should terminate execution itself
# Returns 1 for error handling
fail() {
    echo >&2 '[Failure]' "$@"
    return 1
}

# Sends a warning to stderr
warn() {
    echo >&2 '[Warning]' "$@"
}

# Informational messages
info() {
    echo "$@"
}

# Check if a command exists already
check_cmd() {
    if ! command -v "$@" >/dev/null 2>&1; then
        error Command "$@" not found - please install it
    fi
}

# Utility commands
_sudo() {
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

    if [ -z "${OS_BOOTSTRAP_ROOT}" ]; then
        if [ -f "${DOTFILES_ROOT}"/init.sh ]; then
            OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"/os-bootstraps
        else
            # We're executing from os-bootstraps/
            OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"
            if command -v realpath >/dev/null 2>&1; then
                DOTFILES_ROOT="$(realpath "${DOTFILES_ROOT}"/..)"
            elif command -v dirname >/dev/null 2>&1; then
                DOTFILES_ROOT="$(
                    cd "$(dirname "${DOTFILES_ROOT}"/..)" || return
                    pwd
                )"
            fi
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
