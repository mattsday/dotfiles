#!/bin/sh

KUBECTX_VERSION=v0.9.1
KUBECTX_URL="https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubectx https://github.com/ahmetb/kubectx/releases/download/$KUBECTX_VERSION/kubens"
KUBECTX_ZSH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.zsh https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.zsh"
KUBECTX_BASH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.bash https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.bash"
KUBECTX_FISH_COMPLETION="https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubectx.fish https://raw.githubusercontent.com/ahmetb/kubectx/master/completion/kubens.fish"
ZSH_COMPLETION_DIR=/usr/share/zsh/vendor-completions
FISH_COMPLETION_DIR="$HOME/.config/fish/completions"
if command -v pkg-config >/dev/null 2>&1; then
    BASH_COMPLETION_DIR="$(pkg-config --variable=completionsdir bash-completion)"
elif [ -d /usr/local/etc/bash_completion.d ]; then
    BASH_COMPLETION_DIR=/usr/local/etc/bash_completion.d/
else
    BASH_COMPLETION_DIR=/etc/bash_completion.d
fi

fail() {
    echo "$@"
    exit 1
}

if [ ! -d "$BASH_COMPLETION_DIR" ]; then
    sudo mkdir -p "$BASH_COMPLETION_DIR" || fail Could not create "$BASH_COMPLETION_DIR" 
fi

for url in $KUBECTX_URL; do
    filename="$(basename "$url" | xargs)"
    curl -sL --fail "$url" | sudo tee /usr/local/bin/"$filename" >/dev/null || fail Download failed
    sudo chmod +x /usr/local/bin/"$filename" || fail Chmodding "$filename" failed
done

if [ ! -d "$ZSH_COMPLETION_DIR" ]; then
    sudo mkdir -p "$ZSH_COMPLETION_DIR" || fail Cannot create "$ZSH_COMPLETION_DIR"
fi

if [ ! -d "$BASH_COMPLETION_DIR" ]; then
    sudo mkdir -p "$BASH_COMPLETION_DIR" || fail Cannot create "$BASH_COMPLETION_DIR"
fi

if [ ! -d "$FISH_COMPLETION_DIR" ]; then
    mkdir -p "$FISH_COMPLETION_DIR" || fail Cannot create "$FISH_COMPLETION_DIR"
fi

for url in $KUBECTX_ZSH_COMPLETION; do
    filename="$ZSH_COMPLETION_DIR"/_"$(basename "$url" | xargs)"
    if [ -f "$filename" ]; then
        sudo rm "$filename" || fail Cannot remove "$filename"
    fi
    curl -sL --fail "$url" | sudo tee "$filename" >/dev/null || fail Download failed for "$url"
done

for url in $KUBECTX_BASH_COMPLETION; do
    filename="$BASH_COMPLETION_DIR"/"$(basename "$url" | xargs | awk -F. '{print $1}')"
    if [ -f "$filename" ]; then
        sudo rm "$filename" || fail Cannot remove "$filename"
    fi
    curl -sL --fail "$url" | sudo tee "$filename" >/dev/null || fail Download failed for "$url"
done

for url in $KUBECTX_FISH_COMPLETION; do
    filename="$FISH_COMPLETION_DIR"/"$(basename "$url" | xargs)"
    if [ -f "$filename" ]; then
        rm "$filename" || fail Cannot remove "$filename"
    fi
    curl -sL --fail "$url" | tee "$filename" >/dev/null || fail Download failed for "$url"
done
