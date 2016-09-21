---
layout: post
title: An upgrade strategy for embedded Linux systems
description: "Implementing a simple upgrade strategy for deployed embedded Linux systems"
date: 2016-09-21 13:44:00
categories: yocto 
tags: [linux, embedded, upgrades, beaglebone, gumstix, overo, duovero]
---

Here is a simple upgrade strategy for deployed small board Linux systems like [Gumstix][gumstix], [BeagleBones][beaglebone] or others running off an *SD card* or *eMMC*.

These boards use [U-Boot][uboot] for the *bootloader* and run a Linux distribution built with tools from the [Yocto Project][yocto].

The upgrades I am considering here are *full-system* upgrades, everything but the *bootloader*. These are not incremental upgrades using package managers like rpm, apt or opkg.

*Full-system* upgrades are nice because they are *atomic* and easy to rollback to a known good state assuming the previous system was not modified.

The drawback to *full-system* upgrades is traditionally the size when distributing (bandwidth) and the system resources when installing (not enough space for two systems, takes too long to run the upgrade). 

With the embedded Linux systems I work on these are typically non-issues. 

The size of a [Yocto][yocto] built system as a compressed tarball is usually around 50 MB and almost never greater then 100 MB.

*SD cards* or *eMMC* sizes are rarely less then 4 GB eliminating the storage issue. RAM is typically 512 MB or greater with processors running close to 1 GHz at the low end and frequently multi-core. System resources required to perform the upgrade are not a problem.

Distribution of the new system can be over a network (ethernet or wifi) or through a USB removable drive.  Transferring files less then 100 MB is fairly trivial today even over wifi.

Another nice feature in an upgrade system is the ability to run in the background with the only downtime being the actual reboot to the new system when it's ready.

### Background

The core idea is nothing radical. There will be two *rootfs* partitions, one active and potentially **read-only** and the other inactive and not mounted.

The upgrade will mount and install the new *rootfs* on the non-active partition and then make whatever changes are necessary to let the bootloader know which partition to use on the next boot. 

The implementation described assumes storage of at least **4GB**, with the two *rootfs* partitions being **1GB** each. This amount of storage is not a hard requirement, but as a practical matter less available storage is unlikely to be encountered.

### Requirements

Here are some of my self-imposed requirements

1. The upgrade is a full *rootfs* upgrade, not just select packages.
2. No dependencies other then a Linux shell ([BusyBox][busybox] is sufficient) and some basic disk utilities (dd, sfdisk, mkfs).
3. The currently running *rootfs* is the fallback if the upgrade fails for any reason.
4. No modifications to mainline *u-boot*. (Currently using 2016.07).
5. The upgrade is allowed to modify files on a dedicated partition of the storage device.
6. Storage has already been partitioned appropriately with some onetime install scripts.

### Assumptions

These assumptions could be worked-around or ignored, but for now I am treating them as true.

1. The running *rootfs* is **read-only**.
2. The *boot* partition is **read-only**.
3. There is temporary space available on the storage device for the compressed tarball (i.e. we are not trying to run the upgrade out of RAM). If the new image comes on a USB drive, that is sufficient.

### Distribution

An actual implementation will have to handle the details of getting the new *rootfs* tarball onto the device and checking for corruption and validity.

I'm going to skip over this since the details tend to have project specific nuances that don't immediately affect the low-level implementation I am covering here. 

### Preparation

One of the requirements was that an initial install previously setup some partitions on the storage device.

Here's a representative partitioning using an 8 GB SD card prepped for a Gumstix Overo
 
    root@overo:~# fdisk -l /dev/mmcblk0
    Disk /dev/mmcblk0: 7.4 GiB, 7948206080 bytes, 15523840 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x98ed8cc1

    Device         Boot   Start      End  Sectors  Size Id Type
    /dev/mmcblk0p1 *        128   131199   131072   64M  c W95 FAT32 (LBA)
    /dev/mmcblk0p2       133120  2230271  2097152    1G 83 Linux
    /dev/mmcblk0p3      2230272  4327423  2097152    1G 83 Linux
    /dev/mmcblk0p4      4327424 15523839 11196416  5.3G  5 Extended
    /dev/mmcblk0p5      4329472  4460543   131072   64M  c W95 FAT32 (LBA)
    /dev/mmcblk0p6      4462592 15523839 11061248  5.3G 83 Linux

**p1** is for the bootloader

**p2** and **p3** are the two rootfs partitions.

**p5** will be for *flag* files used by the upgrade system.

**p6** is extra space for application use and general storage. 


### Implementation

Here are some of the things the upgrade script needs to check

1. On which partition is the current *rootfs* running?
2. Is storage partitioned appropriately?
3. Do we have a writable location for flagging the partition to use?


Installing the *rootfs* from a tarball once we know the partition is 5 steps

1. Format the new partition as ext4
2. Mount the partition at a temporary location
3. Untar the new *rootfs*
4. Copy any config files, app files, etc that we want to transfer from the current *rootfs* to the new one
5. Unmount the partition

