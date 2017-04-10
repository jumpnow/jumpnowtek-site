---
layout: post
title: Working with the Gumstix Pi Compute Dev Board
date: 2017-04-10 05:40:00
categories: rpi
tags: [linux, gumstix, rpi compute, yocto]
---

[Gumstix][gumstix] makes a [RPi Compute Module][rpi-compute3] development board that can be used as an alternative to the [Compute Module IO Board V3][rpi-compute-module-dev-kit] from the Raspberry Pi foundation.

The Gumstix [Pi Compute Development Board][gumstix-pi-dev-board] is just one example of a custom board that can be designed using [Gepetto][gumstix-gepetto] their online board design/layout tool.

I am using [Yocto Project][yocto] tools build the software stack for the *CM*, similar to the way I build systems for the other RPi boards.

Some instructions for that can be found [here][jumpnow-yocto-rpi].

When it comes time to flash the image onto the RPi, you can use the RPi Foundation's *Compute Module Development Kit* if you have one of those boards. Instructions for flashing using that board can be found [here][jumpnow-rpi-compute].

You cannot use the Gumstix *Pi Dev Board* the same way since it does not have the circuitry to put the *CM* into a mode where a host computer can directly access the flash as a block device.

Instead, Gumstix sells a [Pi Fast Flash Board][gumstix-pi-fast-flash-board] just for flashing the *RPi CM*. The *Fast Flash Board* does the equivalent of the **J4 Jumper** in the *USB Slave* position on the *RPi Compute Module Dev* board

The Gumstix *Fast Flash Board* is much more convenient when you are flashing multiple boards in succession.

Assuming then that you have built your custom Yocto image using the instructions linked earlier. 

And also assuming you have already built the RaspberryPi tool `rpiboot` from the [RPi Compute][jumpnow-rpi-compute] instructions.

Then steps to flash the *RPi CM3* are as follows

Install the *RPi CM3* on the Gumstix *Pi Fast Flash Board*

Connect a USB cable from the *Pi Fast Flash Board* to the Host computer. (I did not require separate power, the USB was enough).

Run the `rpiboot` utility, to bring up the *CM* as a mass storage device.

    scott@fractal:~/rpi$ sudo ./rpiboot
    Waiting for BCM2835/6/7
    Sending bootcode.bin
    Successful read 4 bytes
    Waiting for BCM2835/6/7
    Second stage boot server
    File read: start.elf
    Second stage boot server done


When `rpiboot` exits, there should be a new device, `/dev/sdc` on my system.

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


If this is the first time flashing your *RPi CM* the device probably won't have any partitions.

This particular *CM* has already been partitioned, but there is no harm in re-partitioning. 

To partition the RPi *eMMC*, there is a simple 2 partition script in `meta-rpi/scripts`.

    scott@fractal:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdc


Then after making sure the environment variables are set correctly you can use the *copy_* scripts from   the *meta-rpi* repository to copy the bootloader and O/S.

The *copy_* scripts use a temporary mount point `/media/card` on the workstation to use when copying files. Create it first if it does not already exist.

    scott@fractal:~/rpi$ sudo mkdir -p /media/card

Then export some environment variables for the scripts. (See the [instructions][jumpnow-yocto-rpi] for an explanation.) 

    scott@fractal:~/rpi/meta-rpi/scripts$ export OETMP=/oe4/rpi/tmp-morty
    scott@fractal:~/rpi/meta-rpi/scripts$ export MACHINE=raspberrypi2

The boot partition

    scott@fractal:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdc

    OETMP: /oe4/rpi/tmp-morty
    Formatting FAT partition on /dev/sdc1
    mkfs.fat 3.0.28 (2015-05-16)
    Mounting /dev/sdc1
    Copying bootloader files
    Creating overlay directory
    Copying overlay dtbs
    Renaming overlay dtbs to dtbos
    Copying dtbs
    Copying kernel
    Unmounting /dev/sdc1
    Done

If you want to use the camera (see below), now is a good time to copy the `dt-blob.bin`

    scott@fractal:~/rpi/meta-rpi/scripts$ sudo mount /dev/sdc1 /media/card
    scott@fractal:~/rpi/meta-rpi/scripts$ sudo cp ~/rpi/dt-blob.bin /media/card
    scott@fractal:~/rpi/meta-rpi/scripts$ sudo umount /dev/sdc1

The root file system

    scott@fractal:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdc console cm

    OETMP: /oe4/rpi/tmp-morty
    IMAGE: qt5
    HOSTNAME: cm3

    Formatting /dev/sdc2 as ext4
    Mounting /dev/sdc2
    Extracting qt5-image-raspberrypi2.tar.xz to /media/card
    Writing cm3 to /etc/hostname
    Unmounting /dev/sdc2
    Done


You can now move the *RPi CM3* to the *Pi Dev Board* and boot it.

One of the nice features of the *Pi Dev Board* is the built-in USB serial console.

    ...
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


The *qt5-image* has some demo apps you can use to test that Qt5 apps will run.

For example here is a QML test, plug in an HDMI display and run this

    root@cm3:~# qqtest


The Gumstix *Pi Dev Board* has a camera connector that is more convenient to use with the official RPi camera modules because it does not require an extra adapter board or jumpers to connect power and I2C the way you need to do using the RPi compute board.

You do still need a `dt-blob.bin` to reconfigure some GPU pins for the camera. You can download the blob from the instructions [here][rpi-cm-camera].

Modify `config.txt` so the GPU can use the camera.

    root@cm3:~# mkdir /mnt/fat
    root@cm3:~# mount /dev/mmcblk0p1 /mnt/fat
    root@cm3:~# echo 'start_x=1' >> /mnt/fat/config.txt
    root@cm3:~# echo 'gpu_mem=128' >> /mnt/fat/config.txt
    root@cm3:~# reboot

  
After that you can use the [raspicam][raspicam] tools installed on either the of test images in `meta-rpi`.

    root@cm3:~# raspistill -t 0 -hf -vf


[gumstix]: http://www.gumstix.com
[rpi-compute3]: https://www.raspberrypi.org/products/compute-module-3/
[rpi-compute-module-dev-kit]: https://www.raspberrypi.org/products/compute-module-io-board-v3/
[gumstix-pi-dev-board]: https://store.gumstix.com/expansion/gumstix-pi-compute-dev-board.html
[gumstix-gepetto]: https://www.gumstix.com/geppetto/
[yocto]: https://www.yoctoproject.org
[jumpnow-yocto-rpi]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[jumpnow-rpi-compute]: http://www.jumpnowtek.com/rpi/Working-with-the-raspberry-pi-compute.html
[gumstix-pi-fast-flash-board]: https://store.gumstix.com/raspberry-pi-cm-fast-flash.html
[bbb-upgrades]: http://www.jumpnowtek.com/beaglebone/Upgrade-strategy-for-BBB.html
[rpi-cm-camera]: https://www.raspberrypi.org/documentation/hardware/computemodule/cmio-camera.md
[raspicam]: https://www.raspberrypi.org/documentation/raspbian/applications/camera.md
