#!/bin/bash
# This script is designed to uninstall and configure Snort 3, a powerful open-source intrusion detection and prevention system (IDS/IPS).
#
# The script performs the following actions:
# 1. Defines text formatting for log messages.
# 2. Implements a logging function with timestamp and helper functions for different log levels (info, warning, error, success).
# 3. Stops and disables the Snort service if it is active and enabled.
# 4. Removes the Snort service file and reloads the systemd daemon.
# 5. Deletes the Snort user and group if they exist.
# 6. Removes the Snort log directory if it exists.
# 7. Uninstalls Snort and related packages.
# 8. Deletes Go binaries and related files.
# 9. Removes the working directory if it exists.
# 10. Uninstalls installed dependencies.
# 11. Cleans up residual files using apt-get autoremove and clean.
#
# Usage:
# Run this script with root privileges to ensure all actions can be performed successfully.


# Define text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BOLD='\033[1m'
NORMAL='\033[0m'

# Function for logging with timestamp
log() {
    local LEVEL="$1"
    shift
    local MESSAGE="$*"
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "${TIMESTAMP} ${LEVEL} ${MESSAGE}"
}

# Logging helpers
info_message() {
    log "${BLUE}${BOLD}[INFO]${NORMAL}" "$*"
}

warn_message() {
    log "${YELLOW}${BOLD}[WARNING]${NORMAL}" "$*"
}

error_message() {
    log "${RED}${BOLD}[ERROR]${NORMAL}" "$*"
}

success_message() {
    log "${GREEN}${BOLD}[SUCCESS]${NORMAL}" "$*"
}

set -e

# Variables
ARCH=$(dpkg --print-architecture)

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

# Stop and disable Snort service
info_message "Stopping and disabling Snort service..."
if systemctl is-active --quiet snort.service; then
    sudo systemctl stop snort.service
    success_message "Snort service stopped."
fi
if systemctl is-enabled --quiet snort.service; then
    sudo systemctl disable snort.service
    success_message "Snort service disabled."
fi
sudo rm -f /etc/systemd/system/snort.service
sudo systemctl daemon-reload
info_message "Snort service file removed."

# Remove Snort user and group
info_message "Removing Snort user and group..."
if id "snort" &>/dev/null; then
    sudo userdel -r snort
    success_message "Snort user removed."
fi
if getent group snort &>/dev/null; then
    sudo groupdel snort
    success_message "Snort group removed."
fi

# Remove Snort log directory
info_message "Removing Snort log directory..."
if [ -d /var/log/snort ]; then
    sudo rm -rf /var/log/snort
    success_message "Snort log directory removed."
fi

# Remove installed packages
info_message "Removing installed packages..."
PACKAGES=("snort3" "zlib" "pcre" "luajit" "hwloc" "flex" "libdnet" "libdaq")
for PACKAGE in "${PACKAGES[@]}"; do
    sudo dpkg -r "$PACKAGE" || true
    success_message "Package $PACKAGE removed (if it was installed)."
done

# Remove Go binaries
info_message "Removing Go binaries..."
if [ -d /usr/local/go ]; then
    sudo rm -rf /usr/local/go
    success_message "Go installation removed."
fi
sudo rm -f /usr/local/bin/protoc-gen-go
sudo rm -f /usr/local/bin/protoc-gen-go-grpc

# Remove working directory
info_message "Removing working directory..."
if [ -d /work ]; then
    sudo rm -rf /work
    success_message "Working directory removed."
fi

# Remove installed dependencies
info_message "Removing installed dependencies..."
sudo apt-get remove --purge -y \
    git libtool pkg-config autoconf gettext \
    libpcap-dev g++ vim make cmake wget libssl-dev \
    liblzma-dev python3-pip unzip protobuf-compiler \
    golang nano net-tools automake checkinstall

# Clean up
info_message "Cleaning up residual files..."
sudo apt-get autoremove -y
sudo apt-get clean
# Remove Snort configuration directory
info_message "Removing Snort configuration directory..."
if [ -d /usr/local/etc/snort ]; then
    sudo rm -rf /usr/local/etc/snort
    success_message "Snort configuration directory removed."
fi

# Clean up apt lists
info_message "Cleaning up apt lists..."
sudo rm -rf /var/lib/apt/lists/*
success_message "Apt lists cleaned up."


success_message "All actions have been successfully undone and cleaned up."
