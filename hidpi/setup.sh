#!/bin/sh

error() {
    echo >&2 '[Error]' "$@"
    exit 1
}

main() {
    # Set GDK global scaling
    if [ ! -f /etc/profile.d/gdk-scale.sh ]; then
        cat <<EOF | sudo tee /etc/profile.d/gdk-scale.sh
#!/bin/sh
export GDK_DPI_SCALE=1.5
EOF
    fi

    # Spotify client doesn't respect external scale factors, do so here
    if [ -f /usr/share/spotify/spotify.desktop ] && [ ! -f "${HOME}/.local/share/applications/spotify.desktop" ]; then
        cp /usr/share/spotify/spotify.desktop "${HOME}/.local/share/applications/" || error "Cannot move spotify config"
        sed -i 's/Exec=spotify %U/Exec=spotify --force-device-scale-factor=1.5 %U/' "${HOME}/.local/share/applications/spotify.desktop"
    fi
}
main
