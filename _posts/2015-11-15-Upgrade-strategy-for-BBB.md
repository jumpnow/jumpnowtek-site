---
layout: post
title: Upgrading BeagleBone Black Systems
description: "Implementing a simple upgrade strategy for deployed BBB systems"
date: 2015-11-19 18:40:00
categories: beaglebone 
tags: [linux, beaglebone, upgrade]
---

A simple upgrade strategy for deployed BeagleBone Black systems running off the *eMMC*.

Sample implementation scripts can be found in this [github project][bbb-updater].

This is a work in progress.

### Background

The core idea is nothing new. There will be two *rootfs* partitions, one active and potentially **read-only** and the other inactive and not mounted.

The upgrade will mount and install the new *rootfs* on the non-active partition and then make whatever changes are necessary to let the bootloader know which partition to use on the next boot. 

The current Rev C BBBs have a 4GB *eMMC*. Older revisions had a 2GB *eMMC*, but since projects I'm working on assume a Rev C. That's what I'll do here. 

The BBB projects I work on tend to be small, dedicated systems where there is more then enough space on the *eMMC* to support a multiple *rootfs* strategy.

The largest BBB system I've worked on included an X11 desktop to support a full-screen Java GUI application. The uncompressed image was still under *250MB* as a running system.

The distributable image file for that project was less then *80MB* as a compressed tarball making full image network downloads reasonable.

### Assumptions

I'm making some assumptions that might be more restrictive then necessary.

1. The upgrade is a full *rootfs* upgrade, not just select packages using a package manager.
2. No dependencies other then the [BusyBox][busybox] shell and some basic disk utilities.
3. The system is currently running off the *eMMC*.
4. The running *rootfs* will be the fallback if the upgrade fails for any reason.
5. The running *rootfs* is **read-only**.
6. The *boot* partition is **read-only**.
7. The *eMMC* has already been partitioned appropriately with some initial install scripts.
8. The upgrade is allowed to modify files on a fourth partition of the *eMMC*.
9. There is temporary space available on some writable partition of the *eMMC* for the compressed tarball.
10. No modifications to standard *u-boot*. (Currently using 2015.07).


### Downloading

An actual implementation will have to handle the downloading and validation of the new *rootfs* tarball.

The new image file might be coming from a USB drive or it could be coming over the network.

System upgrades might happen automatically or they might be user initiated.

There also needs to be some sort of validation that the image file is not corrupted (a checksum) and that the image is appropriate for this system.

I'm going to skip over this part since those kinds of details tend to be project specific. 

### Implementation

*Assumption 8* assumed an initial install previously setup some partitions on the *eMMC*.

Here's a potential partitioning 
 
    root@bbb:~/emmc# fdisk -l /dev/mmcblk1
    Disk /dev/mmcblk1: 3.7 GiB, 3925868544 bytes, 7667712 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xc3617200
    
    Device         Boot   Start     End Sectors  Size Id Type
    /dev/mmcblk1p1 *        128  131199  131072   64M  c W95 FAT32 (LBA)
    /dev/mmcblk1p2       133120 2230271 2097152    1G 83 Linux
    /dev/mmcblk1p3      2230272 4327423 2097152    1G 83 Linux
    /dev/mmcblk1p4      4327424 7667711 3340288  1.6G  5 Extended
    /dev/mmcblk1p5      4329472 4460543  131072   64M  c W95 FAT32 (LBA)
    /dev/mmcblk1p6      4462592 7667711 3205120  1.5G 83 Linux


The two *rootfs* partitions for this system would be `/dev/mmcblk0p2` and `/dev/mmcblk0p3`.

Some things to check

1. On which partition is the current root running?
2. Is the *eMMC* partitioned appropriately?
3. Do we have a writable location to flag the *rootfs* partition switch?

There are some subtleties to be handled, but nothing too difficult.

Installing the *rootfs* from a tarball once we know the partition is four steps

1. Format the partition as ext4
2. Mount the partition at a temporary location
3. Untar the new *rootfs*
4. Unmount the partition

The actual code will be something like this (without any error handling)

    # mkfs.ext4 -q <new-root-partition>
    # mount <new-root-partition> /mnt
    # tar -C /media -xJf <image-file>.tar.xz
    # umount <new-root-partition>

Additional data from the current *rootfs* might want to be copied over to the new *rootfs* before it is unmounted (ssh keys, etc...) The assumption is the *rootfs* is **read-only** when running so any changes have to be made now.

The final step is updating the bootloader so that it knows about the new *rootfs*.

A `uEnv.txt` bootloader command file is typically used with BBB systems to customize the boot process. 

The `uEnv.txt` file lets you specify the kernel and *dtb* and allows passing parameters to the kernel including the type and location of the *rootfs*.

