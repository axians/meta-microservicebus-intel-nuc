#!/bin/sh -e
#
# Copyright (c) 2012, Intel Corporation.
# All rights reserved.
#
# install.sh [device_name] [rootfs_name]
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# figure out how big of a boot partition we need
boot_size=$(du -ms /run/media/$1/ | awk '{print $1}')
# remove rootfs.img ($2) from the size if it exists, as its not installed to /boot
if [ -e /run/media/$1/$2 ]; then
	boot_size=$(( boot_size - $( du -ms /run/media/$1/$2 | awk '{print $1}')  ))
fi
# remove initrd from size since its not currently installed
if [ -e /run/media/$1/initrd ]; then
	boot_size=$(( boot_size - $( du -ms /run/media/$1/initrd | awk '{print $1}') ))
fi
# add 10M to provide some extra space for users and account
# for rounding in the above subtractions
boot_size=$(( boot_size + 10 ))

# 5% for swap
swap_ratio=5

# Get a list of hard drives
hdnamelist=""
live_dev_name=`cat /proc/mounts | grep ${1%/} | awk '{print $1}'`
live_dev_name=${live_dev_name#\/dev/}
# Only strip the digit identifier if the device is not an mmc
case $live_dev_name in
    mmcblk*)
    ;;
    nvme*)
    ;;
    *)
        live_dev_name=${live_dev_name%%[0-9]*}
    ;;
esac

echo "Searching for hard drives ..."

# Some eMMC devices have special sub devices such as mmcblk0boot0 etc
# we're currently only interested in the root device so pick them wisely
devices=`ls /sys/block/ | grep -v mmcblk` || true
mmc_devices=`ls /sys/block/ | grep "mmcblk[0-9]\{1,\}$"` || true
devices="$devices $mmc_devices"

for device in $devices; do
    case $device in
        loop*)
            # skip loop device
            ;;
        sr*)
            # skip CDROM device
            ;;
        ram*)
            # skip ram device
            ;;
        *)
            # skip the device LiveOS is on
            # Add valid hard drive name to the list
            case $device in
                $live_dev_name*)
                # skip the device we are running from
                ;;
                *)
                    hdnamelist="$hdnamelist $device"
                ;;
            esac
            ;;
    esac
done

if [ -z "${hdnamelist}" ]; then
    echo "You need another device (besides the live device /dev/${live_dev_name}) to install the image. Installation aborted."
    exit 1
fi

# Set static install target
TARGET_DEVICE_NAME="@ROOT_BLOCK_DEVICE_NAME@"
echo "TARGET_DEVICE_NAME=${TARGET_DEVICE_NAME}"

for hdname in $hdnamelist; do
    # Display found hard drives and their basic info
    echo "-------------------------------"
    echo /dev/$hdname
    if [ -r /sys/block/$hdname/device/vendor ]; then
        echo -n "VENDOR="
        cat /sys/block/$hdname/device/vendor
    fi
    if [ -r /sys/block/$hdname/device/model ]; then
        echo -n "MODEL="
        cat /sys/block/$hdname/device/model
    fi
    if [ -r /sys/block/$hdname/device/uevent ]; then
        echo -n "UEVENT="
        cat /sys/block/$hdname/device/uevent
    fi
    echo
done

if [ -n "$TARGET_DEVICE_NAME" ]; then
    echo "Installing image on /dev/$TARGET_DEVICE_NAME ..."
else
    echo "No hard drive selected. Installation aborted."
    exit 1
fi

device=/dev/$TARGET_DEVICE_NAME

#
# The udev automounter can cause pain here, kill it
#
rm -f /etc/udev/rules.d/automount.rules
rm -f /etc/udev/scripts/mount*

#
# Unmount anything the automounter had mounted
#
umount ${device}* 2> /dev/null || /bin/true

mkdir -p /tmp

# Create /etc/mtab if not present
if [ ! -e /etc/mtab ] && [ -e /proc/mounts ]; then
    ln -sf /proc/mounts /etc/mtab
fi

disk_size=$(parted ${device} unit mb print | grep '^Disk .*: .*MB' | cut -d" " -f 3 | sed -e "s/MB//")

swap_size=$((disk_size*swap_ratio/100))

# Set rootfs size (in M) from image file + 100 MB account for roundings etc.
rootfs_a_size=$(ls -l /run/media/$1/$2 | awk '{printf("%.0f\n", $5/1000000+100)}')
rootfs_b_size=$(ls -l /run/media/$1/$2 | awk '{printf("%.0f\n", $5/1000000+100)}')

data_size=$((disk_size-boot_size-rootfs_a_size-rootfs_b_size-swap_size))

rootfs_a_start=$((boot_size))
rootfs_a_end=$((rootfs_a_start+rootfs_a_size))

rootfs_b_start=$((rootfs_a_end))
rootfs_b_end=$((rootfs_b_start+rootfs_b_size))

data_start=$((rootfs_b_end))
data_end=$((data_start+data_size))

