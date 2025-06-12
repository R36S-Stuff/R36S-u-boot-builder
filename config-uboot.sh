#!/bin/bash

# if [[ ! "$1" == "native" ]]
# then
#     if [[ -z "$1" ]]
#     then
#         docker run -it --rm -v "$(pwd)":"$(pwd)" ubuntu:18.04 "$(pwd)/$(basename "$0")" "$(pwd)" $USER $(id -u) $(id -g)
#         exit 0
#     else
#         StartDir=$1
#         cd $StartDir
#     fi
# fi

echo resolving dependencies
dpkg --add-architecture i386 >/dev/null 2>&1 &&\
apt-get update >/dev/null 2>&1 &&\
apt-get install -y git lzop build-essential gcc \
    bc libncurses5-dev libc6-i386 lib32stdc++6 zlib1g:i386 wget >/dev/null 2>&1

if [[ ! -d "/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin" ]]
then
    mkdir -p /opt/toolchains
    wget https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
    tar Jxvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C /opt/toolchains/
    rm gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
fi

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/:$PATH

cd src
make mrpropper
make odroidgoa_defconfig
[[ -f ../u-boot.config ]] && cp ../u-boot.config .config 
make menuconfig
cp .config ../u-boot.config