The `uEnv.txt` file is located on the boot partition of the *eMMC* which according to *Assumption 5* is to be considered **read-only**. So we can't modify `uEnv.txt` directly.

*u-boot* runs a [Hush][hush] shell that lets us do some simple scripting. 

Some of the things that can be done with the *u-boot* shell

* Test whether a file exists on FAT or Linux ext partitions
* Create new files on a FAT partition

What cannot be done

* Delete or rename a file on any type of partition

The plan is to use a small dedicated partition `/dev/mmcblk0p5` formatted as FAT for some flag files for u-boot. I'm going to call this the **flags** partition.

There will be at most three flag files at any one time.

If `/dev/mmcblk0p2` is the *rootfs*, the files would be

    two
    two_tried
    two_ok

or if `/dev/mmcblk0p3` is the *rootfs*, they would be

    three
    three_tried
    three_ok


The upgrade script will wipe all files on the **flags** partition, make sure it's formatted as FAT.

The file `two` or `three` indicates the partition that should be used. This file is managed by the upgrade script.

`two_tried` or `three_tried` is a flag to u-boot that it has tried this partition before. This file is managed by u-boot and ensures u-boot won't keep retrying a partition that doesn't boot.

`two_ok` or `three_ok` is a flag to u-boot that the partition is ok to use. This file is managed by Linux.


Here's some psuedo code for u-boot use of the **flags** partition

    if test -e two then
        if test -e two_ok then
            boot two
        elif test -e two_tried then
            boot three
        else
            write two_tried
            boot two
		fi
    else test -e three then
        if test -e three_ok then
            boot three
        elif test -e three_tried then
            boot two
        else
            write three_tried
            boot three
		fi
	fi


Here is an example `uEnv.txt` implementation with some optimizations knowing *boot_two* is the default.

    rootpart=1:2
    flagpart=1:5
    bootdir=/boot
    bootfile=zImage
    console=ttyO0,115200n8
    fdtaddr=0x88000000
    fdtfile=bbb-nohdmi.dtb
    loadaddr=0x82000000
    mmcroot=/dev/mmcblk0p2 ro
    mmcrootfstype=ext4 rootwait
    optargs=consoleblank=0
    mmcargs=setenv bootargs console=${console} ${optargs} root=${mmcroot} rootfstype=${mmcrootfstype}
    loadfdt=load mmc ${rootpart} ${fdtaddr} ${bootdir}/${fdtfile}
    loadimage=load mmc ${rootpart} ${loadaddr} ${bootdir}/${bootfile}
    boot_three=setenv rootpart 1:3; setenv mmcroot /dev/mmcblk0p3 ro
    findroot=\
        if test -e mmc $flagpart three; then \
            if test -e mmc $flagpart three_ok; then \
                run boot_three; \
            elif test ! -e mmc $flagpart three_tried; then \
                fatwrite mmc $flagpart $loadaddr three_tried 4; \
                run boot_three; \
            fi; \
        elif test -e mmc $flagpart two; then \
            if test ! -e mmc $flagpart two_ok; then \
                if test -e mmc $flagpart two_tried; then \
                    run boot_three; \
                else \
                    fatwrite mmc $flagpart $loadaddr two_tried 4; \
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


Linux will run a script like this sometime before shutdown to ensure that an 'ok' file is written to the **flags** partition for the next boot.

    #!/bin/sh
	
    mount /dev/mmcblk0p5 on /mnt

    if <current rootfs is /dev/mmcblk0p2> then
        if [ ! -e /mnt/two ]; then
            touch /mnt/two
        fi

        if [ ! -e /mnt/two_ok ]; then
            touch /mnt/two_ok
        fi

        rm -rf /mnt/three*
    else
        if [ ! -e /mnt/three ]; then
            touch /mnt/three
        fi
	
     if [ ! -e /mnt/three_ok ]; then
            touch /mnt/three_ok
        fi
	
        rm -rf /mnt/two*
    fi

    umount /dev/mmcblk0p5


### Issues / Improvements / TODOs

1. `uEnv.txt` could add some additional checks so that if it doesn't find a kernel or *dtb* on the partition it is supposed to boot from it will automatically fall back to the other partition. This is really the job of the upgrade script though.

2. The two `/dev/mmcblkboot` partitions on the *eMMC* seem ideal for placing the *flag* file instead of a fifth partition.
 
  * Can the `/dev/mmcblkboot` partitions be accessed from the u-boot *Hush* shell?
  * Can we format the `/dev/mmcblkboot` partitions as ext4 or FAT so we can test for a file using the shell?


[busybox]: https://en.wikipedia.org/wiki/BusyBox
[hush]: http://www.denx.de/wiki/view/DULG/CommandLineParsing#Section_14.2.17.2.
[bbb-upgrader]: https://github.com/jumpnow/bbb-upgrader
