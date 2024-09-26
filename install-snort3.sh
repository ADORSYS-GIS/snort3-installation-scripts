#!/bin/bash

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

# Check system architecture
ARCH=$(uname -m)

# Set URLs for AMD64 and ARM64
URL_AMD64="https://github.com/bengo237/snort3-installation-scripts/releases/download/main/snort3-packages-amd64.zip"
URL_ARM64="https://github.com/bengo237/snort3-installation-scripts/releases/download/main/snort3-packages-arm64.zip"

# Function to download, unzip, and install .deb files
install_packages() {
    local url=$1
    local temp_dir=$(mktemp -d)

    print_step "Downloading" "from $url ..."
    wget -q "$url" -O "$temp_dir/packages.zip"

    print_step "Unzipping" "files ..."
    unzip -q "$temp_dir/packages.zip" -d "$temp_dir"

    print_step "Installing" ".deb files ..."
    sudo dpkg -i "$temp_dir"/*.deb

    print_step "Cleaning up" "temporary files ..."
    rm -rf "$temp_dir"
}

# Check if architecture is AMD64 or ARM64
if [ "$ARCH" == "x86_64" ]; then
    info_message "System architecture is AMD64."
    install_packages "$URL_AMD64"
elif [ "$ARCH" == "aarch64" ]; then
    info_message "System architecture is ARM64."
    install_packages "$URL_ARM64"
else
    error_message "Unsupported architecture: $ARCH"
    exit 1
fi

# Create Snort user and group
print_step "Creating" "Snort user and group..."
sudo groupadd snort
sudo useradd -r -s /sbin/nologin -g snort snort

# Set permissions for Snort log directory
print_step "Setting permissions" "for Snort log directory..."
sudo mkdir -p /var/log/snort
sudo chown -R snort:snort /var/log/snort
sudo chmod 755 /var/log/snort
success_message "Permissions set successfully."

# Grant network packet capture privileges to Snort binary
print_step "Granting privileges" "to Snort binary..."
sudo setcap cap_net_raw,cap_net_admin=eip /usr/local/bin/snort

# Get the main network interface
print_step "Determining" "the main network interface..."
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}')

# Check if the interface was found
if [[ -z "$MAIN_INTERFACE" ]]; then
    error_message "Unable to determine the main network interface."
    exit 1
fi

success_message "Main network interface: $MAIN_INTERFACE"

# Set the interface to promiscuous mode
print_step "Setting" "the interface to promiscuous mode..."
sudo ip link set $MAIN_INTERFACE promisc on

# Paths and variables
SNORT_CONFIG="/usr/local/etc/snort/snort_defaults.lua" 
SNORT_BIN="/usr/local/bin/snort" 
LOG_DIR="/var/log/snort/"
SERVICE_FILE="/etc/systemd/system/snort.service"

# Create the Snort service file
print_step "Creating" "Snort service file..."
cat <<EOL | sudo tee $SERVICE_FILE
[Unit]
Description=Snort 3 Intrusion Detection System
After=network.target

[Service]
Type=simple
ExecStart=$SNORT_BIN -c $SNORT_CONFIG -i $MAIN_INTERFACE -l $LOG_DIR
User=snort
Group=snort
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd services
print_step "Reloading" "systemd services..."
sudo systemctl daemon-reload

# Enable the Snort service to start on boot
print_step "Enabling" "Snort service to start on boot..."
sudo systemctl enable snort.service

# Start the Snort service
print_step "Starting" "Snort service..."
sudo systemctl start snort.service

success_message "Snort 3 service created and started successfully."
