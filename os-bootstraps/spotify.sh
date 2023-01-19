#!/bin/bash
#shellcheck disable=SC1090

if [[ -z "${DOTFILES_ROOT}" ]]; then
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

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

# Don't run this if we can't run as root
if [[ "${NO_SUDO}" = 1 ]]; then
    return
fi
# Spotify changes its apt key from time to time; keep it up to date here
KEY_URL=https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg
KEY_NAME=/usr/share/keyrings/spotify-archive-keyring-7A3A762FAFD4A51F.gpg
APT_SOURCE_FILE=/etc/apt/sources.list.d/spotify.list

if [[ ! -f "${KEY_NAME}" ]]; then
    curl -fsSL "${KEY_URL}" | sudo gpg --dearmor -o "${KEY_NAME}"
    if [[ -f "${APT_SOURCE_FILE}" ]]; then
        sudo rm "${APT_SOURCE_FILE}"
    fi
    echo "deb [arch=amd64 signed-by=${KEY_NAME}] http://repository.spotify.com stable non-free" | sudo tee "${APT_SOURCE_FILE}" >/dev/null
    _apt update >/dev/null 2>&1 && _apt install -y spotify-client >/dev/null 2>&1
fi
