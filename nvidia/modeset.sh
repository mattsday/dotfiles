#!/bin/sh
ROOT=/usr/lib/modprobe.d
FILENAME=nvidia-modeset.conf
SH_ROOT=/etc/profile.d
SH_FILENAME=nvidia-egl.sh

if [ ! -d "${ROOT}" ]; then
    echo Directory "${ROOT}" does not exist
    exit 1
fi

if [ ! -f "${ROOT}/${FILENAME}" ]; then
    echo 'options nvidia_drm modeset=1' | sudo tee "${ROOT}/${FILENAME}"
fi

if [ ! -d "${SH_ROOT}" ]; then
    echo Directory "${SH_ROOT}" does not exist
    exit 1
fi

if [ ! -f "${SH_ROOT}/${SH_FILENAME}" ]; then
    echo 'export KWIN_DRM_USE_EGL_STREAMS=1' | sudo tee "${SH_ROOT}/${SH_FILENAME}"
fi
