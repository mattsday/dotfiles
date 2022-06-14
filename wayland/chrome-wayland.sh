#!/bin/bash
# Enable Chrome's Ozone backend for Wayland. This helps with some issues, for
# example: https://bugs.kde.org/show_bug.cgi?id=358277

CHROME_SHORTCUTS=(
    google-chrome.desktop
    google-chrome-beta.desktop
    brave-browser.desktop
)
APP_LOCATIONS=(
    /usr/share/applications
)
DESTINATION_LOCATION="${HOME}/.local/share/applications"

for shortcut in "${CHROME_SHORTCUTS[@]}"; do
    for location in "${APP_LOCATIONS[@]}"; do
        if [[ -f "${location}/${shortcut}" ]]; then
            if [[ ! -f "${DESTINATION_LOCATION}/${shortcut}" ]]; then
                cp "${location}/${shortcut}" "${DESTINATION_LOCATION}/${shortcut}" || exit
                echo Local missing
            fi
        fi
    done
    if ! grep -- '--ozone-platform=wayland' "${DESTINATION_LOCATION}/${shortcut}" >/dev/null; then
        echo "${DESTINATION_LOCATION}/${shortcut}"
        sed -i -E 's|Exec=(.*?)|Exec=\1 --ozone-platform=wayland|g' "${DESTINATION_LOCATION}/${shortcut}"
    fi
done
