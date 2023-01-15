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

# Only run on CentOS/RHEL and derivatives
if [[ -f /etc/os-release ]]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -d = -f 2 | sed 's/"//g')"
	case "${RELEASE}" in
	centos*)
		info Detected CentOS
		;;
	rhel*)
		info Detected Red Hat

		;;
	fedora*)
		info Detected Fedora
		;;
	*)
		error Cannot detect supported OS, stopping
		;;
	esac
else
	error Cannot detect OS, stopping
fi

package_mgr=dnf

if [[ ! -x "/usr/bin/dnf" ]]; then
	if [[ ! -x "/usr/bin/yum" ]]; then
		error Cannot find dnf or yum, stopping
	else
		info "Setting package manager to yum"
		package_mgr=yum
	fi
else
	info "Setting package manager to dnf"
fi

# Check if sudo is installed
if [[ ! -x /usr/bin/sudo ]]; then
	if command -v id >/dev/null 2>&1; then
		if [[ "$(id -u)" = 0 ]]; then
			info Installing sudo
			${package_mgr} install -y sudo >/dev/null
		else
			error "User is not root and sudo isn't installed. Install sudo first"
		fi
	fi
fi

info Updating system
sudo "${package_mgr}" -y update >/dev/null

# Get list of installed apps
installed=$(yum list installed | cut -d ' ' -f 1 | cut -d '.' -f 1)

list="
zsh
vim-enhanced
findutils
git
wget
xz
zip
centos
findutils
hostname
"
for utility in ${list}; do
	exists="$(echo "${installed}" | tr " " "\\n" | grep -wx "${utility}")"
	if [[ -z "${exists}" ]]; then
		info Installing "${utility}"
		sudo "${package_mgr}" -y install "${utility}" >/dev/null
	fi
done
