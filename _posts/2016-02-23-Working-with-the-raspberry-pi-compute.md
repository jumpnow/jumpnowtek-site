---
layout: post
title: Working with the Raspberry Pi Compute Board
description: "Miscellaneous notes regarding the RPi compute"
date: 2016-02-23 10:30:00
categories: rpi
tags: [linux, rpi compute, yocto]
---

I'm building my [Raspberry Pi Compute][rpi-compute] Linux systems using tools from the [Yocto Project][yocto] and some specific RPi instructions [here][rpi-yocto].

### Copying the system to the eMMC

The same *copy* scripts described in the [instructions post][rpi-yocto] will also work to copy the files directly to the RPi Compute eMMC.

First you need to mount the RPi eMMC as *disk* device on your workstation using using the `rpiboot` utility from the [github.com/raspberrypi/tools][rpi-tools] project.

Instructions for obtaining and building `rpiboot` are here : [Flashing the Compute Module eMMC][rpiboot-instructions]

Here's the disk situation on the workstation before mounting the RPi eMMC.

    scott@octo:~/rpi/tools/usbboot$ lsblk
    NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda       8:0    0 931.5G  0 disk
    ├─sda1    8:1    0  93.1G  0 part /
    ├─sda2    8:2    0  93.1G  0 part /home
    ├─sda3    8:3    0  29.8G  0 part [SWAP]
    ├─sda4    8:4    0     1K  0 part
    ├─sda5    8:5    0   100G  0 part /oe5
    ├─sda6    8:6    0   100G  0 part /oe6
    ├─sda7    8:7    0   100G  0 part /oe7
    ├─sda8    8:8    0   100G  0 part /oe8
    ├─sda9    8:9    0   100G  0 part /oe9
    └─sda10   8:10   0 215.5G  0 part /oe10

Put the RPi Compute `J4` jumper to the *USB Slave* position, and plug the `J15` USB cable to the workstation.

Now run `rpiboot`. 

    scott@octo:~/rpi/tools/usbboot$ sudo ./rpiboot
    Waiting for BCM2835 ...
    Found serial = 0: writing file ./usbbootcode.bin
    Failed : 0x7Waiting for BCM2835 ...
    Found serial = 1: writing file ./msd.elf

When `rpiboot` exits, there should be a new drive, `/dev/sdc` on my system.

    scott@octo:~/rpi/tools/usbboot$ lsblk
    NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda       8:0    0 931.5G  0 disk
    ├─sda1    8:1    0  93.1G  0 part /
    ├─sda2    8:2    0  93.1G  0 part /home
    ├─sda3    8:3    0  29.8G  0 part [SWAP]
    ├─sda4    8:4    0     1K  0 part
    ├─sda5    8:5    0   100G  0 part /oe5
    ├─sda6    8:6    0   100G  0 part /oe6
    ├─sda7    8:7    0   100G  0 part /oe7
    ├─sda8    8:8    0   100G  0 part /oe8
    ├─sda9    8:9    0   100G  0 part /oe9
    └─sda10   8:10   0 215.5G  0 part /oe10
    sdc       8:32   1   3.7G  0 disk
    ├─sdc1    8:33   1    64M  0 part
    └─sdc2    8:34   1   3.6G  0 part

Initialize the host environment for the *copy* scripts

    scott@octo:~/rpi/build$ grep TMPDIR conf/local.conf
    TMPDIR = "/oe8/rpi/tmp-jethro"

    scott@octo:~/rpi/build$ export OETMP=/oe8/rpi/tmp-jethro
    scott@octo:~/rpi/build$ export MACHINE=raspberrypi
    scott@octo:~/rpi/build$ cd ../meta-rpi/scripts/

Format the eMMC (this only needs to be done once) 

