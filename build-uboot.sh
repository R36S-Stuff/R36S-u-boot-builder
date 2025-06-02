#!/bin/bash
set -e
function fixperms {
    if [[ ! "$1" == "native" ]]
    then
        echo chown
        echo
        [[ ! -z "$1" ]] && chown -R $2:$3 $4 || echo no fixperms
    else
        echo sudo chown
        echo
        sudo chown -R $2:$3 $4
    fi
}

StartDir=$(pwd)

if [[ ! "$1" == "native" ]]
then
    if [[ -z "$1" ]]
    then
        docker run --rm -v "$(pwd)":"$(pwd)" ubuntu:18.04 "$(pwd)/$(basename "$0")" "$(pwd)" $USER $(id -u) $(id -g)
        exit 0
    else
        StartDir=$1
        cd $StartDir
    fi
fi
echo
echo resolving dependencies
echo
dpkg --add-architecture i386 >/dev/null 2>&1 &&\
apt-get update >/dev/null 2>&1 &&\
apt-get install -y git lzop build-essential gcc \
    bc libncurses5-dev libc6-i386 lib32stdc++6 zlib1g:i386 wget >/dev/null 2>&1

if [[ ! -d "/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin" ]]
then
    echo grabbing toolchain
    echo
    mkdir -p /opt/toolchains
    [[ ! -f "gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz" ]] && wget https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -Ogcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
    tar Jxvf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C /opt/toolchains/
    #rm gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
fi

export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export PATH=/opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin/:$PATH

[[ -z "${UBootSrcRepo}" ]] && UBootSrcRepo=EatPrilosec || say UBootSrcRepo=${UBootSrcRepo}
git clone https://github.com/${UBootSrcRepo}/R36S-u-boot-builder.git u-boot >/dev/null 2>&1
echo fixperms
echo
fixperms $1 $(id -u) $(id -g) src
cd src
#./make.sh odroidgoa
echo mrproper
echo
make mrproper

if [[ -f "../u-boot.config" ]] 
then
    mv configs/odroidgoa_defconfig{,.orig}
    cp ../u-boot.config configs/odroidgoa_defconfig
fi

# make odroidgoa_defconfig
# make
./make.sh odroidgoa

cd sd_fuse
dd if=idbloader.img of=../../u-boot-r36s.bin bs=512 seek=0 conv=fsync,notrunc
dd if=uboot.img     of=../../u-boot-r36s.bin bs=512 seek=16320 conv=fsync,notrunc
dd if=trust.img     of=../../u-boot-r36s.bin bs=512 seek=24512 conv=fsync,notrunc
fixperms $1 $(id -u) $(id -g) ../../u-boot-r36s.bin 
tar cvf ../../u-boot-r36s.tar .
fixperms $1 $(id -u) $(id -g) ../../u-boot-r36s.tar

exit 0
[[ -f ../../u-boot-rocknix.bin ]] && fixperms $1 $(id -u) $(id -g) ../../u-boot-rocknix.bin || echo
[[ -f ../../u-boot-rocknix.bin ]] && rm ../../u-boot-r36s.bin || echo
dd if=idbloader.img of=../../u-boot-rocknix.bin bs=512 seek=0 conv=fsync,notrunc
dd if=uboot.img     of=../../u-boot-rocknix.bin bs=512 seek=16320 conv=fsync,notrunc
dd if=trust.img     of=../../u-boot-rocknix.bin bs=512 seek=24512 conv=fsync,notrunc
fixperms $1 $(id -u) $(id -g) ../../u-boot-rocknix.bin
# tar cvf ../../u-boot-rocknix.tar .
cd ../..
[[ -z "$1" ]] && chown -R $2:$3 src || echo
[[ -z "$1" ]] && chown -R $2:$3 u-boot-rocknix.tar || echo
