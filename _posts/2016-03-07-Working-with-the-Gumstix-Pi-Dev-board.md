---
layout: post
title: Working with the Gumstix Pi Compute Dev Board
date: 2016-05-10 13:02:00
categories: rpi
tags: [linux, gumstix, rpi compute, yocto]
---

[Gumstix][gumstix] makes a [RPi Compute Module][rpi-compute] development board that can be used as an alternative to the [Compute Module Development Kit][rpi-compute-module-dev-kit] from the Raspberry Pi foundation.

The Gumstix [Pi Compute Development Board][gumstix-pi-dev-board] is just one example of a custom board that can be designed using [Gepetto][gumstix-gepetto] their online board design/layout tool.

I am using [Yocto Project][yocto] tools build the software stack for the *CM*, similar to the way I build systems for the other RPi boards.

Some instructions for that can be found [here][jumpnow-yocto-rpi].

When it comes time to flash the image onto the RPi, you can use the RPi Foundation's *Compute Module Development Kit* if you have one of those boards. Instructions for flashing using that board can be found [here][jumpnow-rpi-compute].

You cannot use the Gumstix *Pi Dev Board* the same way since it does not have the circuitry to put the *CM* into a mode where a host computer can directly access the flash as a block device.

Instead, Gumstix sells a [Pi Fast Flash Board][gumstix-pi-fast-flash-board] just for flashing the *RPi CM*. The *Fast Flash Board* does the equivalent of the **J4 Jumper** in the *USB Slave* position on the *RPi Compute Module Dev* board

The *Pi Fast Flash Board* is much more convenient when you are flashing multiple boards in succession.

Once you have an initial image on the *RPi CM* there are other methods you can use for updates or full-upgrades. For example, the method I'm using for [BeagleBone Black upgrades][bbb-upgrades] will work just as well with the *CM*.

Assuming then that you have built your custom Yocto image using the instructions linked earlier. 

And also assuming you have already built the RaspberryPi tool `rpiboot` from the [RPi Compute][jumpnow-rpi-compute] instructions.

Then steps to flash the *RPi CM* are as follows

Install the *RPi CM* on the Gumstix *Pi Fast Flash Board*

Connect a USB cable from the *Pi Fast Flash Board* to the Host computer. (I did not require separate power, the USB was enough).

Run the `rpiboot` utility, to bring up the *CM* as a mass storage device.


    scott@octo:~$ sudo rpiboot
    Waiting for BCM2835 ...
    Initialised device correctly
    Found serial number 0
    Found serial = 0: writing file /usr/share/rpiboot/usbbootcode.bin
    Failed : 0xd6f10f90Waiting for BCM2835 ...
    Initialised device correctly
    Found serial number 1
    Found serial = 1: writing file /usr/share/rpiboot/msd.elf
    Successful read 4 bytes

When `rpiboot` exits, there should be a new device, `/dev/sdc` on my system.

    scott@octo:~$ lsblk
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


If this is the first time flashing your *RPi CM* the device probably won't have any partitions.

This particular *CM* has already been partitioned, but there is no harm in re-partitioning. 

To partition the RPi *eMMC*, there is a simple 2 partition script in `meta-rpi/scripts`.

    scott@octo:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdc


Then after making sure the environment variables are set correctly you can use the *copy_* scripts from   the *meta-rpi* repository to copy the bootloader and O/S. 

    scott@octo:~/rpi/meta-rpi/scripts$ export OETMP=/oe9/rpi1/tmp-krogoth
    scott@octo:~/rpi/meta-rpi/scripts$ export MACHINE=raspberrypi

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdc

    OETMP: /oe9/rpi1/tmp-krogoth
    Formatting FAT partition on /dev/sdc1
    mkfs.fat 3.0.28 (2015-05-16)
    Mounting /dev/sdc1
    Copying bootloader files
    Creating overlay directory
    Copying overlay dtbs
    Renaming overlay dtbs
    Copying dtbs
    Copying kernel
    Unmounting /dev/sdc1
    Done


    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdc qt5 cm

    OETMP: /oe9/rpi1/tmp-krogoth
    IMAGE: qt5
    HOSTNAME: cm

    Formatting /dev/sdc2 as ext4
    /dev/sdc2 contains a ext4 file system labelled 'ROOT'
            last mounted on / on Wed Dec 31 19:00:01 1969
    Proceed anyway? (y,n) y
    Mounting /dev/sdc2
    Extracting qt5-image-raspberrypi.tar.bz2 to /media/card
    Writing cm to /etc/hostname
    Unmounting /dev/sdc2
    Done

