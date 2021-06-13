#!/bin/bash

[ -z "${GIT_USER}"  ] && GIT_USER="Matt Day"
[ -z "${GIT_EMAIL}" ] && GIT_EMAIL="mattsday@gmail.com"

if ! command -v git >/dev/null 2>&1; then
    echo Git not installed
    exit 1
fi
if [ "$(git config --global --get 'pull.rebase')" != true ]; then
	echo Setting git config --global pull.rebase to merge
	git config --global 'pull.rebase' true
fi

if ! git config --global user.name >/dev/null 2>&1; then
    echo Setting git config --global user.name to "${GIT_USER}"
    git config --global user.name "${GIT_USER}"
fi

if ! git config --global user.email >/dev/null 2>&1; then
    echo Setting git config --global user.email to "${GIT_EMAIL}"
    git config --global user.email "${GIT_EMAIL}"
fi

