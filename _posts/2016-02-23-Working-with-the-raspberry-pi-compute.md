---
layout: post
title: Working with the Raspberry Pi Compute Board
description: "Miscellaneous notes regarding the RPi compute"
date: 2017-01-16 14:10:00
categories: rpi
tags: [linux, rpi compute, yocto]
---

I'm building my [Raspberry Pi Compute][rpi-compute] Linux systems using tools from the [Yocto Project][yocto] and some specific RPi instructions [here][rpi-yocto].

Make sure to set the **MACHINE** variable to *raspberrypi* in `local.conf`.

### Copying the system to the eMMC

The same *copy* scripts described in the [instructions linked above][rpi-yocto] will also work to copy the files directly to the RPi Compute eMMC.

First you need to mount the RPi eMMC as *disk* device on your workstation using using the `rpiboot` utility from the [github.com/raspberrypi/tools][rpi-tools] project.

Instructions for obtaining and building `rpiboot` are here : [Flashing the Compute Module eMMC][rpiboot-instructions]

Here is the *TLDR* version

Install the *libusb-1.0-dev* dependency if you don't already have it 

    scott@fractal:~/rpi$ sudo apt-get install libusb-1.0-0-dev 

Then fetch and build the `rpiboot` utility

    scott@octo:~/rpi$ git clone git://github.com/raspberrypi/usbboot.git

    scott@octo:~/rpi$ cd usbboot

    scott@fractal:~/rpi/usbboot$ make && sudo make install


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

Put the RPi Compute `J4` jumper to the *USB Slave Enable* position, and plug the `J15` USB cable to the workstation and power the board through the `J2` USB connector.

Now run `rpiboot`. 

    scott@fractal:~/rpi/usbboot$ sudo rpiboot
    Waiting for BCM2835 ...
    Initialised device correctly
    Found serial number 0
    Found serial = 0: writing file ./usbbootcode.bin
    Successful read 4 bytes
    Waiting for BCM2835 ...
    Initialised device correctly
    Found serial number 1
    Found serial = 1: writing file ./msd.elf
    Successful read 4 bytes

When `rpiboot` exits, there should be a new drive, `/dev/sdc` on my system.

    scott@fractal:~/rpi/usbboot$ lsblk
    NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda      8:0    0 931.5G  0 disk
    ├─sda1   8:1    0  93.1G  0 part /
    ├─sda2   8:2    0 186.3G  0 part /home
    ├─sda3   8:3    0  29.8G  0 part [SWAP]
    ├─sda4   8:4    0   100G  0 part /oe4
    ├─sda5   8:5    0   100G  0 part /br5
    ├─sda6   8:6    0   100G  0 part /oe6
    ├─sda7   8:7    0   100G  0 part /oe7
    ├─sda8   8:8    0   100G  0 part /oe8
    └─sda9   8:9    0   100G  0 part /oe9
    sdc      8:32   1   3.7G  0 disk
    ├─sdc1   8:33   1    64M  0 part
    └─sdc2   8:34   1   3.6G  0 part

Initialize the host environment for the *copy* scripts

    scott@fractal:~/rpi/usbboot$ export OETMP=/oe8/rpi1/tmp-morty
    scott@fractal:~/rpi/usbboot$ export MACHINE=raspberrypi
    scott@fractal:~/rpi/usbboot$ cd ../meta-rpi/scripts/

Format the eMMC (this only needs to be done once) 

The `mk2parts` script creates the minimum two partitions.

    scott@fractal:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdc

Use the `copy_boot.sh` script to format the first partition as a *FAT* filesystem and copy the bootfiles. 

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdc

Use the `copy_rootfs.sh` script to format the second partition as *ext4* and copy the rootfs.

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdc qt5 cm1


Power off, move the `J4` jumper to the *Slave Boot Disable* position and remove the `J15` USB cable.

Then power up the system again and you should boot into the console image.

Watching the boot with a [serial console][rpi-serial-console]

    [    0.000000] Booting Linux on physical CPU 0x0
    [    0.000000] Initializing cgroup subsys cpuset
    [    0.000000] Initializing cgroup subsys cpu
    [    0.000000] Initializing cgroup subsys cpuacct
    [    0.000000] Linux version 4.4.43 (scott@fractal) (gcc version 6.2.0 (GCC) ) #1 Mon Jan 16 05:38:41 EST 2017
    [    0.000000] CPU: ARMv6-compatible processor [410fb767] revision 7 (ARMv7), cr=00c5387d
    [    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT nonaliasing instruction cache
    [    0.000000] Machine model: Raspberry Pi Compute Module Rev 1.0

    ...

    Starting syslogd/klogd: done

    Poky (Yocto Project Reference Distro) 2.2.1 cm1 /dev/ttyAMA0

    cm1 login: root

    root@cm1:~# uname -a
    Linux cm1 4.4.43 #1 Mon Jan 16 05:38:41 EST 2017 armv6l armv6l armv6l GNU/Linux

    root@cm1:~# free
                  total        used        free      shared  buff/cache   available
    Mem:         445020       18740      386868         172       39412      403608
    Swap:             0           0           0

    root@cm1:~# df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/root       3.5G  626M  2.7G  19% /
    devtmpfs        214M     0  214M   0% /dev
    tmpfs           218M  116K  218M   1% /run
    tmpfs           218M   56K  218M   1% /var/volatile

And if you had an HDMI display attached, this would show Qt5 QML apps work

    root@cm1:~# qqtest

Using an adapter board, some jumper wires and the `dt-blob.bin` as described on the Raspberry Pi [CMIO-CAMERA][rpi-cm-camera] page, the camera module works fine. The [raspicam][raspicam] tools operate just like on the other RPi boards.

The *Compute Module* supports two cameras, but I only have one camera currently.

I do have a couple of the new [v2 camera modules][camera-module-v2] on order.

TODO: Start generating my own device trees blobs for the Compute Module GPU.



[yocto]: https://www.yoctoproject.org
[rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[rpi-compute]: https://www.raspberrypi.org/products/compute-module/
[rpi-tools]: https://github.com/raspberrypi/tools
[rpiboot-instructions]: https://www.raspberrypi.org/documentation/hardware/computemodule/cm-emmc-flashing.md
[rpi-serial-console]: http://www.jumpnowtek.com/rpi/RPi-Serial-Console.html
[rpi-cm-camera]: https://www.raspberrypi.org/documentation/hardware/computemodule/cmio-camera.md
[raspicam]: https://www.raspberrypi.org/documentation/raspbian/applications/camera.md
[camera-module-v2]: https://www.raspberrypi.org/products/camera-module-v2/ 