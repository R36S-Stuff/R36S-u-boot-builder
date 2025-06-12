#!/bin/bash

#1 2 3 4 
for panel in 4-60hz
do 
    img="$(pwd)/u-boot-bootpart-panel$panel.img"

    [[ -f "$img" ]] && rm "$img"

    fallocate -l 536MiB "$img"
    lodev=$(losetup -f)
    sudo losetup -P $lodev "$img"

    cd src/sd_fuse
    ./sd_fusing.sh $lodev
    cd ../..

    sudo parted /dev/loop0 mktable msdos

    sudo losetup -d $lodev
    lodev=$(losetup -f)
    sudo losetup -P $lodev "$img"

    sudo parted $lodev mkpart primary 16MiB 512MiB

    sudo mkfs.fat -F 32 ${lodev}p1

    [[ ! -d tmpmnt ]] && mkdir tmpmnt
    sudo mount ${lodev}p1 tmpmnt

    sudo cp boot.ini tmpmnt/
    sudo cp logo.bmp tmpmnt/
    sudo cp -r panels/$panel/* tmpmnt/

    sync
    sudo umount ${lodev}p1 && rm -rf tmpmnt
    sudo losetup -d $lodev
done
