#!/bin/bash
#
# This script uninstalls Snort 3 and its related packages from the system.
# It performs the following steps:
# 1. Defines text formatting for log messages.
# 2. Provides logging functions with timestamp for different log levels (INFO, WARNING, ERROR, SUCCESS).
# 3. Uninstalls Snort 3 and its dependencies if they are installed.
# 4. Removes the Snort user and group.
# 5. Deletes the Snort log directory.
# 6. Removes Snort binary and configuration files.
# 7. Revokes network packet capture privileges from the Snort binary.
# 8. Disables promiscuous mode on the main network interface.
# 9. Removes the Snort service file.
# 10. Reloads systemd services.
# 11. Stops and disables the Snort service.
# 12. Cleans up temporary files related to Snort.
# 
# Usage:
# Run this script with root privileges to ensure all operations are performed successfully.
# Example: sudo ./uninstall-snort3.sh

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

print_step() {
	log "${BLUE}${BOLD}[STEP]${NORMAL}" "$1: $2"
}

# Uninstall Snort and dependencies
print_step "Uninstalling" "Snort and related packages..."

PACKAGES=(
	"snort3"
	"libdaq"
	"libdnet"
	"luajit"
	"pcre"
	"flex"
	"hwloc"
	"zlib"
)

for package in "${PACKAGES[@]}"; do
	if dpkg -l | grep -q "$package"; then
		print_step "Removing" "$package..."
		sudo apt-get remove --purge -y "$package"
	else
		warn_message "$package is not installed, skipping..."
	fi
done

# Remove Snort user and group
print_step "Removing" "Snort user and group..."
if id "snort" &>/dev/null; then
	sudo userdel -r snort
else
	warn_message "Snort user does not exist, skipping..."
fi

if getent group snort &>/dev/null; then
	sudo groupdel snort
else
	warn_message "Snort group does not exist, skipping..."
fi

# Remove Snort log directory
print_step "Removing" "Snort log directory..."
if [ -d /var/log/snort ]; then
	sudo rm -rf /var/log/snort
else
	warn_message "Snort log directory does not exist, skipping..."
fi

# Remove Snort binary and configuration
print_step "Removing" "Snort binary and configuration..."
if [ -f /usr/local/bin/snort ]; then
	sudo rm -f /usr/local/bin/snort
else
	warn_message "Snort binary does not exist, skipping..."
fi

if [ -f /usr/local/etc/snort/snort_defaults.lua ]; then
	sudo rm -f /usr/local/etc/snort/snort_# This script installs and configures Snort 3 on a Debian-based system.
# It performs the following steps:
# 1. Defines text formatting for log messages.
# 2. Defines logging functions with timestamp.
# 3. Checks and installs required packages (curl and unzip).
# 4. Configures the library path for Snort.
# 5. Downloads, unzips, and installs Snort packages based on system architecture (AMD64 or ARM64).
# 6. Creates a Snort user and group.
# 7. Sets permissions for the Snort log directory.
# 8. Grants network packet capture privileges to the Snort binary.
# 9. Determines the main network interface and sets it to promiscuous mode.
# 10. Creates a systemd service file for Snort.
# 11. Reloads systemd services and enables the Snort service to start on boot.
# 12. Starts the Snort service.
# Define text formattingdefaults.lua
else
	warn_message "Snort configuration file does not exist, skipping..."
fi

# Revoke network packet capture privileges from Snort binary
print_step "Revoking privileges" "from Snort binary..."
if [ -f /usr/local/bin/snort ]; then
	sudo setcap -r /usr/local/bin/snort
else
	warn_message "Snort binary does not exist, skipping privilege revocation..."
fi

# Disable promiscuous mode on the main network interface
print_step "Disabling" "promiscuous mode on the network interface..."
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}')
if [[ -n "$MAIN_INTERFACE" ]]; then
	sudo ip link set $MAIN_INTERFACE promi# This script installs and configures Snort 3 on a Debian-based system.
# It performs the following steps:
# 1. Defines text formatting for log messages.
# 2. Defines logging functions with timestamp.
# 3. Checks and installs required packages (curl and unzip).
# 4. Configures the library path for Snort.
# 5. Downloads, unzips, and installs Snort packages based on system architecture (AMD64 or ARM64).
# 6. Creates a Snort user and group.
# 7. Sets permissions for the Snort log directory.
# 8. Grants network packet capture privileges to the Snort binary.
# 9. Determines the main network interface and sets it to promiscuous mode.
# 10. Creates a systemd service file for Snort.
# 11. Reloads systemd services and enables the Snort service to start on boot.
# 12. Starts the Snort service.
# Define text formattingsc off
else
	warn_message "Unable to determine the main network interface, skipping promiscuous mode reset."
fi

# Remove the Snort service file
print_step "Removing" "Snort service file..."
if [ -f /etc/systemd/system/snort.service ]; then
	sudo rm -f /etc/systemd/system/snort.service
else
	warn_message "Snort service file does not exist, skipping..."
fi

# Reload systemd services
print_step "Reloading" "systemd services..."
sudo systemctl daemon-reload

# Stop and disable the Snort service
print_step "Stopping and disabling" "Snort service..."
if systemctl list-units --full -all | grep -Fq 'snort.service'; then
	sudo systemctl stop snort.service
	sudo systemctl disable snort.service
else
	warn_message "Snort service does not exist, skipping..."
fi

# Clean up temporary files (if any)
print_step "Cleaning up" "temporary files..."
sudo rm -rf /tmp/snort-*

success_message "Snort and all related packages uninstalled and changes reverted successfully."