---
layout: post
title: Working with the Raspberry Pi Compute Board
description: "Miscellaneous notes regarding the RPi compute"
date: 2017-04-10 05:40:00
categories: rpi
tags: [linux, rpi compute, yocto]
---

I'm building my [Raspberry Pi Compute3][rpi-compute3] Linux systems using tools from the [Yocto Project][yocto] and some specific RPi instructions [here][rpi-yocto].

Make sure to set the **MACHINE** variable to *raspberrypi2* in `local.conf`.

### Copying the system to the eMMC

The same *copy* scripts described in the [instructions linked above][rpi-yocto] will also work to copy the files directly to the RPi Compute eMMC.

First you need to mount the RPi eMMC as *disk* device on your workstation using using the `rpiboot` utility from the [github.com/raspberrypi/tools][rpi-tools] project.

Instructions for obtaining and building `rpiboot` are here : [Flashing the Compute Module eMMC][rpiboot-instructions]

Here is the *TLDR* version

Install the *libusb-1.0-dev* dependency if you don't already have it 

    scott@fractal:~/rpi$ sudo apt-get install libusb-1.0-0-dev 

Then fetch and build the `rpiboot` utility

    scott@fractal:~/rpi$ git clone git://github.com/raspberrypi/usbboot.git

    scott@fractal:~/rpi$ cd usbboot

    scott@fractal:~/rpi/usbboot$ make


Here's the disk situation on the workstation before mounting the RPi eMMC.

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


Put the RPi Compute `J4` jumper to the *USB Slave Enable* position, and plug the `J15` USB cable to the workstation and power the board through the `J2` USB connector.

Now run `rpiboot`. 

    scott@fractal:~/rpi/usbboot$ sudo ./rpiboot
    Waiting for BCM2835/6/7
    Sending bootcode.bin
    Successful read 4 bytes
    Waiting for BCM2835/6/7
    Second stage boot server
    File read: start.elf
    Second stage boot server done

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

    scott@fractal:~/rpi/usbboot$ export OETMP=/oe4/rpi/tmp-morty
    scott@fractal:~/rpi/usbboot$ export MACHINE=raspberrypi2
    scott@fractal:~/rpi/usbboot$ cd ../meta-rpi/scripts/

Format the eMMC (this only needs to be done once) 

The `mk2parts` script creates the minimum two partitions.

    scott@fractal:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdc

Use the `copy_boot.sh` script to format the first partition as a *FAT* filesystem and copy the bootfiles. 

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdc

Use the `copy_rootfs.sh` script to format the second partition as *ext4* and copy the rootfs.

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdc qt5 cm3


Power off, move the `J4` jumper to the *Slave Boot Disable* position and remove the `J15` USB cable.

Then power up the system again and you should boot into the console image.

Watching the boot with a [serial console][rpi-serial-console]

    Poky (Yocto Project Reference Distro) 2.2.1 cm3 /dev/ttyAMA0

    cm3 login: root
    
    root@cm3:~# uname -a
    Linux cm3 4.9.20 #1 SMP Sun Apr 9 06:31:32 EDT 2017 armv7l armv7l armv7l GNU/Linux

    root@cm3:~# free
                  total        used        free      shared  buff/cache   available
    Mem:         945524       15492      912304         148       17728      908800
    Swap:             0           0           0

    root@cm3:~# df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/root       3.5G  626M  2.7G  19% /
    devtmpfs        458M     0  458M   0% /dev
    tmpfs           462M  100K  462M   1% /run
    tmpfs           462M   48K  462M   1% /var/volatile


And if you had an HDMI display attached, this would show Qt5 QML apps work

    root@cm3:~# qqtest

Using an adapter board, some jumper wires and the `dt-blob.bin` as described on the Raspberry Pi [CMIO-CAMERA][rpi-cm-camera] page, the camera module works fine. The [raspicam][raspicam] tools operate just like on the other RPi boards.

The *Compute Module* supports two cameras, but I only have one camera currently.

I do have a couple of the new [v2 camera modules][camera-module-v2] on order.

TODO: Start generating my own device trees blobs for the Compute Module GPU.



[yocto]: https://www.yoctoproject.org
[rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[rpi-compute3]: https://www.raspberrypi.org/products/compute-module-3/
[rpi-tools]: https://github.com/raspberrypi/tools
[rpiboot-instructions]: https://www.raspberrypi.org/documentation/hardware/computemodule/cm-emmc-flashing.md
[rpi-serial-console]: http://www.jumpnowtek.com/rpi/RPi-Serial-Console.html
[rpi-cm-camera]: https://www.raspberrypi.org/documentation/hardware/computemodule/cmio-camera.md
[raspicam]: https://www.raspberrypi.org/documentation/raspbian/applications/camera.md
[camera-module-v2]: https://www.raspberrypi.org/products/camera-module-v2/ 