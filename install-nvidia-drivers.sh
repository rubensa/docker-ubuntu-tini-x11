#!/usr/bin/env bash

if ! (set -o noclobber ; echo > /tmp/install-nvidia-drivers.lock) ; then
    exit 1  # the install-nvidia-drivers.lock already exists
fi

# Install NVIDIA drivers if NVIDIA_VERSION is set and not previously installed
if [ ! -z ${NVIDIA_VERSION} ] && [ ! `command -v nvidia-smi` ]; then
    echo "# Downloading NVIDIA drivers matching host version (${NVIDIA_VERSION})..."
    curl -o nvidia.run -sSL http://us.download.nvidia.com/XFree86/Linux-x86_64/${NVIDIA_VERSION}/NVIDIA-Linux-x86_64-${NVIDIA_VERSION}.run
    chmod +x nvidia.run
    echo "# Installing NVIDIA drivers..."
    sudo ./nvidia.run --ui=none --no-kernel-module --no-install-compat32-libs --install-libglvnd --no-questions
    rm nvidia.run
fi

rm -f /tmp/install-nvidia-drivers.lock