#!/bin/bash

if [[ -z "${DOTFILES_ROOT}" ]]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    elif command -v dirname >/dev/null 2>&1; then
        DOTFILES_ROOT="$(cd "$(dirname "$0")" || return; pwd)"
	else
        echo >&2 '[Error] cannot determine root (try running from working directory)'
        exit 1
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

if [[ -z "${FERDI_DEV_BASE_DIR}" ]]; then
    FERDI_DEV_BASE_DIR="${HOME}/.config/Ferdi/recipes/dev"
fi
GIT_LOCATION="https://github.com/mattsday/ferdi-anylist"
PLUGIN_DIR="anylist"

main() {
    check_cmd git

    if [[ ! -d "${FERDI_DEV_BASE_DIR}" ]]; then
        mkdir -p "${FERDI_DEV_BASE_DIR}" || error "Could not create directory ${FERDI_DEV_BASE_DIR}"
    fi

    cd "${FERDI_DEV_BASE_DIR}" || error "Could not change directory to ${FERDI_DEV_BASE_DIR}"

    if [[ ! -d "${FERDI_DEV_BASE_DIR}/${PLUGIN_DIR}" ]]; then
        git clone "${GIT_LOCATION}" "${PLUGIN_DIR}" || error "Could not clone git project"
    else
        cd "${FERDI_DEV_BASE_DIR}/${PLUGIN_DIR}" || error "Could not change directory to ${FERDI_DEV_BASE_DIR}/${PLUGIN_DIR}"
        git config pull.rebase false
        git pull || error "Could not run a git pull"
    fi

    info Ferdi AnyList installation successful

}
# Run main function
main
