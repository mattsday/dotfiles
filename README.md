# Matt Day's dotfiles

## About

This repository contains the personal dotfiles for Matt Day. It provides a consistent shell experience across multiple operating systems and environments, and it automates the setup of new machines with essential tools and utilities.

The primary goal is to ensure compatibility and a similar look and feel across different shells, including bourne-compatible shells (ksh, bash, and zsh), csh, tcsh, and fish.

## Getting Started

To get started with these dotfiles, clone the repository and run the bootstrap script:

```bash
git clone "https://github.com/mattsday/dotfiles/" "$HOME/.dotfiles"
cd "$HOME/.dotfiles"
./bootstrap.sh
```

The `bootstrap.sh` script will automatically detect your operating system and install the appropriate software. It will also run the `init.sh` script to symlink the dotfiles into your home directory.

If you only want to deploy the dotfiles without installing any additional software, you can run the `init.sh` script directly:

```bash
./init.sh
```

## Features

*   **Cross-shell compatibility:** A consistent experience across bourne-compatible shells, csh, tcsh, and fish.
*   **Sensible defaults:** A set of sane defaults for various tools and utilities.
*   **Aliases:** A collection of useful aliases for common commands.
*   **Customizable:** Easily extendable with local customizations.
*   **Automated setup:** Bootstrap scripts for setting up new machines.

### Shell Configuration

*   **`shell_common`:** A bourne-compatible script that loads most of the common shell settings.
*   **`alias_list`:** A script for managing aliases across both bourne and csh-compatible shells.
*   **Local customizations:** Create a `dotfile_local` file (e.g., `zsh_local`, `shell_common_local`) to add your own local customizations. These files will be sourced at the end of the main configuration files.

### Tool Configuration

This repository also includes configuration files for a variety of tools, including:

*   Vim
*   Neovim
*   Mutt
*   Git
*   Terminus
*   VS Code
*   Firefox
*   PipeWire

## Supported Operating Systems

The bootstrap scripts can set up the following operating systems:

*   Debian-based distributions (e.g., Debian, Ubuntu)
*   Red Hat-based distributions (e.g., CentOS, Fedora, RHEL)
*   SUSE-based distributions (e.g., openSUSE)
*   Arch-based distributions (e.g., Arch Linux, Manjaro)
*   FreeBSD
*   macOS
*   Windows Subsystem for Linux (WSL)

## Customization

To add your own local customizations, you can create a `_local` file for the corresponding dotfile. For example, to add local aliases, you can create a `~/.shell_common_local` file. These local files will be sourced at the end of the main configuration files, allowing you to override or extend the default settings.

## Additional Scripts

The `os-bootstraps` directory contains several scripts for setting up specific applications and environments. These scripts are typically called by the main `bootstrap.sh` script, but they can also be run manually.

*   **`brave.sh`**: Installs the Brave browser.
*   **`bruschetta-bootstrap.sh`**: Sets up the Bruschetta environment.
*   **`chromebook.sh`**: Sets up a Chromebook.
*   **`docker.sh`**: Installs Docker.
*   **`ferdi-anylist.sh`**: Sets up Ferdi for AnyList.
*   **`ferdi-shopping-list.sh`**: Sets up Ferdi for a shopping list.
*   **`git.sh`**: Configures Git.
*   **`jetbrains-mono-font.sh`**: Installs the JetBrains Mono font.
*   **`kde-desktop.sh`**: Sets up a KDE desktop environment.
*   **`kubectx.sh`**: Installs kubectx and kubens.
*   **`linux-emoji.sh`**: Installs emoji fonts on Linux.
*   **`passwordless-sudo.sh`**: Configures passwordless sudo.
*   **`pipewire.sh`**: Installs and configures PipeWire.
*   **`rodete-bootstrap.sh`**: Sets up the Rodete environment.
*   **`sdkman.sh`**: Installs SDKMAN!.
*   **`spotify.sh`**: Installs Spotify.
*   **`syncthing.sh`**: Installs and configures Syncthing.
*   **`trillian-bootstrap.sh`**: Sets up the Trillian client.
*   **`wsl.sh`**: Sets up Windows Subsystem for Linux.
*   **`zsh.sh`**: Installs and configures Zsh.
