#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...
# shellcheck disable=SC1091

if [ -z "${DOTFILES_ROOT}" ]; then
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

# Load dependencies
. "${DOTFILES_ROOT}"/dotfiles/dependencies

# Load common functions
. "${DOTFILES_ROOT}"/common.sh

# Allow manually disabling sudo for aliases etc
if [ "${NO_SUDO}" = 1 ]; then
	info Disabling sudo aliases
	touch "${HOME}/.disable_dotfiles_sudo"
elif [ "${NO_SUDO}" = 0 ]; then
	info Enabling sudo aliases
	rm "${HOME}/.disable_dotfiles_sudo"
elif [ -f "${HOME}/.disable_dotfiles_sudo" ]; then
	info Sudo aliases disabled - run this script with NO_SUDO=0 to re-enable
fi

mkdir "${DOTFILES_ROOT}"/backup >/dev/null 2>&1

# shellcheck disable=SC2154
for i in ${dotfiles}; do
	verb=Updating
	dotfile="$(basename "${i}")"
	if [ -f "${HOME}/.${dotfile}" ] && [ ! -L "${HOME}/.${dotfile}" ]; then
		info Backing up local ."${dotfile}" to "${DOTFILES_ROOT}/backup/local-${dotfile}"
		mv -f "${HOME}/.${dotfile}" "${DOTFILES_ROOT}/backup/local-${dotfile}"
		verb="Creating"
	elif [ ! -f "${HOME}/.${dotfile}" ]; then
		verb="Creating"
	fi
	info "${verb} ${HOME}/.${dotfile}"
	ln -fs "${i}" "${HOME}/.${dotfile}"
done

