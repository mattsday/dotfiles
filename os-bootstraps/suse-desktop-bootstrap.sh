#!/bin/bash
# Generic bootstrapping for any SUSE-derived desktop
#shellcheck disable=SC1090

fail() {
    echo >&2 '[Failure]' "$@"
    return 1
}

warn() {
    echo >&2 '[Warning]' "$@"
}

info() {
    echo "$@"
}

get_rpm_packages() {
    RPM_PACKAGES+=(pulseaudio-module-bluetooth solaar youtube-dl ckb-next)
}

install_rpm_packages() {
    get_rpm_packages
    INSTALL_PACKAGES=()
    for package in "${RPM_PACKAGES[@]}"; do
        if ! rpm -q "$package" >/dev/null 2>&1; then
            INSTALL_PACKAGES+=("$package")
        fi
    done
    if [ -n "${INSTALL_PACKAGES[*]}" ]; then
        info Installing packages "${INSTALL_PACKAGES[@]}"
        sudo zypper -n install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
    fi
}

get_flatpak_packages() {
    FLATPAK_PACKAGES+=(com.spotify.Client)
}

install_flatpak_packages() {
    # Add Flatpak repo
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo >/dev/null
    INSTALL_PACKAGES=()
    for package in "${FLATPAK_PACKAGES[@]}"; do
        if ! flatpak info "$package" >/dev/null 2>&1; then
            INSTALL_PACKAGES+=("$package")
        fi
    done
    if [ -n "${INSTALL_PACKAGES[*]}" ]; then
        info Installing packages "${INSTALL_PACKAGES[@]}"
        sudo flatpak -y install "${INSTALL_PACKAGES[@]}" >/dev/null || fail "Failed installing packages"
    fi
}

install_chrome() {
    if ! rpm -q google-chrome-stable >/dev/null 2>&1; then
        info Installing Google Chrome
        sudo zypper ar http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome >/dev/null
        sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub >/dev/null
        BACKUP_RPM_PACKAGES=("${RPM_PACKAGES[@]}")
        # Install build packages immediately
        RPM_PACKAGES=(google-chrome-stable)
        install_rpm_packages
        RPM_PACKAGES=("${BACKUP_RPM_PACKAGES[@]}")
    fi

}

configure_fonts() {
    if [ -f jetbrains-mono-font.sh ]; then
        ./jetbrains-mono-font.sh
    elif [ -f ./os-bootstraps/jetbrains-mono-font.sh ]; then
        ./os-bootstraps/jetbrains-mono-font.sh
    fi
}

passwordless_sudo() {
    if sudo [ ! -f /etc/sudoers.d/nopasswd-"$USER" ]; then
        echo "$USER"' ALL=(ALL:ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/nopasswd-"$USER"
    fi
}

ferdi() {
    FERDI_VERSION=5.5.0
    if ! rpm -q ferdi >/dev/null 2>&1; then
        info Installing Ferdi
        UPDATE_FERDI=true
    else
        CURRENT_FERDI_VERSION="$(rpm -q ferdi | sed 's/ferdi-//;s/\.x86_64//' | awk -F- '{print $1}' | xargs)"
        if [ "$CURRENT_FERDI_VERSION" != "$FERDI_VERSION" ]; then
            info "Updating Ferdi to $FERDI_VERSION (from $CURRENT_FERDI_VERSION)"
            UPDATE_FERDI=true
        fi
    fi
    if [ -n "$UPDATE_FERDI" ]; then
        # TODO - needs a lot of TLC
        FERDI_FILE=/tmp/ferdi-"$FERDI_VERSION".rpm
        FERDI_URL=https://github.com/getferdi/ferdi/releases/download/v"$FERDI_VERSION"/ferdi-"$FERDI_VERSION".x86_64.rpm
        if ! wget -O "$FERDI_FILE" "$FERDI_URL"; then
            FERDI_URL=https://github.com/getferdi/ferdi/releases/download/"$FERDI_VERSION"/ferdi-"$FERDI_VERSION".x86_64.rpm
            wget -O "$FERDI_FILE" "$FERDI_URL" || fail Could not download Ferdi
        fi
        sudo rpm -i --nodeps "$FERDI_FILE" || fail Could not install Ferdi
    fi
    if [ -f "$PWD/ferdi-shopping-list.sh" ]; then
        "$PWD/ferdi-shopping-list.sh"
    elif [ -f "$PWD/os-bootstraps/ferdi-shopping-list.sh" ]; then
        "$PWD/os-bootstraps/ferdi-shopping-list.sh"
    fi
}

vs_code() {
    if ! rpm -q code >/dev/null 2>&1; then
        info Installing VS Code
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc >/dev/null
        sudo zypper -n ar https://packages.microsoft.com/yumrepos/vscode vscode
        sudo zypper -n refresh
        RPM_PACKAGES+=(code)
    fi
}

ssh_configuration() {
    SSH_FILE="$HOME"/.config/autostart-scripts/ssh.sh
    if [ ! -f "$SSH_FILE" ]; then
        mkdir -p "$HOME"/.config/autostart-scripts/ || fail Cannot create ssh dir
        info Setting up ssh with ksshaskpass
        cat <<'EOF' | tee "$SSH_FILE" >/dev/null
#!/bin/bash
sleep 5
SSH_ASKPASS=/usr/libexec/ssh/ksshaskpass ssh-add "$HOME/.ssh/id_rsa" </dev/null
EOF
        chmod +x "$SSH_FILE"
    fi
    SSH_FILE="$HOME"/.config/plasma-workspace/env/ssh-agent-startup.sh
    if [ ! -f "$SSH_FILE" ]; then
        mkdir -p "$HOME"/.config/plasma-workspace/env || fail Cannot create ssh dir
        info Setting up ssh agent autostart
        cat <<'EOF' | tee "$SSH_FILE" >/dev/null
#!/bin/sh
[ -n "$SSH_AGENT_PID" ] || eval "$(ssh-agent -s)"
export SSH_ASKPASS=/usr/libexec/ssh/ksshaskpass
EOF
        chmod +x "$SSH_FILE"
    fi
}

main() {
    CALLBACKS+=(
        passwordless_sudo
        install_chrome
        vs_code
        configure_fonts
        ssh_configuration
        ferdi
    )
    get_rpm_packages
    get_flatpak_packages

    # If we're not being sourced
    # shellcheck disable=SC2154
    if [ -z "$_suse_bootstrap_mattsday" ]; then
        for callback in "${CALLBACKS[@]}"; do
            "$callback"
        done
        install_rpm_packages
        install_flatpak_packages
    fi
}

main "$@"