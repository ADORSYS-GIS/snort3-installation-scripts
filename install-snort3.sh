#!/bin/bash
# This script is designed to install and configure Snort 3, a powerful open-source intrusion detection and prevention system (IDS/IPS).
# 
# Usage:
#   ./install-snort3.sh
#
# Features:
# - Installs necessary dependencies for Snort 3.
# - Downloads and compiles Snort 3 from source.
# - Configures Snort 3 with default settings.
# - Sets up Snort 3 to run as a service.
#
# Requirements:
# - Root or sudo privileges.
# - Internet connection to download packages and Snort 3 source code.
#
# Note:
# - Ensure that your system meets the hardware and software requirements for Snort 3.
# - Review and modify configuration settings as needed for your specific environment.

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

set -e

# Variables
LIBDAQ_VERSION=3.0.15
LIBDNET_VERSION=1.14
FLEX_VERSION=2.6.4
HWLOC_VERSION=2.5.0
PCRE_VERSION=8.45
ZLIB_VERSION=1.2.13
SNORT_VER=3.3.1.0
ARCH=$(dpkg --print-architecture)

# Disable interactive prompts
export DEBIAN_FRONTEND=noninteractive

print_step "Initializing" "Updating system and installing dependencies..."
# Update system and install dependencies
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    git libtool pkg-config autoconf gettext \
    libpcap-dev g++ vim make cmake wget libssl-dev \
    liblzma-dev python3-pip unzip protobuf-compiler \
    golang nano net-tools automake checkinstall

success_message "System updated and dependencies installed successfully."

print_step "Installing" "Go programming language..."
# Install Go
if [ "$ARCH" = "amd64" ]; then
    GO_BIN=go1.22.4.linux-amd64.tar.gz
elif [ "$ARCH" = "arm64" ]; then
    GO_BIN=go1.22.4.linux-arm64.tar.gz
else
    error_message "Unsupported architecture."
    exit 1
fi

wget https://go.dev/dl/${GO_BIN}
tar -xvf ${GO_BIN}
sudo mv go /usr/local
rm -rf ${GO_BIN}
export PATH=$PATH:/usr/local/go/bin

success_message "Go installed successfully."

print_step "Installing" "Protobuf tools..."
# Install protoc-gen-go and protoc-gen-go-grpc
go install github.com/golang/protobuf/protoc-gen-go@v1.5.2
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1.0
sudo mv ~/go/bin/protoc-gen-go /usr/local/bin/
sudo mv ~/go/bin/protoc-gen-go-grpc /usr/local/bin/

success_message "Protobuf tools installed successfully."

# Create working directories
WORK_DIR=/work
sudo mkdir -p $WORK_DIR
sudo chmod 777 $WORK_DIR

# Function to install a library
install_library() {
    local LIB_NAME="$1"
    local LIB_VERSION="$2"
    local LIB_URL="$3"

    print_step "Downloading" "$LIB_NAME version $LIB_VERSION..."
    wget "$LIB_URL"
    tar -xvf "$LIB_NAME-$LIB_VERSION.tar.gz"
    cd "$LIB_NAME-$LIB_VERSION"
    ./configure && make
    sudo checkinstall --pkgname="$LIB_NAME" --pkgversion="$LIB_VERSION" --backup=no --deldoc=yes --fstrans=no --default
    sudo mv "${LIB_NAME}_${LIB_VERSION}-1_amd64.deb" $WORK_DIR
    cd $WORK_DIR
    rm -rf "$LIB_NAME-$LIB_VERSION" "$LIB_NAME-$LIB_VERSION.tar.gz"

    success_message "$LIB_NAME installed successfully."
}

# Install libdaq
install_library "libdaq" "${LIBDAQ_VERSION}" "https://github.com/snort3/libdaq/archive/refs/tags/v${LIBDAQ_VERSION}.tar.gz"

# Install libdnet
install_library "libdnet" "${LIBDNET_VERSION}" "https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-${LIBDNET_VERSION}.tar.gz"

# Install Flex
install_library "flex" "${FLEX_VERSION}" "https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz"

# Install hwloc
install_library "hwloc" "${HWLOC_VERSION}" "https://download.open-mpi.org/release/hwloc/v2.5/hwloc-${HWLOC_VERSION}.tar.gz"

print_step "Installing" "LuaJIT..."
# Install LuaJIT
cd $WORK_DIR
git clone https://luajit.org/git/luajit.git
cd luajit
make
sudo checkinstall --pkgname=luajit --pkgversion=2.1.0 --backup=no --deldoc=yes --fstrans=no --default
sudo mv luajit_2.1.0-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf luajit

success_message "LuaJIT installed successfully."

# Install PCRE
install_library "pcre" "${PCRE_VERSION}" "https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz"

# Install zlib
install_library "zlib" "${ZLIB_VERSION}" "https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz"

print_step "Installing" "Snort 3..."
# Install Snort 3
wget https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VER}.tar.gz
tar -xvf ${SNORT_VER}.tar.gz
cd snort3-${SNORT_VER}
export my_path=/usr/local
./configure_cmake.sh --prefix=$my_path
cd build
make -j$(nproc)
sudo checkinstall --pkgname=snort3 --pkgversion=${SNORT_VER} --backup=no --deldoc=yes --fstrans=no --default
sudo mv snort3_${SNORT_VER}-1_amd64.deb $WORK_DIR

cd $WORK_DIR
rm -rf snort3-${SNORT_VER} ${SNORT_VER}.tar.gz

success_message "Snort 3 installed successfully."

print_step "Creating" "Snort user and group..."
# Create Snort user and group
sudo groupadd snort
sudo useradd -r -s /sbin/nologin -g snort snort
success_message "Snort user and group created."

print_step "Setting permissions" "For Snort log directory..."
# Set permissions for Snort log directory
sudo mkdir -p /var/log/snort
sudo chown -R snort:snort /var/log/snort
sudo chmod 750 /var/log/snort
success_message "Permissions set for Snort log directory."

print_step "Granting" "Network packet capture privileges to Snort binary..."
# Grant network packet capture privileges to Snort binary
sudo setcap cap_net_raw,cap_net_admin=eip /usr/local/bin/snort
success_message "Privileges granted."

# Get the main network interface
MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}')

# Check if the interface was found
if [[ -z "$MAIN_INTERFACE" ]]; then
    error_message "Unable to determine the main network interface."
    exit 1
fi

info_message "Main network interface: $MAIN_INTERFACE"

print_step "Configuring" "Main network interface to promiscuous mode..."
# Set the interface to promiscuous mode
sudo ip link set $MAIN_INTERFACE promisc on
success_message "Promiscuous mode set for $MAIN_INTERFACE."

# Paths and variables
SNORT_CONFIG="/usr/local/etc/snort/snort.lua" 
SNORT_BIN="/usr/local/bin/snort" 
LOG_DIR="/var/log/snort"
SERVICE_FILE="/etc/systemd/system/snort.service"

print_step "Creating" "Snort service file..."
# Create the Snort service file
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

success_message "Snort service file created."

print_step "Reloading" "Systemd services..."
# Reload systemd services
sudo systemctl daemon-reload

print_step "Enabling" "Snort service to start on boot..."
# Enable the Snort service to start on boot
sudo systemctl enable snort.service

print_step "Starting" "Snort service..."
# Start
sudo systemctl start snort.service

success_message "Snort service started successfully."

