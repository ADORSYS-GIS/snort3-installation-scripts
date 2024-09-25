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
sudo systemctl stop snort.service
sudo systemctl disable snort.service
sudo rm -f /etc/systemd/system/snort.service
sudo systemctl daemon-reload

# Remove Snort user and group
sudo userdel -r snort
sudo groupdel snort

# Remove Snort log directory
sudo rm -rf /var/log/snort

# Remove installed packages
sudo dpkg -r snort3
sudo dpkg -r zlib
sudo dpkg -r pcre
sudo dpkg -r luajit
sudo dpkg -r hwloc
sudo dpkg -r flex
sudo dpkg -r libdnet
sudo dpkg -r libdaq

# Remove Go binaries
sudo rm -rf /usr/local/go
sudo rm -f /usr/local/bin/protoc-gen-go
sudo rm -f /usr/local/bin/protoc-gen-go-grpc

# Remove working directory
sudo rm -rf /work

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
