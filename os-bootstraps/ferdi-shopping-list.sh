#!/bin/bash

BASE_DIR="${HOME}/.config/Ferdi/recipes/dev"
GIT_LOCATION="https://github.com/sharkpp/franz-recipe-google-shoppinglist"
PLUGIN_DIR="google-shopping-list"

error() {
    >&2 echo '[Error]' "$@"
    exit 1
}

warn() {
    >&2 echo '[Warn]'  "$@"
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

    if [[ ! -d "${BASE_DIR}" ]]; then
        mkdir -p "${BASE_DIR}" || error "Could not create directory ${BASE_DIR}"
    fi

    cd "${BASE_DIR}" || error "Could not change directory to ${BASE_DIR}"

    if [[ ! -d "${BASE_DIR}/${PLUGIN_DIR}" ]]; then
        git clone "${GIT_LOCATION}" "${PLUGIN_DIR}" || error "Could not clone git project"
    else
        cd "${BASE_DIR}/${PLUGIN_DIR}" || error "Could not change directory to ${BASE_DIR}/${PLUGIN_DIR}"
        git pull || error "Could not run a git pull"
    fi

    info Ferdi Shopping List installation successful
    
}
# Run main function
main


