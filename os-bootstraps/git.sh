#!/bin/bash

if [[ -z "${DOTFILES_ROOT}" ]]; then
    if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
        DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
    elif command -v dirname >/dev/null 2>&1; then
        DOTFILES_ROOT="$(cd "$(dirname "$0")" || return; pwd)"
	else
        echo >&2 '[Error] cannot determine root (try running from working directory)'
        exit 1
    fi
fi

# Load common settings and functions
. "${DOTFILES_ROOT}/common.sh"

[[ -z "${GIT_USER}" ]] && GIT_USER="Matt Day"
[[ -z "${GIT_EMAIL}" ]] && GIT_EMAIL="mattsday@gmail.com"

if ! command -v git >/dev/null 2>&1; then
    error Git not installed
fi

if ! git config --global user.name >/dev/null 2>&1; then
    info Setting git config --global user.name to "${GIT_USER}"
    git config --global user.name "${GIT_USER}"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    info Setting git config --global user.email to "${GIT_EMAIL}"
    git config --global user.email "${GIT_EMAIL}"
fi

if ! git config --global init.defaultBranch >/dev/null 2>&1; then
    info Setting default git branch to main
    git config --global init.defaultBranch main
fi
