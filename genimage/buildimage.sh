#!/bin/bash
# NOTE: this file used in docker container
#       don't execute it directly
#                               -- xiaofan

set -xe

BOOT_UUID=7866616e-2d6f-7065-6e65-756c65722d62
ROOT_UUID=7866616e-2d6f-7065-6e65-756c65722d72
# now we are in /work
# /work/rootfs.tar mounted from host (read only)
# /work/genimage mounted from host (read only)
# /work/output mounted from host (read/write)
# /work/input is temporary directory, store genimage input files
# /work/rootfs is temporary directory, store all files in rootfs partition
# /work/boot is temporary directory, store all files in boot partition

mkdir rootfs
tar -C rootfs -xf rootfs.tar

mv rootfs/boot .
mkdir rootfs/boot

rm rootfs/.dockerenv
rm rootfs/etc/resolv.conf
echo "openeuler-rock3a" >rootfs/etc/hostname
cat >rootfs/etc/fstab <<EOF
UUID=$ROOT_UUID /           ext4    defaults    0   1
UUID=$BOOT_UUID /boot       ext4    defaults    0   2
EOF

# generate boot.ext4
genimage --config genimage/part-boot.cfg --rootpath boot
tune2fs -U $BOOT_UUID images/boot.ext4
rm -rf tmp/
# generate rootfs.ext4
genimage --config genimage/part-rootfs.cfg --rootpath rootfs
tune2fs -U $ROOT_UUID images/rootfs.ext4
rm -rf tmp/

# generate image
mkdir input/
mv images/{boot,rootfs}.ext4 input/
cp genimage/firmware/*.bin input/
genimage --config genimage/image.cfg
rm -rf tmp/

# copy to host
mv input/{boot,rootfs}.ext4 images
chown -R $HOSTUID:$HOSTGID images
cp -a images/* output/
