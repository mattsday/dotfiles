#!/bin/bash

if [[ -z "${FERDI_DEV_BASE_DIR}" ]]; then
    FERDI_DEV_BASE_DIR="${HOME}/.config/Ferdi/recipes/dev"
fi
GIT_LOCATION="https://github.com/mattsday/ferdi-anylist"
PLUGIN_DIR="anylist"

error() {
    echo >&2 '[Error]' "$@"
    exit 1
}

warn() {
    echo >&2 '[Warn]' "$@"
}

info() {
    echo "$@"
}

check_cmd() {
    if ! command -v "$@" >/dev/null 2>&1; then
        error Command "$@" not found - please install it
    fi
}

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