The actual code will be something like this (without any error handling)

    # mkfs.ext4 -q <new-root-partition>
    # mount <new-root-partition> /mnt
    # tar -C /media -xJf <image-file>.tar.xz
    # copy config/app files as needed
    # umount <new-root-partition>


The final step is updating the bootloader so that it knows about the new *rootfs*.

A bootscript file (`uEnv.txt`) is commonly used with *u-boot* to customize the boot process. The bootscript is typically used to specify a *.dtb for the kernel and also to pass command line parameters to the kernel.

One of the command line parameters that can be passed is the location of the *rootfs*.

The `uEnv.txt` file is located on the boot partition **p1** which I am considering **read-only**, so I won't be modifying `uEnv.txt`.

But *u-boot* runs a [Hush][hush] shell that allows some simple scripting. 

Some of the things that can be done with the *u-boot* shell

* Test for file existence
* Create new files

This what the **p5** partition will be used for. I'll call this the **flags** partition.

There will be at most three flag files at any one time.

If **p2** is the *rootfs* partition, the possible files would be

    two
    two_tried
    two_ok

or if **p3** is the *rootfs*, they would be

    three
    three_tried
    three_ok


The files `two` or `three` indicate which partition should be used. This file is managed by the upgrade script  as the last step of the upgrade process.

The `tried` flag file is managed by u-boot to indicate whether this partition has been tried before. This is used to ensure we don't keep retrying a partition that doesn't boot.

The `ok` flag files tell u-boot that the partition is good to use. This file is managed by a Linux userland script once the system has booted successfully using this partition.


Here's some pseudo code for the u-boot use of the **flags** partition

    if test -e three then
        if test -e three_ok then
            boot partition three
        elif test -e three_tried then
            boot partition two
        else
            write three_tried
            boot partition three
        fi
	else if test -e two then
        if test -e two_ok then
            boot partition two
        elif test -e two_tried then
            boot partition three
        else
            write two_tried
            boot partition two
        fi
    fi


Once the new system has booted successfully, Linux runs a script like the following to ensure that an `ok` file is written to the **flags** partition for the next boot.

    mount <flag partition> </mnt>

    if <current rootfs is p2> then
        if [ ! -e /mnt/two_ok ]; then
            touch /mnt/two_ok
        fi
    else
        if [ ! -e /mnt/three_ok ]; then
            touch /mnt/three_ok
        fi
    fi

    umount <flag partition>

If Linux doesn't update the **flags** partition, the system will revert back to the previous *rootfs* on the next boot because of the `_tried` file written by u-boot. 

### Real code

A working implementation for [Yocto][yocto] built systems can be found in this recipe [github.com/jumpnow/meta-overo/tree/krogoth/recipes-support/system-upgrader][system-upgrader].

Here is an example `uEnv.txt` for a Gumstix Overo optimized somewhat knowing that **p2** is the default root partition.

    root@overo:~# cat /mnt/fat/uEnv.txt

    rootpart=0:2
    flagpart=0:5
    bootdir=/boot
    bootfile=zImage
    console=ttyO2,115200n8
    fdtaddr=0x88000000
    fdtfile=omap3-overo-storm-tobi.dtb
    loadaddr=0x82000000
    mmcroot=/dev/mmcblk0p2 ro
    mmcrootfstype=ext4 rootwait
    mmcargs=setenv bootargs console=${console} root=${mmcroot} rootfstype=${mmcrootfstype}
    loadfdt=load mmc ${rootpart} ${fdtaddr} ${bootdir}/${fdtfile}
    loadimage=load mmc ${rootpart} ${loadaddr} ${bootdir}/${bootfile}
    boot_three=setenv rootpart 0:3; setenv mmcroot /dev/mmcblk0p3 ro
    findroot=\
        if test -e mmc ${flagpart} three; then \
            if test -e mmc ${flagpart} three_ok; then \
                run boot_three; \
            elif test ! -e mmc ${flagpart} three_tried; then \
                fatwrite mmc ${flagpart} ${loadaddr} three_tried 4; \
                run boot_three; \
            fi; \
        elif test -e mmc ${flagpart} two; then \
            if test ! -e mmc ${flagpart} two_ok; then \
                if test -e mmc ${flagpart} two_tried; then \
                    run boot_three; \
                else \
                    fatwrite mmc ${flagpart} ${loadaddr} two_tried 4; \
                fi; \
            fi; \
        fi;
    uenvcmd=\
        run findroot; \
        echo Using root partition ${rootpart}; \
        if run loadfdt; then \
            echo Loaded ${fdtfile}; \
            if run loadimage; then \
                run mmcargs; \
                bootz ${loadaddr} - ${fdtaddr}; \
            fi; \
        fi;


The data being written in the *fatwrite* commands is irrelevant since the implementation only cares about file existence.


