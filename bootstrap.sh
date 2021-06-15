#!/bin/sh

if [ -z "${DOTFILES_ROOT}" ]; then
	if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
		DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
	else
		DOTFILES_ROOT="${PWD}"
	fi
fi
export DOTFILES_ROOT

# Load common settings
. "${DOTFILES_ROOT}"/common.sh

if [ -f "${DOTFILES_ROOT}"/init.sh ]; then
	"${DOTFILES_ROOT}"/init.sh
fi

_bootstrap_mattsday=1
export _bootstrap_mattsday

if [ -f "/etc/os-release" ]; then
	RELEASE="$(grep '^ID=' /etc/os-release | cut -f 2 -d = | sed 's/"//g')"
	RELEASE_LIKE="$(grep '^ID_LIKE=' /etc/os-release | cut -f 2 -d = | sed 's/"//g')"

	if [ "${RELEASE}" = debian ] || [ "${RELEASE_LIKE}" = debian ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/debian-bootstrap.sh ]; then
			info Detected Debian flavoured
			"${DOTFILES_ROOT}"/os-bootstraps/debian-bootstrap.sh
		fi
	elif [ "${RELEASE}" = centos ] || [ "${RELEASE}" = rhel ] || [ "${RELEASE}" = fedora ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/centos-bootstrap.sh ]; then
			info Detected Red Hat flavoured
			"${DOTFILES_ROOT}"/bootstraps"${DOTFILES_ROOT}"/centos-bootstrap.sh
		fi
	elif [ "${RELEASE}" = suse ] || [ "${RELEASE}" = opensuse ] || [ "${RELEASE}" = "opensuse-tumbleweed" ] || [ "${RELEASE}" = "opensuse-leap" ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/suse-bootstrap.sh ]; then
			info Detected SuSE flavoured
			"${DOTFILES_ROOT}"/os-bootstraps/suse-bootstrap.sh
		fi
	elif [ "${RELEASE}" = arch ] || [ "${RELEASE}" = manjaro ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/arch-bootstrap.sh ]; then
			info Detected Arch flavoured
			"${DOTFILES_ROOT}"/os-bootstraps/arch-bootstrap.sh
		fi
	elif [ "${RELEASE}" = freebsd ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/arch-bootstrap.sh ]; then
			info Detected FreeBSD
			"${DOTFILES_ROOT}"/os-bootstraps/freebsd-bootstrap.sh
		fi
	fi
else
	# Check if we're running OS X
	SYSTEM="$(uname)"
	if [ "${SYSTEM}" = Darwin ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/mac-bootstrap.sh ]; then
			info Detected Mac OS X
			"${DOTFILES_ROOT}"/os-bootstraps/mac-bootstrap.sh
		fi
	elif [ "${SYSTEM}" = FreeBSD ]; then
		if [ -f "${DOTFILES_ROOT}"/os-bootstraps/freebsd-bootstrap.sh ]; then
			info Detected FreeBSD
			"${DOTFILES_ROOT}"/os-bootstraps/freebsd-bootstrap.sh
		fi
	fi
fi

if command -v git >/dev/null 2>&1; then
    if [ -x "${DOTFILES_ROOT}/os-bootstraps/git.sh" ]; then
        "${DOTFILES_ROOT}/os-bootstraps/git.sh"
    fi
fi

if [ -x "${HOME}/.update_aliases" ]; then
	"${HOME}/.update_aliases" force
fi
