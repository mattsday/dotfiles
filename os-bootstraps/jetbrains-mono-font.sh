#!/bin/sh

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    else
        DOTFILES_ROOT="${PWD}"
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

FONT_LOCATION="https://download.jetbrains.com/fonts/JetBrainsMono-1.0.3.zip"
FONT_ARCHIVE="/tmp/JetBrainsMono-1.0.3.zip"
FONT_DIR="/tmp/jetbrains-mono"
TTF_DIR="${FONT_DIR}"/JetBrainsMono-1.0.3/ttf
LOCAL_FONT="${HOME}"/.local/share/fonts/

MAC=0
if [ "$(uname)" = Darwin ]; then
    MAC=1
    LOCAL_FONT="${HOME}/Library/Fonts"
fi

main() {
    if [ -f "${LOCAL_FONT}"/JetBrainsMono-Regular.ttf ]; then
        #Fonts already installed in "${LOCAL_FONT}"
        exit 0
    fi

    check_cmd curl
    check_cmd unzip
    if [ "${MAC}" = 0 ]; then
        check_cmd fc-cache
    fi

    # Download it
    curl -Lo "${FONT_ARCHIVE}" "${FONT_LOCATION}" || error Could not download from "${FONT_LOCATION}" to "${FONT_ARCHIVE}"

    mkdir -p "${FONT_DIR}" || error Could not create dir "${FONT_DIR}"

    unzip -od "${FONT_DIR}" "${FONT_ARCHIVE}" >/dev/null || error "Failed to unzip ${FONT_ARCHIVE}"

    if [ ! -d "${TTF_DIR}" ]; then
        error Cannot find ttf directory in "${TTF_DIR}"
    fi

    # Copy files to local font cache
    if [ ! -d "${LOCAL_FONT}" ]; then
        mkdir -p "${LOCAL_FONT}" || error "Could not create local font dir in ${LOCAL_FONT}"
    fi

    cp "${TTF_DIR}"/*.ttf "${LOCAL_FONT}" || error Could not copy fonts to "${LOCAL_FONT}"
    if [ "${MAC}" = 0 ]; then
        fc-cache -f -v >/dev/null
    fi
    info Fonts updated

}

main "$@"
