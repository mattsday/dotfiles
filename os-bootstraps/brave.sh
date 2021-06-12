#!/bin/bash
# Install the brave browser manually

VERSION=1.25.70
URL="https://github.com/brave/brave-browser/releases/download/v${VERSION}/brave-browser-${VERSION}-linux-amd64.zip"
DEST=/opt/brave
ZIP=/opt/brave/brave-browser.zip
ICON_DIR="${HOME}"/.local/share/icons/hicolor
DESKTOP_DIR="${HOME}"/.local/share/applications

fail() {
    echo >&2 '[Failure]' "$@"
    exit 1
}

warn() {
    echo >&2 '[Warning]' "$@"
}

info() {
    echo "$@"
}

# Check existing version to see if we need to run this
if [ -x "${DEST}/brave" ]; then
    INSTALLED="$("${DEST}/brave" --version | cut -d " " -f 3 | cut -d '.' -f '2-')"
    if [ "${INSTALLED}" = "${VERSION}" ] && [ -z "${FORCE}" ]; then
        info Brave up to date
        exit 0
    fi
fi

info Installing or Upgrading Brave Browser

check_cmd() {
    if ! command -v "${1}" >/dev/null 2>&1; then
        fail Command "${1}" not found - please install it
        exit 1
    fi
}

check_cmd curl
check_cmd unzip

if [ ! -d /opt/brave ]; then
    sudo mkdir "${DEST}" || fail "Cannot create dir ${DEST}"
    sudo chmod "${USER}" "${DEST}" || fail "Cannot claim ownership of ${DEST}"
fi

# Take ownership of the brave destination
sudo chown -R "${USER}" "${DEST}" || warn "Failed to take ownership of ${DEST} as ${USER}"

if [ -f "${ZIP}" ]; then
    rm "${ZIP}" || fail Cannot delete "${ZIP}"
fi

curl -s -L -o "${ZIP}" "${URL}" || fail Could not download "${URL}"

unzip -qq -od "${DEST}" "${ZIP}" || fail Could not extract "${ZIP}"

if [ ! -d "${ICON_DIR}" ]; then
    mkdir -p "${ICON_DIR}" || warn "Could not create ${ICON_DIR}"
fi

for i in "${DEST}"/product_logo_*.png; do
    size="$(echo "${i}" | cut -d . -f 1 | cut -d _ -f 3)"
    icon_dest="${ICON_DIR}/${size}x${size}/apps"
    if [ ! -d "${icon_dest}" ]; then
        mkdir -p "${icon_dest}" || warn "Could not create ${icon_dest}"
    fi
    if [ ! -f "${icon_dest}/brave-browser.png" ]; then
        cp "${i}" "${icon_dest}/brave-browser.png" || warn "Could not move ${i} to ${icon_dest}"
    fi
done

if [ ! -d "${DESKTOP_DIR}" ]; then
    mkdir -p "${DESKTOP_DIR}" || warn "Could not create ${DESKTOP_DIR}"
fi

if [ ! -f "${DESKTOP_DIR}/brave-browser.desktop" ]; then
    cat <<EOF | tee "${DESKTOP_DIR}/brave-browser.desktop" >/dev/null
[Desktop Entry]
Version=1.0
Name=Brave Web Browser
Comment=Access the Internet
Exec=/opt/brave/brave-browser %U
StartupNotify=true
Terminal=false
Icon=brave-browser
Type=Application
Categories=Network;WebBrowser;
MimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/ftp;x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/ipfs;x-scheme-handler/ipns;
Actions=new-window;new-private-window;

[Desktop Action new-window]
Name=New Window
Exec=/opt/brave/brave-browser

[Desktop Action new-private-window]
Name=New Incognito Window
Exec=/opt/brave/brave-browser --incognito
EOF
fi