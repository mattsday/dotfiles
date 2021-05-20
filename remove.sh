#!/bin/sh
# shellcheck disable=SC1091

if [ -z "${DOTFILES_ROOT}" ]; then
	if command -v dirname >/dev/null 2>&1 && command -v realpath >/dev/null 2>&1; then
		DOTFILES_ROOT="$(realpath "$(dirname "$0")")"
	else
		DOTFILES_ROOT="${PWD}"
	fi
fi
echo Removing dotfiles

# Load dependencies
. "${DOTFILES_ROOT}"/dotfiles/dependencies

# Figure out what we've got linked
# shellcheck disable=SC2154
for i in ${dotfiles}; do
	dotfile="$(basename "${i}")"
	file="${HOME}/.${dotfile}"
	if [ -L "${file}" ]; then
		echo Removing "${file}"
		rm "${file}"
	fi
	BACKUP="${DOTFILES_ROOT}/backup/local-${dotfile}"
	if [ -f "${BACKUP}" ]; then
		echo Restoring "${file}" from backup
		mv "${BACKUP}" "${file}"
	fi
done

# shellcheck disable=SC2154
for dotfile in ${extra}; do
	file="${dotfile}"
	if [ -L "${file}" ]; then
		echo Removing "${file}"
		rm "${file}"
	fi
	BACKUP="${DOTFILES_ROOT}/backup/local-$(basename "${dotfile}" | xargs)"
	if [ -f "${BACKUP}" ]; then
		echo Restoring "${dotfile}" from backup
		mv "${BACKUP}" "${file}"
	fi
done

if [ -L "${USER_CHROME}" ]; then
	echo Removing "${USER_CHROME}"
	rm "${USER_CHROME}"
	if [ -f "${DOTFILES_ROOT}/backup/local-userChrome.css" ]; then
		echo Restoring "${USER_CHROME}" from backup
		mv "${DOTFILES_ROOT}/backup/local-userChrome.css" "${USER_CHROME}"
	elif [ -f "${DOTFILES_ROOT}/backup/userChrome.css" ]; then
		echo Restoring "${USER_CHROME}" from backup
		mv "${DOTFILES_ROOT}/backup/userChrome.css" "${USER_CHROME}"
	fi
fi

if [ -L "${PIPEWIRE_CONFIG_ALSA_PATH}" ]; then
	echo Removing "${PIPEWIRE_CONFIG_ALSA_PATH}"
	rm "${PIPEWIRE_CONFIG_ALSA_PATH}"
	if [ -f "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_ALSA}" ]; then
		echo Restoring "${PIPEWIRE_CONFIG_ALSA_PATH}" from backup
		mv "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_ALSA}" "${PIPEWIRE_CONFIG_ALSA_PATH}"
	fi
fi

if [ -L "${PIPEWIRE_CONFIG_BLUEZ_PATH}" ]; then
	echo Removing "${PIPEWIRE_CONFIG_BLUEZ_PATH}"
	rm "${PIPEWIRE_CONFIG_BLUEZ_PATH}"
	if [ -f "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_BLUEZ}" ]; then
		echo Restoring "${PIPEWIRE_CONFIG_BLUEZ_PATH}" from backup
		mv "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_BLUEZ}" "${PIPEWIRE_CONFIG_BLUEZ_PATH}"
	fi
fi

echo Done
