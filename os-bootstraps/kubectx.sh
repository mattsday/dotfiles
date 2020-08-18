#!/bin/bash

KUBECTX_VERSION=v0.9.1
KUBECTX_URL=(https://github.com/ahmetb/kubectx/releases/download/"$KUBECTX_VERSION"/kubectx https://github.com/ahmetb/kubectx/releases/download/"$KUBECTX_VERSION"/kubens)
KUBECTX_ZSH_COMPLETION=(https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh)
KUBECTX_BASH_COMPLETION=(https://github.com/ahmetb/kubectx/blob/master/completion/kubectx.bash https://github.com/ahmetb/kubectx/blob/master/completion/kubens.bash)
ZSH_COMPLETION_DIR=/usr/share/zsh/vendor-completions

fail() {
    echo "$@"
    exit 1
}

for url in "${KUBECTX_URL[@]}"; do
    filename="$(basename "$url" | xargs)"
    curl -sL --fail "$url" | sudo tee /usr/local/bin/"$filename" >/dev/null || fail Download failed
    sudo chmod +x /usr/local/bin/"$filename" || fail Chmodding "$filename" failed
done

if [ ! -d "$ZSH_COMPLETION_DIR" ]; then
    sudo mkdir -p "$ZSH_COMPLETION_DIR" || fail Cannot create "$ZSH_COMPLETION_DIR"
fi

for completion in "${KUBECTX_ZSH_COMPLETION[@]}"; do
    filename="$(basename "$completion" | xargs)"
    curl -sL --fail "$url" | sudo tee "$ZSH_COMPLETION_DIR"/_"$filename" >/dev/null || fail Download failed
done