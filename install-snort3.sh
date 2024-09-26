#!/bin/bash

# Check system architecture
ARCH=$(uname -m)

# Set URLs for AMD64 and ARM64
URL_AMD64="https://github.com/bengo237/snort3-installation-scripts/releases/download/main/snort3-packages-amd64.zip"
URL_ARM64="https://github.com/bengo237/snort3-installation-scripts/releases/download/main/snort3-packages-arm64.zip"

# Function to download, unzip, and install .deb files
install_packages() {
    local url=$1
    local temp_dir=$(mktemp -d)

    echo "Downloading from $url ..."
    wget -q "$url" -O "$temp_dir/packages.zip"

    echo "Unzipping files ..."
    unzip -q "$temp_dir/packages.zip" -d "$temp_dir"

    echo "Installing .deb files ..."
    sudo dpkg -i "$temp_dir"/*.deb

    echo "Cleaning up ..."
    rm -rf "$temp_dir"
}

# Check if architecture is AMD64 or ARM64
if [ "$ARCH" == "x86_64" ]; then
    echo "System architecture is AMD64."
    install_packages "$URL_AMD64"
elif [ "$ARCH" == "aarch64" ]; then
    echo "System architecture is ARM64."
    install_packages "$URL_ARM64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

echo "Installation complete."