The `mk2parts` script creates the minimum two partitions.

    scott@octo:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdc
    [sudo] password for scott:

    Working on /dev/sdc

    umount: /dev/sdc1: not mounted
    umount: /dev/sdc2: not mounted
    DISK SIZE – 3909091328 bytes

    Okay, here we go ...

    === Zeroing the MBR ===

    1024+0 records in
    1024+0 records out
    1048576 bytes (1.0 MB) copied, 0.512869 s, 2.0 MB/s

    === Creating 2 partitions ===

    Checking that no-one is using this disk right now ... OK

    Disk /dev/sdc: 3.7 GiB, 3909091328 bytes, 7634944 sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

    >>> Created a new DOS disklabel with disk identifier 0x1485162a.
    Created a new partition 1 of type 'W95 FAT32 (LBA)' and of size 64 MiB.
    /dev/sdc2: Created a new partition 2 of type 'Linux' and of size 3.6 GiB.
    /dev/sdc3:
    New situation:

    Device     Boot  Start     End Sectors  Size Id Type
    /dev/sdc1  *      8192  139263  131072   64M  c W95 FAT32 (LBA)
    /dev/sdc2       139264 7634943 7495680  3.6G 83 Linux

    The partition table has been altered.
    Calling ioctl() to re-read partition table.
    Syncing disks.

    === Done! ===

Format the first partition as a *FAT* filesystem and copy the bootfiles. 

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdc

    OETMP: /oe8/rpi/tmp-jethro
    Formatting FAT partition on /dev/sdc1
    mkfs.fat 3.0.28 (2015-05-16)
    Mounting /dev/sdc1
    Copying bootloader files
    Creating overlay directory
    Copying overlay dtbs
    Copying dtbs
    Copying kernel
    Unmounting /dev/sdc1
    Done

Format the second partition as *ext4* and copy the rootfs.

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdc console rpi

    OETMP: /oe8/rpi/tmp-jethro
    IMAGE: console
    HOSTNAME: rpi

    Formatting /dev/sdc2 as ext4
    /dev/sdc2 contains a ext4 file system labelled 'ROOT'
            last mounted on / on Wed Dec 31 19:00:01 1969
    Proceed anyway? (y,n) y
    Mounting /dev/sdc2
    Extracting console-image-raspberrypi.tar.bz2 to /media/card
    Writing hostname to /etc/hostname
    Unmounting /dev/sdc2
    Done

Power off, move the `J4` jumper to the *Boot Enable* position and remove the `J15` USB cable.

Then power up the system again and you should boot into the console image.

Watching the boot with a serial console

    [    0.000000] Booting Linux on physical CPU 0x0
    [    0.000000] Initializing cgroup subsys cpuset
    [    0.000000] Initializing cgroup subsys cpu
    [    0.000000] Initializing cgroup subsys cpuacct
    [    0.000000] Linux version 4.1.18 (scott@octo) (gcc version 5.2.0 (GCC) ) #1 Mon Feb 22 16:52:07 EST 2016
    [    0.000000] CPU: ARMv6-compatible processor [410fb767] revision 7 (ARMv7), cr=00c5387d
    [    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT nonaliasing instruction cache
    [    0.000000] Machine: BCM2708

    ...

    Starting syslogd/klogd: done
    
    Poky (Yocto Project Reference Distro) 2.0.1 rpi /dev/ttyAMA0
    
    rpi login: root

    root@rpi:~# uname -a
    Linux rpi 4.1.18 #1 Tue Feb 23 05:05:33 EST 2016 armv6l GNU/Linux

    root@rpi:~# free
                  total        used        free      shared  buff/cache   available
    Mem:         445372        9408      408448        1272       27516      409416
    Swap:             0           0           0

    root@rpi:~# df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/root       3.5G  379M  2.9G  12% /
    devtmpfs        214M     0  214M   0% /dev
    tmpfs           218M  1.2M  217M   1% /run
    tmpfs           218M   52K  218M   1% /var/volatile


That *console-image* is not customized for the *RPi Compute*, it tries to start a network, ntpd, etc... 

But it's very easy to create a custom image using Yocto from this point. 


[yocto]: https://www.yoctoproject.org
[rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[rpi-compute]: https://www.raspberrypi.org/products/compute-module/
[rpi-tools]: https://github.com/raspberrypi/tools
[rpiboot-instructions]: https://www.raspberrypi.org/documentation/hardware/computemodule/cm-emmc-flashing.md
