#!/bin/sh
# This should execute on pretty much any bourne shell in case the plan is to jump to zsh or tcsh asap...

# horrible but I want it over multiple lines and usable by standard shells...
dotfiles="
alias_list
zshrc
cshrc
tcsh_settings
vimrc
bashrc
vimrc
kshrc
muttrc
screenrc
profile
tmux.conf
shell_common
gitconfig
bash_profile
proxy_settings
proxy_settings_csh
"

mkdir backup > /dev/null 2>&1

for dotfile in $dotfiles; do
	if [ -f "$HOME/.$dotfile" ] && [ ! -L "$HOME/.$dotfile" ]; then
		echo Backing up local "$dotfile"
		mv -f "$HOME/.$dotfile" "backup/local-$dotfile"
	fi
	echo "Creating $HOME/.$dotfile"
	ln -fs "$PWD/$dotfile" "$HOME/.$dotfile"
done

# Add ssh config file:
if [ -d "$HOME/.ssh" ]; then
	if [ -f "$HOME/.ssh/config" ] && [ ! -L "$HOME/.ssh/config" ]; then
		echo Backing up old ssh config
		mv -f "$HOME/.ssh/config" "backup/local-ssh-config"
	fi
	echo "Creating $HOME/.ssh/config"
	ln -fs "$PWD/ssh_config" "$HOME/.ssh/config"
	chmod 600 "$HOME/.ssh/config"
fi

# Add nvim config file (same as vimrc):
if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME/.config/nvim"
fi
ln -fs "$PWD/vimrc" "$HOME/.config/nvim/init.vim"

echo Setting up aliases

SH_ALIAS_FILE="$HOME/.aliases"
CSH_ALIAS_FILE="$HOME/.csh_aliases"

rm $SH_ALIAS_FILE >/dev/null 2>&1
rm $CSH_ALIAS_FILE >/dev/null 2>&1

add_alias() {
	IFS='@'
	for alias in $1; do
		alias_name=`echo $alias | awk -F= '{print $1}' | xargs`
		alias_data=`echo $alias | awk -F= '{print $2}'`
		echo alias $alias_name=\'$alias_data\' >> $SH_ALIAS_FILE
		echo alias $alias_name \'$alias_data\' >> $CSH_ALIAS_FILE
	done
}

add_export() {
	IFS='@'
	for export in $1; do
		export_name=`echo $export | awk -F= '{print $1}' | xargs`
		export_data=`echo $export | awk -F= '{print $2}' | xargs`
		echo $export_name=\'$export_data\' >> $SH_ALIAS_FILE
		echo export $export_name >> $SH_ALIAS_FILE
		echo setenv $export_name \'$export_data\' >> $CSH_ALIAS_FILE
		#export $export_name=$export_data
	done
}

while IFS='' read -r line || [ -n "$line" ]; do
	case $line in
		# Ignore comments
		'#'*)
			;;
		# Check for executables
		'alias @'*|'export @'*)
			# Get the list of command_list to test
			command_list=`echo $line | awk '{print $2}' | sed 's/^@//'`
			IFS=,
			execute=1
			for command in $command_list; do
				case $command in
					# If it's an absolute path just test if it is executable
					*\/*)
						if [ ! -x "$command" ]; then
							execute=0
							break
						fi
						;;
					# Otherwise search the path for it
					*)
						if ! command -v $command >/dev/null 2>&1; then
							execute=0
							break
						fi
				esac
			done
			IFS=''
			if [ $execute = 1 ]; then
				type=`echo $line | awk '{ print $1 }' | xargs`
				if [ "$type" = alias ]; then
					add_alias `echo $line | awk '{ print $0 }' | sed 's/^alias//' | sed 's|@'"$command_list"'||' | xargs`
				elif [ "$type" = export ]; then
					add_export `echo $line | awk '{ print $0 }' | sed 's/^export//' | sed 's|@'"$command_list"'||' | xargs`
				fi
			fi
			;;
		export*)
				add_export `echo $line | sed 's/^export//' | xargs`
			;;
		alias*)
			if [ ! -z "$line" ]; then
				add_alias `echo $line | sed 's/^alias//' | xargs`
			fi
			;;
	esac
done < "$HOME/.alias_list"



echo Done.
