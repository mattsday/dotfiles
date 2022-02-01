#!/bin/bash
# Attempts to fast-forward pipewire fixes in case the current distribution's is broken (as was the case for 0.3.42)

# Desired versions to bump to
PW_VERSION=0.3.44-1
WP_VERSION=0.4.7-1

# What to upgrade
PW_UPGRADE=1
WP_UPGRADE=1

MIRROR=http://ftp.de.debian.org
PW_BASE=/debian/pool/main/p/pipewire/
WP_BASE=/debian/pool/main/w/wireplumber/

TMP_DIR=/tmp/pipewire-upg

PW_FILES=(
    "libspa-0.2-modules_${PW_VERSION}_amd64.deb"
    "libspa-0.2-bluetooth_${PW_VERSION}_amd64.deb"
    "libspa-0.2-jack_${PW_VERSION}_amd64.deb"
    "libpipewire-0.3-common_${PW_VERSION}_all.deb"
    "pipewire-pulse_${PW_VERSION}_amd64.deb"
    "libpipewire-0.3-modules_${PW_VERSION}_amd64.deb"
    "pipewire-bin_${PW_VERSION}_amd64.deb"
    "pipewire-audio-client-libraries_${PW_VERSION}_amd64.deb"
    "gstreamer1.0-pipewire_${PW_VERSION}_amd64.deb"
    "pipewire_${PW_VERSION}_amd64.deb"
    "libpipewire-0.3-0_${PW_VERSION}_amd64.deb"
)
WP_FILES=(
    "wireplumber_${WP_VERSION}_amd64.deb"
    "libwireplumber-0.4-0_${WP_VERSION}_amd64.deb"
)

error() {
    echo >&2 '[Error]' "$@"
    exit 1
}

download() {
    curl -s -L -o "${2}" "${1}" || error Could not download "${URL}"
}

main() {
    if [[ -d "${TMP_DIR}" ]]; then
        rm -r "${TMP_DIR}" || error Could not clear "${TMP_DIR}"
    fi
    mkdir "${TMP_DIR}" || error Could not create "${TMP_DIR}"

    if [[ "${PW_UPGRADE}" = 1 ]]; then
        for f in "${PW_FILES[@]}"; do
            URL="${MIRROR}${PW_BASE}${f}"
            download "${URL}" "${TMP_DIR}/${f}"
            FILES+=("${TMP_DIR}/${f}")
        done
    fi

    if [[ "${WP_UPGRADE}" = 1 ]]; then
        for f in "${WP_FILES[@]}"; do
            URL="${MIRROR}${WP_BASE}${f}"
            download "${URL}" "${TMP_DIR}/${f}"
            FILES+=("${TMP_DIR}/${f}")
        done
    fi

    sudo dpkg -i "${FILES[@]}"
}
main
