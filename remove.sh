#!/bin/bash

echo Removing dotfiles

# Load dependencies
. ./dependencies

# Figure out what we've got linked
for dotfile in ${dotfiles}; do
	FILE="$HOME/.${dotfile}"
	if [ -L "${FILE}" ]; then
		echo Removing "${FILE}"
		rm "${FILE}"
	fi
	BACKUP="$PWD/backup/local-$dotfile"
	if [ -f "${BACKUP}" ]; then
		echo Restoring backup from "${BACKUP}"
		mv "${BACKUP}" "${FILE}"
	fi
done

for dotfile in ${extra}; do
	FILE="${dotfile}"
	if [ -L "${FILE}" ]; then
        echo Removing "${FILE}"
		rm "${FILE}"
    fi
	BACKUP="$PWD/backup/local-$(basename "${dotfile}" | xargs)"
	if [ -f "${BACKUP}" ]; then
		echo Restoring "${dotfile}" from backup
		mv "${BACKUP}" "${FILE}"
	fi
done

if [ -L "${USER_CHROME}" ]; then
	echo Removing "${USER_CHROME}"
	rm "${USER_CHROME}"
	if [ -f "${PWD}/backup/local-userChrome.css" ]; then
		echo Restoring "${USER_CHROME}" from backup
		mv "${PWD}/backup/local-userChrome.css" "${USER_CHROME}"
	elif [ -f "${PWD}/backup/userChrome.css" ]; then
		echo Restoring "${USER_CHROME}" from backup
		mv "${PWD}/backup/userChrome.css" "${USER_CHROME}"
	fi
fi

VS_SETTINGS="$VS_DIR/settings.json"
if [ -L "${VS_SETTINGS}" ]; then
	echo Removing "${VS_SETTINGS}"
	rm "${VS_SETTINGS}"
	if [ -f "${PWD}/backup/local-settings.json" ]; then
		echo Restoring "$VS_SETTINGS" from backup
		mv "backup/local-settings.json" "$VS_SETTINGS"
	fi
fi

echo Done

