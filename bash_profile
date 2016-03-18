#!/bin/bash
# Matt Day's custom .bash_profile file
# Not sure where I got all this from, it showed up along the way!
# Latest copy always here: https://github.com/mattsday/dotfiles/

# Do nothing other than launch bashrc (which checks if we're running interactively)
# ...for some reason ootb OS X doesn't do this!

if [[ -e $HOME/.bashrc ]]; then
	. $HOME/.bashrc
fi