swap_start=$((data_end))

# MMC devices are special in a couple of ways
# 1) they use a partition prefix character 'p'
# 2) they are detected asynchronously (need rootwait)
rootwait=""
part_prefix=""
if [ ! "${device#/dev/mmcblk}" = "${device}" ] || \
   [ ! "${device#/dev/nvme}" = "${device}" ]; then
    part_prefix="p"
    rootwait="rootwait"
fi

# USB devices also require rootwait
if [ -n `readlink /dev/disk/by-id/usb* | grep $TARGET_DEVICE_NAME` ]; then
    rootwait="rootwait"
fi

bootfs=${device}${part_prefix}1
rootfs_a=${device}${part_prefix}2
rootfs_b=${device}${part_prefix}3
data=${device}${part_prefix}4
swap=${device}${part_prefix}5

echo "*****************"
echo "Boot partition size:   $boot_size MB ($bootfs)"
echo "Rootfs A partition size: $rootfs_a_size MB ($rootfs_a)"
echo "Rootfs B partition size: $rootfs_b_size MB ($rootfs_b)"
echo "Data partition size: $data_size MB ($data)"
echo "Swap partition size:   $swap_size MB ($swap)"
echo "*****************"
echo "Deleting partition table on ${device} ..."
dd if=/dev/zero of=${device} bs=512 count=35

echo "Creating new partition table on ${device} ..."
parted ${device} mklabel gpt

echo "Creating boot partition on $bootfs"
parted ${device} mkpart boot fat32 0% $boot_size
parted ${device} set 1 boot on

echo "Creating rootfs A partition on $rootfs_a"
parted ${device} mkpart root ext4 $rootfs_a_start $rootfs_a_end

echo "Creating rootfs B partition on $rootfs_b"
parted ${device} mkpart root ext4 $rootfs_b_start $rootfs_b_end

echo "Creating data partition on $data"
parted ${device} mkpart root ext4 $data_start $data_end

echo "Creating swap partition on $swap"
parted ${device} mkpart swap linux-swap $swap_start 100%

parted ${device} print

echo "Waiting for device nodes..."
C=0
while [ $C -ne 3 ] && [ ! -e $bootfs  -o ! -e $rootfs_a  -o ! -e $rootfs_b  -o ! -e $data -o ! -e $swap ]; do
    C=$(( C + 1 ))
    sleep 1
done

echo "Formatting $bootfs to vfat..."
mkfs.vfat $bootfs

echo "Formatting $rootfs_a to ext4..."
mkfs.ext4 -F $rootfs_a

echo "Formatting $rootfs_b to ext4..."
mkfs.ext4 -F $rootfs_b

echo "Formatting $data to ext4..."
mkfs.ext4 -F $data

echo "Formatting swap partition...($swap)"
mkswap $swap

mkdir /tgt_root_a
mkdir /tgt_root_b
mkdir /src_root
mkdir -p /boot

# Handling of the target root partition
mount $rootfs_a /tgt_root_a
mount $rootfs_b /tgt_root_b
mount -o rw,loop,noatime,nodiratime /run/media/$1/$2 /src_root
echo "Copying rootfs files..."
cp -a /src_root/* /tgt_root_a
cp -a /src_root/* /tgt_root_b
if [ -d /tgt_root/etc/ ] ; then
    boot_uuid=$(blkid -o value -s UUID ${bootfs})
    swap_part_uuid=$(blkid -o value -s PARTUUID ${swap})
    
    # We dont want udev to mount our root device while we're booting...
    if [ -d /tgt_root/etc/udev/ ] ; then
        echo "${device}" >> /tgt_root/etc/udev/mount.blacklist
    fi
fi

umount /src_root

# Handling of the target boot partition
mount $bootfs /boot
echo "Preparing boot partition..."

EFIDIR="/boot/EFI/BOOT"
mkdir -p $EFIDIR
# Copy the efi loader
cp /run/media/$1/EFI/BOOT/*.efi $EFIDIR

if [ -f /run/media/$1/EFI/BOOT/grub.cfg ]; then
    root_part_uuid=$(blkid -o value -s PARTUUID ${rootfs_a})
    GRUBCFG="$EFIDIR/grub.cfg"
    cp /run/media/$1/EFI/BOOT/grub.cfg $GRUBCFG
fi

umount /tgt_root_a
umount /tgt_root_b

# Copy kernel artifacts. To add more artifacts just add to types
# For now just support kernel types already being used by something in OE-core
for types in bzImage zImage vmlinux vmlinuz fitImage; do
    for kernel in `find /run/media/$1/ -name $types*`; do
        cp $kernel /boot
    done
done

echo ""
echo "****************************************"
echo " CONSOLE...press CTRL+D if all is ok"
echo "****************************************"
echo ""
/bin/bash
echo end console

umount /boot

sync

echo "Installation successful. Remove your installation media and press ENTER to reboot."

read enter

echo "Rebooting..."
reboot -f
