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

# Update system and install dependencies
sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    git libtool pkg-config autoconf gettext \
    libpcap-dev g++ vim make cmake wget libssl-dev \
    liblzma-dev python3-pip unzip protobuf-compiler \
    golang nano net-tools automake checkinstall

# Install Go
if [ "$ARCH" = "amd64" ]; then
    GO_BIN=go1.22.4.linux-amd64.tar.gz
elif [ "$ARCH" = "arm64" ]; then
    GO_BIN=go1.22.4.linux-arm64.tar.gz
else
    echo "Unsupported architecture"
    exit 1
fi
wget https://go.dev/dl/${GO_BIN}
tar -xvf ${GO_BIN}
sudo mv go /usr/local
rm -rf ${GO_BIN}
export PATH=$PATH:/usr/local/go/bin

# Install protoc-gen-go and protoc-gen-go-grpc
go install github.com/golang/protobuf/protoc-gen-go@v1.5.2
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1.0
sudo mv ~/go/bin/protoc-gen-go /usr/local/bin/
sudo mv ~/go/bin/protoc-gen-go-grpc /usr/local/bin/

# Create working directories
WORK_DIR=/work
sudo mkdir -p $WORK_DIR
sudo chmod 777 $WORK_DIR

# Install libdaq
cd $WORK_DIR
wget https://github.com/snort3/libdaq/archive/refs/tags/v${LIBDAQ_VERSION}.tar.gz
tar -xvf v${LIBDAQ_VERSION}.tar.gz
cd libdaq-${LIBDAQ_VERSION}
./bootstrap && ./configure && make
sudo checkinstall --pkgname=libdaq --pkgversion=${LIBDAQ_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv libdaq_${LIBDAQ_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf v${LIBDAQ_VERSION}.tar.gz

# Install libdnet
wget https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-${LIBDNET_VERSION}.tar.gz
tar -xvf libdnet-${LIBDNET_VERSION}.tar.gz
cd libdnet-libdnet-${LIBDNET_VERSION}
./configure && make
sudo checkinstall --pkgname=libdnet --pkgversion=${LIBDNET_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv libdnet_${LIBDNET_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf libdnet-${LIBDNET_VERSION} libdnet-${LIBDNET_VERSION}.tar.gz

# Install Flex
wget https://github.com/westes/flex/releases/download/v${FLEX_VERSION}/flex-${FLEX_VERSION}.tar.gz
tar -xvf flex-${FLEX_VERSION}.tar.gz
cd flex-${FLEX_VERSION}
./configure && make
sudo checkinstall --pkgname=flex --pkgversion=${FLEX_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv flex_${FLEX_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf flex-${FLEX_VERSION} flex-${FLEX_VERSION}.tar.gz

# Install hwloc
wget https://download.open-mpi.org/release/hwloc/v2.5/hwloc-${HWLOC_VERSION}.tar.gz
tar -xvf hwloc-${HWLOC_VERSION}.tar.gz
cd hwloc-${HWLOC_VERSION}
./configure && make
sudo checkinstall --pkgname=hwloc --pkgversion=${HWLOC_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv hwloc_${HWLOC_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf hwloc-${HWLOC_VERSION} hwloc-${HWLOC_VERSION}.tar.gz

# Install LuaJIT with update
cd $WORK_DIR
git clone https://luajit.org/git/luajit.git
cd luajit
make
sudo checkinstall --pkgname=luajit --pkgversion=2.1.0 --backup=no --deldoc=yes --fstrans=no --default
sudo mv luajit_2.1.0-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf luajit

# Install PCRE
wget https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz
tar -xvf pcre-${PCRE_VERSION}.tar.gz
cd pcre-${PCRE_VERSION}
./configure && make
sudo checkinstall --pkgname=pcre --pkgversion=${PCRE_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv pcre_${PCRE_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf pcre-${PCRE_VERSION} pcre-${PCRE_VERSION}.tar.gz

# Install zlib
wget https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz
tar -xvf zlib-${ZLIB_VERSION}.tar.gz
cd zlib-${ZLIB_VERSION}
./configure && make
sudo checkinstall --pkgname=zlib --pkgversion=${ZLIB_VERSION} --backup=no --deldoc=yes --fstrans=no --default
sudo mv zlib_${ZLIB_VERSION}-1_amd64.deb $WORK_DIR
cd $WORK_DIR
rm -rf zlib-${ZLIB_VERSION} zlib-${ZLIB_VERSION}.tar.gz

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

echo "Snort 3 installation and packaging is complete."
