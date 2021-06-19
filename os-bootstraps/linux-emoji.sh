#!/bin/sh
# Sets up noto colour emoji as the default emoji font
# This in turn makes emojis so much better in e.g. Konsole, notifications, etc

if [ -z "${DOTFILES_ROOT}" ]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    else
        DOTFILES_ROOT="${PWD}"
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

info Setting up linux emoji

# Check if the correct fonts are installed and install them on debian-based distros
if [ -x /usr/bin/apt-get ] && [ -x /usr/bin/dpkg ]; then
    if ! dpkg-query -W -f='${Status}' fonts-noto 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
        DEBIAN_FRONTEND="noninteractive" sudo apt-get "$@" -y install fonts-noto fonts-noto'*' >/dev/null
    fi
elif ! fc-list 2>/dev/null | grep NotoColorEmoji >/dev/null 2>&1; then
    info Note - install fonts-noto-'*' after this
fi

# Check if fontconfig dir is a symlink and if so remove it
if [ -L "${HOME}"/.config/fontconfig ]; then
    rm "${HOME}"/.config/fontconfig || error Cannot unlink "${HOME}"/.config/fontconfig
fi

# Create the dir if needed
if [ ! -d "${HOME}"/.config/fontconfig ]; then
    mkdir -p "${HOME}"/.config/fontconfig || error Cannot create dir "${HOME}"/.config/fontconfig
fi

SOURCE_FILE="${DOTFILES_ROOT}"/dotfiles/special/fontconfig/fonts.conf
if [ ! -f "${SOURCE_FILE}" ]; then
    BASE="$(dirname "${PWD}" | xargs)"
    SOURCE_FILE="${BASE}"/dotfiles/special/fontconfig/fonts.conf
    if [ ! -f "${SOURCE_FILE}" ]; then
        error Cannot locate "${SOURCE_FILE}"
    fi
fi

DESTINATION_FILE="${HOME}"/.config/fontconfig/fonts.conf

# Check if the file is already symlinked, if so we can exit
if [ -L "${DESTINATION_FILE}" ] && EXISTING_FONTS_FILE=$(readlink "${HOME}"/.config/fontconfig/fonts.conf) 2>/dev/null; then
    if [ ! -L "${EXISTING_FONTS_FILE}" ]; then
        if [ "${EXISTING_FONTS_FILE}" = "${SOURCE_FILE}" ]; then
            # Don't bother continuing and running the expensive fc-cache command
            exit 0
        fi
    fi
fi

if [ -f "${DESTINATION_FILE}" ] && [ ! -L "${DESTINATION_FILE}" ]; then
    info Backing up local fonts.conf
    cp "${DESTINATION_FILE}" "${PWD}"/backup/local-fonts.conf || warn Cannot backup "${DESTINATION_FILE}" to "${PWD}"/backup/local-fonts.conf
fi

ln -fs "${SOURCE_FILE}" "${DESTINATION_FILE}" || error Cannot copy "${SOURCE_FILE}" to "${DESTINATION_FILE}"

fc-cache -f -v >/dev/null || warn fc-cache had errors
