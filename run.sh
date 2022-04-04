#!/bin/bash

set -x

if [ -f recovery.img.lz4 ];then
	lz4 -d recovery.img.lz4 stock-recovery.img
elif [ -f recovery.img ];then
	mv recovery.img stock-recovery.img
fi

off=$(grep -ab -o SEANDROIDENFORCE stock-recovery.img |tail -n 1 |cut -d : -f 1)
dd if=stock-recovery.img of=fastbootd-recovery.img bs=4k count=$off iflag=count_bytes

if [ ! -f phh.pem ];then
    openssl genrsa -f4 -out phh.pem 4096
fi

rm -Rf d
(
mkdir d
cd d
../magiskboot_x86 unpack ../fastbootd-recovery.img
../magiskboot_x86 cpio ramdisk.cpio extract
# Reverse fastbootd ENG mode check
../magiskboot_x86 hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094 # 20 01 00 35
../magiskboot_x86 hexpatch system/bin/recovery eec3009420010034 eec3009420010035
../magiskboot_x86 hexpatch system/bin/recovery 3ad3009420010034 3ad3009420010035
../magiskboot_x86 hexpatch system/bin/recovery 50c0009420010034 50c0009420010035
../magiskboot_x86 hexpatch system/bin/recovery 080109aae80000b4 080109aae80000b5
../magiskboot_x86 hexpatch system/bin/recovery 20f0a6ef38b1681c 20f0a6ef38b9681c
../magiskboot_x86 hexpatch system/bin/recovery 23f03aed38b1681c 23f03aed38b9681c
../magiskboot_x86 hexpatch system/bin/recovery 20f09eef38b1681c 20f09eef38b9681c
../magiskboot_x86 hexpatch system/bin/recovery 26f0ceec30b1681c 26f0ceec30b9681c
../magiskboot_x86 hexpatch system/bin/recovery 24f0fcee30b1681c 24f0fcee30b9681c
../magiskboot_x86 hexpatch system/bin/recovery 27f02eeb30b1681c 27f02eeb30b9681c
../magiskboot_x86 cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery'
../magiskboot_x86 repack ../fastbootd-recovery.img new-boot.img
cp new-boot.img ../fastbootd-recovery.img
)

./avbtool extract_public_key --key phh.pem --output phh.pub.bin
./avbtool add_hash_footer --partition_name recovery --partition_size $(wc -c stock-recovery.img |cut -f 1 -d ' ') --image fastbootd-recovery.img --key phh.pem --algorithm SHA256_RSA4096

lz4 -f fastbootd-recovery.img recovery.img.lz4
tar cvf fastbootd-recovery.tar recovery.img.lz4

# Clean up
rm -Rf d fastbootd-recovery.img phh.pub.bin
