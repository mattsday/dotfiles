#!/bin/bash
# Configuration for all KDE desktops - mainly for Baloo

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

# Only enable as a non-root user
if command -v id >/dev/null 2>&1; then
    if [[ "$(id -u)" = 0 ]]; then
        exit
    fi
else
    warn Cannot determine if user is root
    exit
fi

configure_baloo() {
    if ! command -v balooctl >/dev/null 2>&1; then
        return
    fi
    # List of unwanted folders
    UNWATED_FOLDERS=(
        "${HOME}/snap"
        "${HOME}/go"
        "${HOME}/Android"
        "${HOME}/Documents/GnuCash"
        "${HOME}/Games/battlenet/"
        "${HOME}/Projects/Archive"
        "${HOME}/Projects/Personal/Banking"
        "${HOME}/Projects/Personal/mwafi5"
        "${HOME}/Projects/Cisco Legacy"
    )

    UNWANTED_FILTERS=(
        '*.dex'
        '*.xml'
        '*.ts'
        '*.len'
        '*.flat'
        '*.json'
        '*.tab'
        '*.tsx'
        '*.tab_i'
        '*.gpg'
        '*.sig'
        'build'
    )

    info Configuring file indexer
    UPDATE=false
    for folder in "${UNWATED_FOLDERS[@]}"; do
        if [[ -d "${folder}" ]]; then
            if balooctl config add excludeFolders "${folder}" >/dev/null; then
                info Ignoring "${folder}" from index
                UPDATE=true
            fi
        fi
    done

    for filter in "${UNWANTED_FILTERS[@]}"; do
        if balooctl config add excludeFilters "${filter}" >/dev/null; then
            info Ignoring "${filter}" from index
            UPDATE=true
        fi
    done

    if [[ "${UPDATE}" = true ]]; then
        info Rebuilding index
        balooctl disable >/dev/null 2>&1
        balooctl purge >/dev/null 2>&1
        sleep 2
        balooctl disable >/dev/null 2>&1
        sleep 1
        balooctl enable >/dev/null 2>&1
        balooctl check >/dev/null 2>&1
    fi
}

# Disable discover notifications - it's super annoying
configure_discover() {
    DISCOVER_NOTIFIER="${HOME}/.config/autostart/org.kde.discover.notifier.desktop"
    if [[ ! -f "${DISCOVER_NOTIFIER}" ]]; then
        if [[ ! -d "${HOME}/.config/autostart" ]]; then
            mkdir -p "${HOME}/.config/autostart" || fail Could not create "${HOME}/.config/autostart"
            return
        fi
        if [[ -f /etc/xdg/autostart/org.kde.discover.notifier.desktop ]]; then
            info Disabling Discover notifications
            cp /etc/xdg/autostart/org.kde.discover.notifier.desktop "${DISCOVER_NOTIFIER}" || fail Could not create "${DISCOVER_NOTIFIER}"
            echo 'Hidden=true' | tee -a "${DISCOVER_NOTIFIER}" >/dev/null
        fi
    fi
}

configure_dolphin() {
    if ! command -v xdg-mime >/dev/null 2>&1; then
        info Install xdg-mime to set dolphin as default
        return
    fi
    current="$(xdg-mime query default inode/directory)"
    if [[ "$current" != org.kde.dolphin.desktop ]]; then
        info Setting dolphin as default file browser
        xdg-mime default org.kde.dolphin.desktop inode/directory
    fi

}

main() {
    configure_baloo
    configure_discover
    configure_dolphin
}

main
