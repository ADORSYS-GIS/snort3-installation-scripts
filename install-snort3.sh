# This script automates the installation and setup of Snort 3 on a Debian-based system.
# It performs the following steps:
# 1. Defines text formatting for logging.
# 2. Sets up logging functions with timestamps.
# 3. Defines variables for versions of dependencies and architecture.
# 4. Disables interactive prompts for package installation.
# 5. Updates the system and installs necessary packages.
# 6. Installs Go programming language based on system architecture.
# 7. Installs protoc-gen-go and protoc-gen-go-grpc.
# 8. Creates a working directory for building dependencies.
# 9. Downloads, builds, and installs libdaq.
# 10. Downloads, builds, and installs libdnet.
# 11. Downloads, builds, and installs Flex.
# 12. Downloads, builds, and installs hwloc.
# 13. Clones, builds, and installs LuaJIT.
# 14. Downloads, builds, and installs PCRE.
# 15. Downloads, builds, and installs zlib.
# 16. Downloads, builds, and installs Snort 3.
# 17. Creates a Snort user and group.
# 18. Sets permissions for the Snort log directory.
# 19. Grants network packet capture privileges to the Snort binary.
# 20. Determines the main network interface and sets it to promiscuous mode.
# 21. Creates a systemd service file for Snort.
# 22. Reloads systemd services and enables the Snort service to start on boot.
# 23. Starts the Snort service.
#!/bin/bash

set -e

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

# Update system and install dependencies
print_step "Updating system" "Installing necessary packages..."
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    git libtool pkg-config autoconf gettext \
    libpcap-dev g++ vim make cmake wget libssl-dev \
    liblzma-dev python3-pip unzip protobuf-compiler \
    golang nano net-tools automake checkinstall
success_message "System updated and packages installed."

# Install Go
if [ "$ARCH" = "amd64" ]; then
    GO_BIN=go1.22.4.linux-amd64.tar.gz
elif [ "$ARCH" = "arm64" ]; then
    GO_BIN=go1.22.4.linux-arm64.tar.gz
else
    error_message "Unsupported architecture"
    exit 1
fi
print_step "Downloading" "Go binary..."
wget https://go.dev/dl/${GO_BIN}
tar -xvf ${GO_BIN}
sudo mv go /usr/local
rm -rf ${GO_BIN}
export PATH=$PATH:/usr/local/go/bin
success_message "Go installed successfully."

# Install protoc-gen-go and protoc-gen-go-grpc
print_step "Installing" "protoc-gen-go and protoc-gen-go-grpc..."
go install github.com/golang/protobuf/protoc-gen-go@v1.5.2
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1.0
sudo mv ~/go/bin/protoc-gen-go /usr/local/bin/
sudo mv ~/go/bin/protoc-gen-go-grpc /usr/local/bin/
success_message "protoc-gen-go and protoc-gen-go-grpc installed successfully."

# Create working directories
WORK_DIR=/work
sudo mkdir -p $WORK_DIR
sudo chmod 777 $WORK_DIR
success_message "Working directory created."

