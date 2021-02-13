#!/bin/bash
# Configuration for all KDE desktops - mainly for Baloo

info() {
    echo "$@"
}

# List of unwanted folders
UNWATED_FOLDERS=(
    "$HOME/snap"
    "$HOME/go"
    "$HOME/Android"
    "$HOME/Documents/GnuCash"
    "$HOME/Games/battlenet/"
)

UNWANTED_FILTERS=(
    '*.dex'
)

info Configuring file indexer
UPDATE=false
for folder in "${UNWATED_FOLDERS[@]}"; do
    if [ -d "$folder" ]; then
        if balooctl config add excludeFolders "$folder" >/dev/null; then
            info Ignoring "$folder" from index
            UPDATE=true
        fi
    fi
done

for filter in "${UNWANTED_FILTERS[@]}"; do
    if balooctl config add excludeFilters "$filter" >/dev/null; then
        info Ignoring "$filter" from index
        UPDATE=true
    fi
done

if [ "$UPDATE" = true ]; then
    info Rebuilding index
    balooctl disable >/dev/null 2>&1
    balooctl purge >/dev/null 2>&1
    sleep 2
    balooctl disable >/dev/null 2>&1
    sleep 1
    balooctl enable >/dev/null 2>&1
    balooctl check >/dev/null 2>&1
fi
