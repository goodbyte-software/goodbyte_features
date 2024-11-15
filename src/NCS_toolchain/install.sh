#!/bin/bash

NRFUTIL_URL="https://developer.nordicsemi.com/.pc-tools/nrfutil/x64-linux/nrfutil"
NCLT_URL="https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-0/nrf-command-line-tools-10.24.0_linux-amd64.tar.gz"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u "${USERNAME}" > /dev/null 2>&1; then
    USERNAME=root
fi
export USERNAME_VAR="${USERNAME}"

wget -q "$NRFUTIL_URL" -O /usr/local/bin/nrfutil
if [ $? -ne 0 ]; then
    echo "Error: Downloading nrfutil failed!"
    exit 1
else
    echo "nrfutil downloaded successfully."
fi

chmod +x /usr/local/bin/nrfutil


sudo -u "${USERNAME}" nrfutil install nrf5sdk-tools
sudo -u "${USERNAME}" nrfutil install device
sudo -u "${USERNAME}" nrfutil install toolchain-manager


sudo -u "${USERNAME}" nrfutil toolchain-manager install --ncs-version v${VERSION}
if [ $? -ne 0 ]; then
    echo "Error: Installing NCS version v${VERSION} failed!"
    exit 1
else
    echo "NCS version v${VERSION} installed successfully."
fi


sudo -u "${USERNAME}" nrfutil toolchain-manager env --ncs-version v${VERSION} --as-script > /usr/local/bin/.zephyrrc


if [ -n "$NCLT_URL" ]; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    wget -qO- "$NCLT_URL" | tar -xz || { echo "Download error"; exit 1; }

    if [ -d ./nrf-command-line-tools ]; then
        cp -r ./nrf-command-line-tools /opt
        ln -sf /opt/nrf-command-line-tools/bin/nrfjprog /usr/local/bin/nrfjprog
        ln -sf /opt/nrf-command-line-tools/bin/mergehex /usr/local/bin/mergehex
    else
        echo "nrf-command-line-tools not found!"
    fi

    cd ~
    rm -rf "$TEMP_DIR"
else
    echo "Skipping nRF Command Line Tools installation (URL not provided)"
fi


