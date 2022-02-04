#!/bin/zsh
# Bootstrap some zsh plugins and features

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

install_autosuggestions() {
    if [[ ! -d "${HOME}/.zsh-autosuggestions" ]]; then
        info Installing zsh autosuggestions
        git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.zsh-autosuggestions" || error Could not clone repo https://github.com/zsh-users/zsh-autosuggestions
        info Done
    fi
}

main() {
    # Check if git is installed
    check_cmd git
    # Now install stuff
    install_autosuggestions
}

main
