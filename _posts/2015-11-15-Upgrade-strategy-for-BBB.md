---
layout: post
title: Upgrading BeagleBone Black Systems
description: "Implementing a simple upgrade strategy for deployed BBB systems"
date: 2015-11-16 10:50:00
categories: beaglebone 
tags: [linux, beaglebone, upgrade]
---

A simple upgrade strategy for deployed BeagleBone Black systems running off the *eMMC*.

This is a work in progress.

### Background

The core idea is that there will be two *rootfs* partitions, one active and potentially **read-only** and the other inactive and not mounted.

The upgrade will mount and install the new *rootfs* on the non-active partition and then make whatever changes are necessary to let the bootloader know which partition to use on the next boot. 

BBB projects I work on tend to be small, dedicated systems.

The current Rev C BBBs have a 4GB *eMMC*. Older revisions had a 2GB *eMMC*, but since projects I'm working on assume a Rev C. That's what I'll do here. 

The largest BBB system I've worked on included an X11 desktop to support a full-screen Java GUI application. The distributable image file for that project was less then *80MB* as a compressed tarball. 

That's not unreasonable for a network download.

Uncompressed that X11/Java image was under *250MB* as a running system.

So there is plenty of space on the BBB *eMMC* to support this multiple *rootfs* strategy.

### Assumptions

1. The upgrade is a full *rootfs* upgrade, not just select packages using a package manager.
2. The system is currently running off the *eMMC*.
3. The running *rootfs* will be the fallback if the upgrade fails.
4. The running *rootfs* is **read-only**.
5. The *boot* partition is **read-only**.
6. The *eMMC* has already been partitioned appropriately with some initial install scripts.
7. The upgrade is allowed to modify files on a fourth partition of the *eMMC*.
8. There is temporary space available on some writable partition of the *eMMC* for the compressed tarball.

9. No modifications to standard *u-boot*.


### Downloading

An actual implementation will have to handle the downloading and validation of the new *rootfs* tarball.

I'm going to skip over this part since the details will be project specific. 

For instance, the image file might be coming from a USB drive the user inserted or it could be coming over the network. System upgrades might happen automatically or they might be user initiated.

There also needs to be some sort of validation that the image file is not corrupted (a checksum) and that the image is appropriate for this system.

### Implementation

*Assumption 8* assumed an initial install previously setup some partitions on the *eMMC*.

Here's a potential partitioning 
 
    root@beaglebone:~# fdisk -l /dev/mmcblk0
    Disk /dev/mmcblk0: 3.7 GiB, 3925868544 bytes, 7667712 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disklabel type: dos
    Disk identifier: 0xc9abb9c2
    
    Device         Boot   Start     End Sectors  Size Id Type
    /dev/mmcblk0p1 *        128  131071  130944   64M  c W95 FAT32 (LBA)
    /dev/mmcblk0p2       131072 2228223 2097152    1G 83 Linux
    /dev/mmcblk0p3      2228224 4325375 2097152    1G 83 Linux
    /dev/mmcblk0p4      4325376 7667711 3342336  1.6G 83 Linux


The two *rootfs* partitions for this system would be `/dev/mmcblk0p2` and `/dev/mmcblk0p3`.

Figuring out which partition we should be using for the upgrade can be done with some shell scripting.

Some things to check

1. On which partition is the current root running?
2. Is the *eMMC* partitioned appropriately?
3. Do we have a writable location to flag the *rootfs* partition switch?

There are some subtleties to be handled, but nothing too difficult.

TODO: Insert script when it's cleaned up

Installing the *rootfs* from a tarball once we know the partition is 2 steps

1. Format the partition as ext4 to erase what was there previously
2. Untar the new *rootfs*

The actual code will be something like this (without any error handling)

    # mkfs.ext4 -q <new-root-partition>
    # mount <new-root-partition> /media
    # tar -C /media -xJf <image-file>.tar.xz
    # umount <new-root-partition>

Additional data from the current *rootfs* might want to be copied over to the new *rootfs* before it is unmounted (ssh keys, etc...) The assumption is the *rootfs* is **read-only** when running so any changes have to be made now.

The final step is updating the bootloader so that it knows about the new *rootfs*.

A `uEnv.txt` bootloader command file is used with BBB systems to customize the boot process. 

The `uEnv.txt` file lets you specify the kernel and *dtb* and allows passing parameters to the kernel including the type and location of the *rootfs*.

The `uEnv.txt` file is located on the boot partition of the *eMMC* which according to *Assumption 5* is to be considered **read-only**. So we can't modify `uEnv.txt`.

But *u-boot* runs a [Hush][hush] shell that lets us do some simple scripting. 

One of the things we can do in the u-boot shell is test for file existence. We can use this for the boolean choice of using partition 2 or 3 for the *rootfs*.

For this example, assuming `/dev/mmcblk0p4` is mounted as `/data`, the test file might be something like

    /data/active_root/three

If `uEnv.txt` sees this file it will use `/dev/mmcblk0p3` as the *rootfs*, otherwise it will use `/dev/mmcblk0p2`.

Here is a sample `uEnv.txt` that does this

    rootpart=1:2
    bootdir=/boot
    mmcroot=/dev/mmcblk0p2 ro
    mmcrootfstype=ext4 rootwait
    bootfile=zImage
    console=ttyO0,115200n8
    fdtaddr=0x88000000
    fdtfile=bbb-nohdmi.dtb
    loadaddr=0x82000000
    optargs=consoleblank=0
    mmcargs=setenv bootargs console=${console} ${optargs} root=${mmcroot} rootfstype=${mmcrootfstype}
    findrootpart=if test -e mmc 1:4 /active_root/three; then setenv rootpart 1:3; setenv mmcroot /dev/mmcblk0p3 ro; fi;
    loadfdt=load mmc ${rootpart} ${fdtaddr} ${bootdir}/${fdtfile}
    loadimage=load mmc ${rootpart} ${loadaddr} ${bootdir}/${bootfile}
    uenvcmd=run findrootpart; if run loadfdt; then echo Loaded ${fdtfile}; if run loadimage; then run mmcargs; bootz ${loadaddr} - ${fdtaddr}; fi; fi;
 

The test is *findrootpart*.

    findrootpart= \
        if test -e mmc 1:4 /active_root/three; then \
            setenv rootpart 1:3; \
            setenv mmcroot /dev/mmcblk0p3 ro; \
        fi; \

The variables that have to get modified are

* *rootpart* - the root partition as u-boot sees it
* *mmcroot* - the root partition to pass to the kernel


Those two variables have defaults that specify `/dev/mmcblk0p2` as the *rootfs*.

### Issues / Improvements / TODOs

1. The fourth partition is likely also used as the `/data` partition for applications and is subject to getting filled or corrupted. Maybe a 5 partition scheme makes more sense.

2. The two `/dev/mmcblkboot` partitions on the *eMMC* seem ideal for placing the *flag* file instead of a fifth partition.
 
  * Can the `/dev/mmcblkboot` partitions be accessed from the u-boot *Hush* shell?
  * Can we format the `/dev/mmcblkboot` partitions as ext4 or FAT?

3. `uEnv.txt` could add some checks so that if it doesn't find a kernel or *dtb* on the partition it thinks it should boot from it can automatically fall back to the other partition.

4. How does the user revert to the older rootfs if the new kernel loads but the systems doesn't finish booting for some reason?

[hush]: http://www.denx.de/wiki/view/DULG/CommandLineParsing#Section_14.2.17.2.
 

    





