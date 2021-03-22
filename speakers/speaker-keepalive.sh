#!/bin/sh
# Speakers keepalive - this will play an inaudable tone indefinitely.

if [ -z "$SOUND_FILE" ]; then
    SOUND_FILE=/usr/local/share/speakers/22000.wav
fi
if [ ! -f "$SOUND_FILE" ]; then
    echo >&2 "Error - cannot find sound file - set the \`SOUND_FILE\` variable"
    exit 1
fi
if ! APLAY="$(command -v aplay)" 2>/dev/null; then
    echo >&2 "Error - please ensure aplay is installed"
    exit 2
fi
while true; do
   "$APLAY" -q "$SOUND_FILE"
   sleep 19
done
