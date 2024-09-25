#!/bin/bash

set -e

# Variables
LIBDAQ_VERSION=3.0.15
LIBDNET_VERSION=1.14
FLEX_VERSION=2.6.4
HWLOC_VERSION=2.5.0
PCRE_VERSION=8.45
ZLIB_VERSION=1.2.13
SNORT_VER=3.2.2.0
ARCH=$(dpkg --print-architecture)

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Stop and disable Snort service
if systemctl is-active --quiet snort.service; then
    sudo systemctl stop snort.service
fi
if systemctl is-enabled --quiet snort.service; then
    sudo systemctl disable snort.service
fi
sudo rm -f /etc/systemd/system/snort.service
sudo systemctl daemon-reload

# Remove Snort user and group
if id "snort" &>/dev/null; then
    sudo userdel -r snort
fi
if getent group snort &>/dev/null; then
    sudo groupdel snort
fi

# Remove Snort log directory
if [ -d /var/log/snort ]; then
    sudo rm -rf /var/log/snort
fi

# Remove installed packages
sudo dpkg -r snort3 || true
sudo dpkg -r zlib || true
sudo dpkg -r pcre || true
sudo dpkg -r luajit || true
sudo dpkg -r hwloc || true
sudo dpkg -r flex || true
sudo dpkg -r libdnet || true
sudo dpkg -r libdaq || true

# Remove Go binaries
if [ -d /usr/local/go ]; then
    sudo rm -rf /usr/local/go
fi
sudo rm -f /usr/local/bin/protoc-gen-go
sudo rm -f /usr/local/bin/protoc-gen-go-grpc

# Remove working directory
if [ -d /work ]; then
    sudo rm -rf /work
fi

# Remove installed dependencies
sudo apt-get remove --purge -y \
    git libtool pkg-config autoconf gettext \
    libpcap-dev g++ vim make cmake wget libssl-dev \
    liblzma-dev python3-pip unzip protobuf-compiler \
    golang nano net-tools automake checkinstall

# Clean up
sudo apt-get autoremove -y
sudo apt-get clean

echo "All actions have been successfully undone and cleaned up."
