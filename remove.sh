#!/bin/sh
# shellcheck disable=SC1091

if [ -z "${DOTFILES_ROOT}" ]; then
	if command -v basename >/dev/null 2>&1; then
		DOTFILES_ROOT="$(dirname "$0")"
		if command -v realpath >/dev/null 2>&1; then
			DOTFILES_ROOT="$(realpath "${DOTFILES_ROOT}")"
		fi
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

echo Done