# Install libdaq
cd $WORK_DIR
print_step "Downloading" "libdaq version ${LIBDAQ_VERSION}..."
wget https://github.com/snort3/libdaq/archive/refs/tags/v${LIBDAQ_VERSION}.tar.gz
tar -xvf v${LIBDAQ_VERSION}.tar.gz
cd libdaq-${LIBDAQ_VERSION}
print_step "Building" "libdaq..."
./bootstrap && ./configure && make
sudo checkinstall --pkgname=libdaq --pkgversion=${LIBDAQ_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv libdaq_${LIBDAQ_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf v${LIBDAQ_VERSION}.tar.gz
success_message "libdaq installed successfully."

# Install libdnet
print_step "Downloading" "libdnet version ${LIBDNET_VERSION}..."
wget https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-${LIBDNET_VERSION}.tar.gz
tar -xvf libdnet-${LIBDNET_VERSION}.tar.gz
cd libdnet-libdnet-${LIBDNET_VERSION}
print_step "Building" "libdnet..."
./configure && make
sudo checkinstall --pkgname=libdnet --pkgversion=${LIBDNET_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv libdnet_${LIBDNET_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf libdnet-${LIBDNET_VERSION} libdnet-${LIBDNET_VERSION}.tar.gz
success_message "libdnet installed successfully."

# Install Flex
print_step "Downloading" "Flex version ${FLEX_VERSION}..."
wget https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz
tar -xvf flex-${FLEX_VERSION}.tar.gz
cd flex-${FLEX_VERSION}
print_step "Building" "Flex..."
./configure && make
sudo checkinstall --pkgname=flex --pkgversion=${FLEX_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv flex_${FLEX_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf flex-${FLEX_VERSION} flex-${FLEX_VERSION}.tar.gz
success_message "Flex installed successfully."

# Install hwloc
print_step "Downloading" "hwloc version ${HWLOC_VERSION}..."
wget https://download.open-mpi.org/release/hwloc/v2.5/hwloc-${HWLOC_VERSION}.tar.gz
tar -xvf hwloc-${HWLOC_VERSION}.tar.gz
cd hwloc-${HWLOC_VERSION}
print_step "Building" "hwloc..."
./configure && make
sudo checkinstall --pkgname=hwloc --pkgversion=${HWLOC_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv hwloc_${HWLOC_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf hwloc-${HWLOC_VERSION} hwloc-${HWLOC_VERSION}.tar.gz
success_message "hwloc installed successfully."

# Install LuaJIT with update
cd $WORK_DIR
print_step "Cloning" "LuaJIT..."
git clone https://luajit.org/git/luajit.git
cd luajit
print_step "Building" "LuaJIT..."
make
sudo checkinstall --pkgname=luajit --pkgversion=2.1.0 --backup=no --deldoc=yes --fstrans=no --default
sudo mv luajit_2.1.0-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf luajit
success_message "LuaJIT installed successfully."

# Install PCRE
print_step "Downloading" "PCRE version ${PCRE_VERSION}..."
wget https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz
tar -xvf pcre-${PCRE_VERSION}.tar.gz
cd pcre-${PCRE_VERSION}
print_step "Building" "PCRE..."
./configure && make
sudo checkinstall --pkgname=pcre --pkgversion=${PCRE_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv pcre_${PCRE_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf pcre-${PCRE_VERSION} pcre-${PCRE_VERSION}.tar.gz
success_message "PCRE installed successfully."

# Install zlib
print_step "Downloading" "zlib version ${ZLIB_VERSION}..."
wget https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
tar -xvf zlib-${ZLIB_VERSION}.tar.gz
cd zlib-${ZLIB_VERSION}
print_step "Building" "zlib..."
./configure && make
sudo checkinstall --pkgname=zlib --pkgversion=${ZLIB_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv zlib_${ZLIB_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf zlib-${ZLIB_VERSION} zlib-${ZLIB_VERSION}.tar.gz
success_message "zlib installed successfully."

# Install Snort 3
print_step "Downloading" "Snort 3 version ${SNORT_VER}..."
wget https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VER}.tar.gz
tar -xvf ${SNORT_VER}.tar.gz
cd snort3-${SNORT_VER}
export my_path=/usr/local
print_step "Configuring" "Snort 3..."
./configure_cmake.sh --prefix=$my_path
cd build
print_step "Building" "Snort 3..."
make -j$(nproc)
sudo checkinstall --pkgname=snort3 --pkgversion=${SNORT_VER} --backup=no --deldoc=yes --fstrans=no --default
sudo mv snort3_${SNORT_VER}-1_amd64.deb $WORK_DIR

cd $WORK_DIR
rm -rf snort3-${SNORT_VER} ${SNORT_VER}.tar.gz
success_message "Snort 3 installed successfully."

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
SNORT_BIN="/usr/local/bin/snort/" 
LOG_DIR="/var/log/snort"
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
