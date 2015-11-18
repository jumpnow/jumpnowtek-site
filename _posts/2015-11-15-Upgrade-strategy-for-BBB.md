---
layout: post
title: Upgrading BeagleBone Black Systems
description: "Implementing a simple upgrade strategy for deployed BBB systems"
date: 2015-11-18 17:46:00
categories: beaglebone 
tags: [linux, beaglebone, upgrade]
---

A simple upgrade strategy for deployed BeagleBone Black systems running off the *eMMC*.

This is a work in progress.

### Background

The core idea is that there will be two *rootfs* partitions, one active and potentially **read-only** and the other inactive and not mounted.

The upgrade will mount and install the new *rootfs* on the non-active partition and then make whatever changes are necessary to let the bootloader know which partition to use on the next boot. 

The current Rev C BBBs have a 4GB *eMMC*. Older revisions had a 2GB *eMMC*, but since projects I'm working on assume a Rev C. That's what I'll do here. 

BBB projects I work on tend to be small, dedicated systems.

The largest BBB system I've worked on included an X11 desktop to support a full-screen Java GUI application. 
The uncompressed image was under *250MB* as a running system.

There is enough space on the BBB *eMMC* to support a multiple *rootfs* strategy.

The distributable image file for that project was less then *80MB* as a compressed tarball making full image network downloads reasonable.

### Assumptions

I'm making some assumptions that might be more restrictive then necessary.

1. The upgrade is a full *rootfs* upgrade, not just select packages using a package manager.
2. The system is currently running off the *eMMC*.
3. The running *rootfs* will be the fallback if the upgrade fails.
4. The running *rootfs* is **read-only**.
5. The *boot* partition is **read-only**.
6. The *eMMC* has already been partitioned appropriately with some initial install scripts run from an SD card boot.
7. The upgrade is allowed to modify files on a fourth partition of the *eMMC*.
8. There is temporary space available on some writable partition of the *eMMC* for the compressed tarball.
9. Require only the [BusyBox][busybox] *Ash* shell and some basic disk utilities, no *Bash*, *Perl* or *Python*.
10. No modifications to standard *u-boot*.

If possible I would like to stay with an unmodified mainstream u-boot.

### Downloading

An actual implementation will have to handle the downloading and validation of the new *rootfs* tarball.

The new image file might be coming from a USB drive or it could be coming over the network.

System upgrades might happen automatically or they might be user initiated.

There also needs to be some sort of validation that the image file is not corrupted (a checksum) and that the image is appropriate for this system.

I'm going to skip over this part since the details will be project specific. 

### Implementation

*Assumption 8* assumed an initial install previously setup some partitions on the *eMMC*.

Here's a potential partitioning 
 
    root@bbb:~/emmc# fdisk -l /dev/mmcblk0
    Disk /dev/mmcblk0: 3.7 GiB, 3925868544 bytes, 7667712 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0x32e05668
    
    Device         Boot   Start     End Sectors  Size Id Type
    /dev/mmcblk0p1 *        128  131071  130944   64M  c W95 FAT32 (LBA)
    /dev/mmcblk0p2       131072 2228223 2097152    1G 83 Linux
    /dev/mmcblk0p3      2228224 4325375 2097152    1G 83 Linux
    /dev/mmcblk0p4      4325376 7667711 3342336  1.6G  5 Extended
    /dev/mmcblk0p5      4327424 4458495  131072   64M  c W95 FAT32 (LBA)
    /dev/mmcblk0p6      4460544 7667711 3207168  1.5G 83 Linux


The two *rootfs* partitions for this system would be `/dev/mmcblk0p2` and `/dev/mmcblk0p3`.

Figuring out which partition we should be using for the upgrade can be done with some shell scripting.

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
    two_success

or if `/dev/mmcblk0p3` is the *rootfs*, they would be

    three
    three_tried
    three_success


Here's how the **flags** partition will be managed.

The upgrade script will wipe all files on the **flags** partition, make sure it's formatted as FAT and write a single file either `two` or `three` depending on the new *rootfs*.

The u-boot script will use an algorithm like this to choose the u-boot partition to use for the *rootfs* on this boot.

All file operations done on the FAT formatted **flags** partition

    if test -e two then
        if test -e two_success then
            boot two
        elif test -e two_tried then
            boot three
        else
            write two_tried
            boot two
    else test -e three then
        if test -e three_success then
            boot three
        elif test -e three_tried
            boot two
        else
            write three_tried
            boot three

If this is the first time trying this *rootfs* partition a flag file '_tried' is written so the **flags** partition is not repeatedly used if it is failing for some reason.

Linux will run a pseudo code script like this sometime before shutdown to ensure that a '_success' file is written to the **flags** partition for the next boot.

    mount /dev/mmcblk0p5 on /mnt

    if <current rootfs is /dev/mmcblk0p2> then
        if [ ! -e /mnt/two ]; then
            touch /mnt/two
        fi

        if [ ! -e /mnt/two_success ]; then
            touch /mnt/two_success
        fi

        rm -rf /mnt/three*
    else
        if [ ! -e /mnt/three ]; then
            touch /mnt/three
        fi
	
     if [ ! -e /mnt/three_success ]; then
            touch /mnt/three_success
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

