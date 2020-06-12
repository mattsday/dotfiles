#!/bin/bash
# TODO - needs a lot of TLC
FERDI_VERSION=5.5.0
FERDI_URL=https://github.com/getferdi/ferdi/releases/download/v"$FERDI_VERSION"/ferdi_"$FERDI_VERSION"_amd64.deb

if dpkg-query -W -f='${Status}' ferdi 2>/dev/null | grep "ok installed" >/dev/null 2>&1; then
    echo Ferdi already installed
    exit 0
fi

wget -O /tmp/ferdi-"$FERDI_VERSION".deb "$FERDI_URL" || exit 1

sudo dpkg -i /tmp/ferdi-"$FERDI_VERSION".deb || exit 1
