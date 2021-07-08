#!/bin/sh
# Shim to load the real common.sh environment when executing directly

# Set DOTFILES_COMMON so this doesn't get called too much
[ -n "${DOTFILES_OS_BOOTSTRAP_COMMON}" ] && return
DOTFILES_OS_BOOTSTRAP_COMMON=1

if [ -z "${OS_BOOTSTRAP_ROOT}" ]; then
    if [ -f "${DOTFILES_ROOT}"/init.sh ]; then
        OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"/os-bootstraps
    else
        # We're executing from os-bootstraps/
        OS_BOOTSTRAP_ROOT="${DOTFILES_ROOT}"
        if command -v realpath >/dev/null 2>&1; then
            DOTFILES_ROOT="$(realpath "${DOTFILES_ROOT}"/..)"
        else
            # Without realpath just crudely remove os-bootstraps
            DOTFILES_ROOT="$(echo "${DOTFILES_ROOT}" | sed 's|/os-bootstraps||g')"
        fi
    fi
fi

. "${DOTFILES_ROOT}"/common.sh
