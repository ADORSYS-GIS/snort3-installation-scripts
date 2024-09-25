#!/bin/bash

set -e

# Variables
SNORT_VER=3.2.2.0
LIBDAQ_VERSION=3.0.15
LIBDNET_VERSION=1.14
FLEX_VERSION=2.6.4
HWLOC_VERSION=2.5.0
PCRE_VERSION=8.45
ZLIB_VERSION=1.2.13
WORK_DIR=/work
ARCH=$(dpkg --print-architecture)

# Stop and disable Snort service
if systemctl is-active --quiet snort.service; then
    echo "Stopping Snort service..."
    sudo systemctl stop snort.service
fi

if systemctl is-enabled --quiet snort.service; then
    echo "Disabling Snort service..."
    sudo systemctl disable snort.service
fi

# Remove the Snort systemd service file
if [ -f /etc/systemd/system/snort.service ]; then
    echo "Removing Snort service file..."
    sudo rm /etc/systemd/system/snort.service
    sudo systemctl daemon-reload
fi

# Delete Snort user and group
if id "snort" &>/dev/null; then
    echo "Deleting Snort user and group..."
    sudo userdel -r snort
    sudo groupdel snort
fi

# Remove Snort log directory
if [ -d /var/log/snort ]; then
    echo "Removing Snort log directory..."
    sudo rm -rf /var/log/snort
fi

# Remove Snort installation
if dpkg -l | grep snort3 &>/dev/null; then
    echo "Removing Snort 3 package..."
    sudo dpkg --purge snort3
fi

# Remove libdaq
if dpkg -l | grep libdaq &>/dev/null; then
    echo "Removing libdaq package..."
    sudo dpkg --purge libdaq
fi

# Remove libdnet
if dpkg -l | grep libdnet &>/dev/null; then
    echo "Removing libdnet package..."
    sudo dpkg --purge libdnet
fi

# Remove Flex
if dpkg -l | grep flex &>/dev/null; then
    echo "Removing Flex package..."
    sudo dpkg --purge flex
fi

# Remove hwloc
if dpkg -l | grep hwloc &>/dev/null; then
    echo "Removing hwloc package..."
    sudo dpkg --purge hwloc
fi

# Remove LuaJIT
if dpkg -l | grep luajit &>/dev/null; then
    echo "Removing LuaJIT package..."
    sudo dpkg --purge luajit
fi

# Remove PCRE
if dpkg -l | grep pcre &>/dev/null; then
    echo "Removing PCRE package..."
    sudo dpkg --purge pcre
fi

# Remove zlib
if dpkg -l | grep zlib &>/dev/null; then
    echo "Removing zlib package..."
    sudo dpkg --purge zlib
fi

# Remove Go
if [ -d /usr/local/go ]; then
    echo "Removing Go installation..."
    sudo rm -rf /usr/local/go
fi

# Remove Go binaries
if [ -f /usr/local/bin/protoc-gen-go ]; then
    echo "Removing protoc-gen-go binary..."
    sudo rm /usr/local/bin/protoc-gen-go
fi

if [ -f /usr/local/bin/protoc-gen-go-grpc ]; then
    echo "Removing protoc-gen-go-grpc binary..."
    sudo rm /usr/local/bin/protoc-gen-go-grpc
fi

# Remove the working directory
if [ -d "$WORK_DIR" ]; then
    echo "Removing working directory..."
    sudo rm -rf $WORK_DIR
fi

# Reset network interface from promiscuous mode
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}')
if [[ -n "$MAIN_INTERFACE" ]]; then
    echo "Resetting network interface $MAIN_INTERFACE from promiscuous mode..."
    sudo ip link set $MAIN_INTERFACE promisc off
fi

# Remove the Go environment variable from the current session
export PATH=$(echo $PATH | sed -e 's|:/usr/local/go/bin||')

echo "Snort 3 and all associated components have been uninstalled successfully."
