#!/bin/sh

if [ -z "${DOTFILES_ROOT}" ]; then
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

[ -z "${KUBECTX_VERSION}" ] && KUBECTX_VERSION=v0.9.4
[ -z "${KUBECTX_ARCH}" ] && KUBECTX_ARCH=linux_x86_64
[ -z "${TMP_DIR}" ] && TMP_DIR=/tmp
[ -z "${KUBECTX_PREFIX}" ] && KUBECTX_PREFIX=/usr/local/bin

if [ -z "${KUBECTX_FORCE}" ] && command -v kubectx >/dev/null 2>&1 && command -v kubens >/dev/null 2>&1; then
    info Kubectx and Kubens already installed, set KUBECTX_FORCE=1 to force
    exit 0
fi

KUBECTX_FILE=kubectx_"${KUBECTX_VERSION}"_"${KUBECTX_ARCH}".tar.gz
KUBENS_FILE=kubens_"${KUBECTX_VERSION}"_"${KUBECTX_ARCH}".tar.gz

KUBECTX_BASE_URL="https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}"

KUBECTX_ZSH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh"
KUBECTX_BASH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash"
KUBECTX_FISH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.fish https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.fish"

ZSH_COMPLETION_DIR=/usr/share/zsh/vendor-completions
FISH_COMPLETION_DIR="${HOME}/.config/fish/completions"

if command -v pkg-config >/dev/null 2>&1; then
    BASH_COMPLETION_DIR="$(pkg-config --variable=completionsdir bash-completion)"
elif [ -d /usr/local/etc/bash_completion.d ]; then
    BASH_COMPLETION_DIR=/usr/local/etc/bash_completion.d/
else
    BASH_COMPLETION_DIR=/etc/bash_completion.d
fi

download() {
    filename="$1"
    output_file="$2"
    if [ -z "${output_file}" ] || [ -z "${filename}" ]; then
        error Files not found
    fi
    downloaded_file="${TMP_DIR}/$1"

    url="${KUBECTX_BASE_URL}/${filename}"
    if [ -f "${downloaded_file}" ]; then
        rm "${downloaded_file}" || error "${downloaded_file}" exists and could not be deleted
    fi
    curl -sL --fail "${url}" -o "${downloaded_file}" || error Download of "${url}" failed
    if [ ! -f "${downloaded_file}" ]; then
        error "Download failed (not found in ${downloaded_file})"
    fi
    tar zxvf "${downloaded_file}" -C "${TMP_DIR}" >/dev/null 2>&1 || error Could not extract "${downloaded_file}"
    if [ -f "${TMP_DIR}/${output_file}" ]; then
        sudo mv "${TMP_DIR}/${output_file}" "${KUBECTX_PREFIX}"
    else
        error Could not download "${output_file}"
    fi
}

download "${KUBECTX_FILE}" kubectx
download "${KUBENS_FILE}" kubens

if [ ! -d "${BASH_COMPLETION_DIR}" ]; then
    sudo mkdir -p "${BASH_COMPLETION_DIR}" || error Could not create "${BASH_COMPLETION_DIR}"
fi

if [ ! -d "${ZSH_COMPLETION_DIR}" ]; then
    sudo mkdir -p "${ZSH_COMPLETION_DIR}" || error Cannot create "${ZSH_COMPLETION_DIR}"
fi

if [ ! -d "${BASH_COMPLETION_DIR}" ]; then
    sudo mkdir -p "${BASH_COMPLETION_DIR}" || error Cannot create "${BASH_COMPLETION_DIR}"
fi

if [ ! -d "${FISH_COMPLETION_DIR}" ]; then
    mkdir -p "${FISH_COMPLETION_DIR}" || error Cannot create "${FISH_COMPLETION_DIR}"
fi

for url in ${KUBECTX_ZSH_COMPLETION}; do
    filename="${ZSH_COMPLETION_DIR}"/_"$(basename "${url}" | xargs)"
    if [ -f "${filename}" ]; then
        sudo rm "${filename}" || error Cannot remove "${filename}"
    fi
    curl -sL --fail "${url}" | sudo tee "${filename}" >/dev/null || error Download failed for "${url}"
done

for url in ${KUBECTX_BASH_COMPLETION}; do
    filename="${BASH_COMPLETION_DIR}"/"$(basename "${url}" | xargs | cut -d '.' -f 1)"
    if [ -f "${filename}" ]; then
        sudo rm "${filename}" || error Cannot remove "${filename}"
    fi
    curl -sL --fail "${url}" | sudo tee "${filename}" >/dev/null || error Download failed for "${url}"
done

for url in ${KUBECTX_FISH_COMPLETION}; do
    filename="${FISH_COMPLETION_DIR}"/"$(basename "${url}" | xargs)"
    if [ -f "${filename}" ]; then
        rm "${filename}" || warn Cannot remove "${filename}"
    fi
    curl -sL --fail "${url}" | tee "${filename}" >/dev/null || error Download failed for "${url}"
done
