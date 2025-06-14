#!/bin/bash
# Bootstrap Windows environments

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

symlinks() {
  if [[ ! -L "${HOME}/winhome" ]]; then
    info Setting up symlinks
    users=("Matt" "Matt Day")
    for u in "${users[@]}"; do
      if [[ -d "/mnt/c/Users/${u}" ]]; then
        user="${u}"
        home="/mnt/c/Users/${u}"
      fi
    done
    if [[ -z "${home}" ]]; then
      error "Cannot locate home directory in" "${users[@]}"
    fi
    ln -fs "${home}" "${HOME}/winhome"
  fi
}

# Install Powershell files
powershell() {
  if [[ ! -d "${HOME}/winhome" ]]; then
    echo No windows home dir found
    return
  fi
  info Setting up Powershell
  mkdir -p "${HOME}/winhome/Documents/Powershell"
  cp "${DOTFILES_ROOT}/dotfiles/special/powershell/profile.ps1" "${HOME}/winhome/Documents/Powershell/profile.ps1"
}

main() {
  CALLBACKS+=(
    symlinks
    powershell
  )

  # If we're not being sourced
  # shellcheck disable=SC2154
  if [[ -z "${_debian_bootstrap_mattsday}" ]]; then
    for callback in "${CALLBACKS[@]}"; do
      "${callback}"
    done
  fi
}

main "$@"