# shellcheck disable=SC2154
for i in ${configdirs}; do
	verb=Updating
	destination_dir="${HOME}"/.config/"$(basename "${i}")"
	if [ -d "${i}" ]; then
		if [ ! -d "${destination_dir}" ]; then
			mkdir -p "${destination_dir}" || warn Failed to create dir "${destination_dir}"
		fi
		for j in "${i}"/*; do
			destination_file="${destination_dir}"/"$(basename "${j}")"
			if [ -f "${destination_file}" ] && [ ! -L "${destination_file}" ]; then
				info Backing up local "${destination_file}" to "${DOTFILES_ROOT}/backup/local-$(basename "${j}")"
				mv -f "${destination_file}" "${DOTFILES_ROOT}/backup/local-$(basename "${j}")"
				verb="Creating"
			elif [ ! -f "${destination_file}" ]; then
				verb="Creating"
			fi
			info "${verb} ${destination_file}"
			ln -fs "${j}" "${destination_file}"
		done
	fi
done

# Add nvim config file (same as vimrc):
verb=Updating
if [ ! -d "${HOME}/.config/nvim" ]; then
	mkdir -p "${HOME}/.config/nvim"
	verb=Creating
elif [ -f "${HOME}/.config/nvim/init.vim" ] && [ ! -L "${HOME}/.config/nvim/init.vim" ]; then
	info "Backing local nvim config to ${DOTFILES_ROOT}/backup/local-init.vim"
	mv -f "${HOME}/.config/nvim/init.vim" "${DOTFILES_ROOT}/backup/local-init.vim"
	verb=Creating
elif [ ! -f "${HOME}/.config/nvim/init.vim" ]; then
	verb=Creating
fi
info "${verb} ${HOME}/.config/nvim/init.vim"
ln -fs "${DOTFILES_ROOT}/dotfiles/home/vimrc" "${HOME}/.config/nvim/init.vim"

verb=Updating
if [ -f "${FF_PROFILE_INI}" ] && [ -d "${FF_PROFILE_PATH}" ]; then
	if [ ! -d "${FF_PROFILE_PATH}/chrome" ]; then
		mkdir -p "${FF_PROFILE_PATH}/chrome"
		verb=Creating
	fi
	if [ -f "${USER_CHROME}" ] && [ ! -L "${USER_CHROME}" ]; then
		info Backing up local "${USER_CHROME}" to "${DOTFILES_ROOT}/backup/userChrome.css"
		mv "${USER_CHROME}" "${DOTFILES_ROOT}/backup/local-userChrome.css"
		verb=Creating
	fi
	if [ ! -f "${USER_CHROME}" ]; then
		verb=Creating
	fi
	info "${verb}" "${USER_CHROME}"
	ln -fs "${LOCAL_CHROME}" "${USER_CHROME}"
fi

# Add local pipewire configuration
if command -v pipewire-pulse >/dev/null 2>&1; then

	alsa_verb=Updating
	bluez_verb=Updating
	if [ ! -d "${PIPEWIRE_CONFIG_DIR}" ]; then
		mkdir -p "${PIPEWIRE_CONFIG_DIR}"
		alsa_verb=Creating
		bluez_verb=Creating
	elif [ -f "${PIPEWIRE_CONFIG_ALSA_PATH}" ] || [ -f "${PIPEWIRE_CONFIG_BLUEZ_PATH}" ]; then
		if [ ! -L "${PIPEWIRE_CONFIG_ALSA_PATH}" ]; then
			info "Backing local pipewire alsa config to ${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_ALSA}"
			mv -f "${PIPEWIRE_CONFIG_ALSA_PATH}" "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_ALSA}"
			alsa_verb=Creating
		fi
		if [ ! -L "${PIPEWIRE_CONFIG_BLUEZ_PATH}" ]; then
			info "Backing local pipewire bluez config to ${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_BLUEZ}"
			mv -f "${PIPEWIRE_CONFIG_BLUEZ_PATH}" "${DOTFILES_ROOT}/backup/local-${PIPEWIRE_CONFIG_BLUEZ}"
			bluez_verb=Creating
		fi
	else
		alsa_verb=Creating
		bluez_verb=Creating
	fi
	info "${alsa_verb} ${PIPEWIRE_CONFIG_ALSA_PATH}"
	ln -fs "${DOTFILES_ROOT}/dotfiles/special/pipewire/${PIPEWIRE_CONFIG_ALSA}" "${PIPEWIRE_CONFIG_ALSA_PATH}"
	info "${bluez_verb} ${PIPEWIRE_CONFIG_BLUEZ_PATH}"
	ln -fs "${DOTFILES_ROOT}/dotfiles/special/pipewire/${PIPEWIRE_CONFIG_BLUEZ}" "${PIPEWIRE_CONFIG_BLUEZ_PATH}"

	# Skip for now - this is causing problems
	wireplumber_verb=Updating
	if [ ! -d "${WIREPLUMBER_CONFIG_DIR}" ]; then
		# mkdir -p "${WIREPLUMBER_CONFIG_DIR}"
		wireplumber_verb=Creating
	elif [ -f "${WIREPLUMBER_CONFIG_ALSA_PATH}" ]; then
		if [ ! -L "${WIREPLUMBER_CONFIG_ALSA_PATH}" ]; then
			info Backing up local wireplumber config to "${DOTFILES_ROOT}/backup/local-${WIREPLUMBER_CONFIG_ALSA}"
			#mv -f "${WIREPLUMBER_CONFIG_ALSA_PATH}" "${DOTFILES_ROOT}/backup/local-${WIREPLUMBER_CONFIG_ALSA}"
			wireplumber_verb=Creating
		fi
	else
		wireplumber_verb=Creating
	fi
	info "${wireplumber_verb} ${WIREPLUMBER_CONFIG_ALSA_PATH}"
	#ln -fs "${DOTFILES_ROOT}/dotfiles/special/pipewire/${WIREPLUMBER_CONFIG_ALSA}" "${WIREPLUMBER_CONFIG_ALSA_PATH}"
fi

VS_SETTINGS="${VS_DIR}/settings.json"

# Remove VS code settings symlink if it exists and use built-in config sync
if [ -L "${VS_SETTINGS}" ]; then
	info Unlinking "${VS_SETTINGS}"
	ORIG_VS_SETTINGS="$(readlink "${VS_SETTINGS}")"
	if [ -L "${ORIG_VS_SETTINGS}" ]; then
		warn Cannot move VS code settings as "${ORIG_VS_SETTINGS}" is a symlink
	else
		rm "${VS_SETTINGS}" || warn Cannot remove VS Code settings
		cp "${ORIG_VS_SETTINGS}" "${VS_SETTINGS}" || warn Cannot copy "${ORIG_VS_SETTINGS}" to "${VS_SETTINGS}"
	fi
fi

sh "${HOME}"/.update_aliases force
info Done.
