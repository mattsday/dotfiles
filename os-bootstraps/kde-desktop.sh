#!/bin/bash
# Configuration for all KDE desktops - mainly for Baloo

info() {
    echo "$@"
}

# List of unwanted folders
UNWATED=(
    "$HOME/snap"
    "$HOME/go"
    "$HOME/Android"
    "$HOME/Documents/GnuCash"
)

info Configuring file indexer

for folder in "${UNWATED[@]}"; do
    if [ -d "$folder" ]; then
        balooctl config add excludeFolders "$folder" >/dev/null
    fi
done
