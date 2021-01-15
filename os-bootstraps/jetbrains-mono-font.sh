#!/bin/sh
FONT_LOCATION="https://download.jetbrains.com/fonts/JetBrainsMono-1.0.3.zip"
FONT_ARCHIVE="/tmp/JetBrainsMono-1.0.3.zip"
FONT_DIR="/tmp/jetbrains-mono"
TTF_DIR="$FONT_DIR"/JetBrainsMono-1.0.3/ttf
LOCAL_FONT="$HOME"/.local/share/fonts/

MAC=0
if [ "$(uname)" = Darwin ]; then
    MAC=1
    LOCAL_FONT="$HOME/Library/Fonts"
fi

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

check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail Command "$1" not found - please install it
        exit 1
    fi
}

main() {
    if [ -f "$LOCAL_FONT"/JetBrainsMono-Regular.ttf ]; then
        info Fonts already installed in "$LOCAL_FONT"
        exit 0
    fi

    check_cmd curl
    check_cmd unzip
    if [ "$MAC" = 0 ]; then
        check_cmd fc-cache
    fi

    # Download it
    curl -Lo "$FONT_ARCHIVE" "$FONT_LOCATION" || fail Could not download from "$FONT_LOCATION" to "$FONT_ARCHIVE"

    mkdir -p "$FONT_DIR" || fail Could not create dir "$FONT_DIR"

    unzip -od "$FONT_DIR" "$FONT_ARCHIVE" >/dev/null || fail "Failed to unzip $FONT_ARCHIVE"

    if [ ! -d "$TTF_DIR" ]; then
        fail Cannot find ttf directory in "$TTF_DIR"
    fi

    # Copy files to local font cache
    if [ ! -d "$LOCAL_FONT" ]; then
        mkdir -p "$LOCAL_FONT" || fail "Could not create local font dir in $LOCAL_FONT"
    fi

    cp "$TTF_DIR"/*.ttf "$LOCAL_FONT" || fail Could not copy fonts to "$LOCAL_FONT"
    if [ "$MAC" = 0 ]; then
        fc-cache -f -v >/dev/null
    fi
    info Fonts updated

}

main "$@"