An example upgrade run over an ssh session looks like this

    root@overo:~# ls -l /data
    total 97656
    drwx------ 2 root root    16384 Jul  9 13:49 lost+found
    -rw-r--r-- 1 root root 56664116 Jul  9 14:50 qt5-image-overo.tar.xz

    root@overo:~# sysupgrade.sh /data/qt5-image-overo.tar.xz
    Finding the current root partition : /dev/mmcblk0p3
    The new root will be : /dev/mmcblk0p2
    Checking the new root partition size : OK
    Checking for a /dev/mmcblk0p5 partition : OK
    Checking the /dev/mmcblk0p5 flag partition size : OK
    Check that /dev/mmcblk0p5 is not in use : OK
    Checking if /mnt/upgrade mount point exists : OK
    Checking that /mnt/upgrade is not in use : OK
    Formatting partition /dev/mmcblk0p2 as ext4 : OK
    Mounting /dev/mmcblk0p2 on /mnt/upgrade : OK
    Extracting new root filesystem /data/qt5-image-overo.tar.xz to /mnt/upgrade : OK
    Copying config files from current system : OK
    Unmounting /dev/mmcblk0p2 : OK
    Mounting the flag partition /dev/mmcblk0p5 on /mnt/upgrade : OK
    Removing old flag files for partition two : OK
    Creating file /mnt/upgrade/two : OK
    Deleting file /mnt/upgrade/three : OK
    Removing remaining flag files for partition three : OK
    Unmounting /dev/mmcblk0p5 from /mnt/upgrade : OK

    A new system was installed onto /dev/mmcblk0p2

    Reboot to use the new system.

The upgrade script took about 90 seconds and the system was completely usable while it was running.

On the first boot into the new system, the output from the *bootpart-flags* script looks like this

    ...
    Finding the current root partition : /dev/mmcblk0p2
    Checking there is a /dev/mmcblk0p5 partition : OK
    Checking that /dev/mmcblk0p5 is not in use : OK
    Checking if /mnt/bootflags mount point exists : NO
    Attempting to create mount point /mnt/bootflags : OK
    Mounting /dev/mmcblk0p5 read-only on /mnt/bootflags : OK
    Checking flag files on /dev/mmcblk0p5 : OK
    Unmounting /dev/mmcblk0p5 : OK
    Mounting /dev/mmcblk0p5 read-write on /mnt/bootflags : OK
    Updating flags partition : OK
    Unmounting /dev/mmcblk0p5 : OK
    ...

On a subsequent boot this is the output of the *bootpart-flags* script

    ...
    Finding the current root partition : /dev/mmcblk0p2
    Checking there is a /dev/mmcblk0p5 partition : OK
    Checking that /dev/mmcblk0p5 is not in use : OK
    Checking if /mnt/bootflags mount point exists : OK
    Checking that /mnt/bootflags is not in use : OK
    Mounting /dev/mmcblk0p5 read-only on /mnt/bootflags : OK
    Checking flag files on /dev/mmcblk0p5 : OK
    Unmounting /dev/mmcblk0p5 : OK
    Boot flags are up to date
    ...

The system can be manually reverted using the `sysrevert.sh` script

    root@overo:~# sysrevert.sh
    Finding the current root partition : OK
    Current rootfs : /dev/mmcblk0p2
    New rootfs : /dev/mmcblk0p3
    Mounting new rootfs at /mnt/upgrade : OK
    Sanity checking new rootfs : OK
    Unmounting the new rootfs : OK
    Checking there is a /dev/mmcblk0p5 partition : OK
    Checking that /dev/mmcblk0p5 is not in use : OK
    Checking if /mnt/bootflags mount point exists : OK
    Checking that /mnt/bootflags is not in use : OK
    Mounting /dev/mmcblk0p5 read-write on /mnt/bootflags : OK
    Updating flags partition : OK
    Unmounting /dev/mmcblk0p5 : OK
    Rootfs on next boot will be /dev/mmcblk0p3

After reboot

    ...
    Finding the current root partition : /dev/mmcblk0p3
    Checking there is a /dev/mmcblk0p5 partition : OK
    Checking that /dev/mmcblk0p5 is not in use : OK
    Checking if /mnt/bootflags mount point exists : OK
    Checking that /mnt/bootflags is not in use : OK
    Mounting /dev/mmcblk0p5 read-only on /mnt/bootflags : OK
    Checking flag files on /dev/mmcblk0p5 : OK
    Unmounting /dev/mmcblk0p5 : OK
    Mounting /dev/mmcblk0p5 read-write on /mnt/bootflags : OK
    Updating flags partition : OK
    Unmounting /dev/mmcblk0p5 : OK
    ...


[gumstix]: https://www.gumstix.com/
[beaglebone]: https://beagleboard.org/
[uboot]: https://en.wikipedia.org/wiki/Das_U-Boot
[busybox]: https://en.wikipedia.org/wiki/BusyBox
[hush]: http://www.denx.de/wiki/view/DULG/CommandLineParsing#Section_14.2.17.2.
[system-upgrader]: https://github.com/jumpnow/meta-overo/tree/krogoth/recipes-support/system-upgrader
[yocto]: http://www.yoctoproject.org
[overo-build]: http://www.jumpnowtek.com/gumstix-linux/Overo-Systems-with-Yocto.html