If you want to use the camera (see below), now is a good time to copy the `dt-blob.bin`

    scott@octo:~/rpi/meta-rpi/scripts$ sudo mount /dev/sdc1 /media/card
    scott@octo:~/rpi/meta-rpi/scripts$ sudo cp ~/rpi/dt-blob.bin /media/card
    scott@octo:~/rpi/meta-rpi/scripts$ sudo umount /dev/sdc1


You can now move the *RPi CM* to the *Pi Dev Board* and boot it.

One of the nice features of the *Pi Dev Board* is the built-in USB serial console.

    ...
    Poky (Yocto Project Reference Distro) 2.1 cm /dev/ttyAMA0

    cm login: root

    root@cm:~# uname -a
    Linux cm 4.4.8 #1 Sun May 8 10:48:00 EDT 2016 armv6l armv6l armv6l GNU/Linux

    root@cm:~# free
                  total        used        free      shared  buff/cache   available
    Mem:         380104       13076      324852         180       42176      339252
    Swap:             0           0           0

    root@cm:~# df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/root       3.5G  512M  2.8G  16% /
    devtmpfs        182M     0  182M   0% /dev
    tmpfs           186M  128K  186M   1% /run
    tmpfs           186M   52K  186M   1% /var/volatile

The *qt5-image* has some demo apps you can use to test that Qt5 apps will run.

Plug in an HDMI display and run this

    root@cm:~# qcolorcheck -platform linuxfb

The Gumstix *Pi Dev Board* has a camera connector that is a little more convenient to use with the official RPi camera modules because it does not require an extra adapter board or jumpers to connect power and I2C the way you need to do using the RPi compute board.

You do still need a `dt-blob.bin` to reconfigure some GPU pins for the camera. You can download the blob from the instructions [here][rpi-cm-camera].

Modify `config.txt` so the GPU can use the camera.

    root@cm:~# mkdir /mnt/fat
    root@cm:~# mount /dev/mmcblk0p1 /mnt/fat
    root@cm:~# echo 'start_x=1' >> /mnt/fat/config.txt
    root@cm:~# echo 'gpu_mem=128' >> /mnt/fat/config.txt
    root@cm:~# reboot

  
After that you can use the [raspicam][raspicam] tools installed on either the of test images in `meta-rpi`.

    root@cm:~# raspistill -t 300000 -hf -vf


Anticipation is high for the hopefully pin-compatible [RPi CM3][cm3-soon] that's rumored to [exist][cm3-post].

[gumstix]: http://www.gumstix.com
[rpi-compute]: https://www.raspberrypi.org/products/compute-module/
[rpi-compute-module-dev-kit]: https://www.raspberrypi.org/products/compute-module-development-kit/
[gumstix-pi-dev-board]: https://store.gumstix.com/expansion/gumstix-pi-compute-dev-board.html
[gumstix-gepetto]: https://www.gumstix.com/geppetto/
[yocto]: https://www.yoctoproject.org
[jumpnow-yocto-rpi]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[jumpnow-rpi-compute]: http://www.jumpnowtek.com/rpi/Working-with-the-raspberry-pi-compute.html
[gumstix-pi-fast-flash-board]: https://store.gumstix.com/raspberry-pi-cm-fast-flash.html
[bbb-upgrades]: http://www.jumpnowtek.com/beaglebone/Upgrade-strategy-for-BBB.html
[rpi-cm-camera]: https://www.raspberrypi.org/documentation/hardware/computemodule/cmio-camera.md
[raspicam]: https://www.raspberrypi.org/documentation/raspbian/applications/camera.md
[cm3-post]: https://www.raspberrypi.org/forums/viewtopic.php?f=98&t=141248
[cm3-soon]: http://www.techrepublic.com/article/raspberry-pi-3-the-inside-story-from-the-new-35-computers-creator/