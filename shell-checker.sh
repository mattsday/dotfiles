#!/usr/bin/env bash
# Shellchecks all scripts in this repo to see if they're vaguely sane

do_shellcheck() {
    echo Shellchecking "$1"
    shellcheck -o all -e SC2154,SC2034,SC1090,SC1091 "$1"
}

if ! command -v shellcheck >/dev/null 2>&1; then
    echo Please install shellcheck
    exit 1
fi

if ! do_shellcheck "$0"; then
    echo Shellcheck caused errors parsing this file - out of date shellcheck'?'
    exit 2
fi

shopt -s globstar

for i in **; do
    case "${i}" in
    # Don't parse this script again (do so above to test shellcheck)
    "$0")
        continue
        ;;
    */bashrc | */bash_profile | */profile | */zshrc | */kshrc)
        do_shellcheck "${i}"
        continue
        ;;
    */*.wav)
        continue
        ;;
    *) ;; # Nothing to see here
    esac
    HEADER="$(head -n 1 "${i}" 2>/dev/null)" >/dev/null 2>&1
    case "${HEADER}" in
    '#!/bin/bash')
        do_shellcheck "${i}"
        ;;
    '#!/bin/sh')
        do_shellcheck "${i}"
        ;;
    *) ;; # Nothing to see here
    esac

done
