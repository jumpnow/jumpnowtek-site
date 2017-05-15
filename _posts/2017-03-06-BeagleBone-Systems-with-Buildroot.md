---
layout: post
title: Building Beaglebone Systems with Buildroot
description: "Building customized systems for the BeagleBone Black using Buildroot"
date: 2017-05-15 16:56:00
categories: beaglebone
tags: [linux, beaglebone, bbb, buildroot, qt5, pyqt, pyqt5, pru]
---

A short post covering the use of [Buildroot][buildroot] to build a [BeagleBone Black][bbb] system for working with the [BBB PRUs][bbb-pru].

I'll expand on this post later since the Buildroot systems have some other nice features such as Qt 5.8 and working PyQt. But for now, these notes are just to support building images for the PRU experiments that I'm covering in [this post][bbb-pru-uio-doc].

Make sure you have **ccache** installed on your workstation. Your distro should have a package for this. 

If you don't want to use ccache, run `make menuconfig` between `make <defconfig>` and the build `make` and disable ccache use.

Fetch the repo, use the **[jumpnow]** branch

    scott@fractal:~$ git clone -b jumpnow https://github.com/jumpnow/buildroot
    scott@fractal:~$ cd buildroot

This will build under the `~/buildroot` directory
  
    scott@fractal:~/buildroot$ make jumpnow_bbb_pru_defconfig
    scott@fractal:~/buildroot$ make

If you don't care about the PRU then you can use this defconfig instead

    scott@fractal:~/buildroot$ make jumpnow_bbb_defconfig
    scott@fractal:/br5/bbb$ make

I suggest building outside the buildroot tree by passing an argument like this `O=<some-other-dir>` to the make defconfig step.

    scott@fractal:~/buildroot$ make O=/br5/bbb jumpnow_bbb_pru_defconfig
    scott@fractal:~/buildroot$ cd /br5/bbb
    scott@fractal:/br5/bbb$ make

The default download directory for Buildroot sources will be `$(HOME)/dl`. You can change this with `make menuconfig`.

And finally, you will probably need your distros 32-bit compatibility libs for the TI PRU compiler package. I did using an Ubuntu 16.04 64-bit server for a build system.

The **jumpnow\_bbb\_pru\_defconfig** uses a ti-linux 4.4.52 kernel with patches and a kernel config that supports using the uio-pruss kernel driver.

The **jumpnow\_bbb\_defconfig** uses a linux-stable 4.9.28 kernel with patches and dtbs to support the 4DCape 4.3 and 7 inch displays and the new NewHaven 7 inch capacitive touch display.

The system is minimal and should build fast (~15 minutes), especially on subsequent builds where source has been downloaded and the ccache is populated.

After the image is built you can load the image to an SD card like this

    scott@fractal:/br5/bbb$ sudo dd if=images/bbb-sdcard.img of=/dev/sdb bs=1M

Boot the image holding the **USER** button on the board until the bootloader starts.

I recommend having a USB serial for console access.

The system will look for a dhcp address on the ethernet, but USB networking is not enabled (or at least not tested and definitely not configured).

An ssh server is running.

The default dtb is the **am335x-bonegreen.dtb** which will work with a regular BB Black, but it does not enable a display. I am primarily using this image for the PRU and a lot of the display pins conflict with the PRU pins.

It's easy enough to change the dtb that is used by editing the **uEnv.txt** file on the FAT partition of the SD card. `/dev/mmcblk0p1`, the FAT partition is mounted here

    # ls /mnt
    MLO         u-boot.img  uEnv.txt


### Using the Buildroot Cross-Compiler

You can use the Buildroot generated cross-compiler to build sources outside of the Buildroot system.

For example, here is a simple kernel workflow done external to Buildroot.

Fetch the kernel and checkout a working branch. This is the same kernel the Buildroot build used.

    ~$ git clone -b ti-linux-4.4.y git://git.ti.com/ti-linux-kernel/ti-linux-kernel.git
    ~$ cd ~/ti-linux-kernel
    ~/ti-linux-kernel$ git checkout -b bbb-4.4

Add the same patches and config the Buildroot built kernel is using

    ~/ti-linux-kernel$ git am ~/buildroot/board/jumpnow/bbb/ti-linux/4.4/*.patch
    ~/ti-linux-kernel$ cp ~/buildroot/board/jumpnow/bbb/ti-linux/4.4/defconfig .config

Add the path to the Buildroot cross-compiler
	
    ~/ti-linux-kernel$ export PATH=/br5/bbb/host/usr/bin:${PATH}

Build the kernel and modules (adjust the parallel -jX flag for your machine)

    ~/ti-linux-kernel$ make ARCH=arm CROSS_COMPILE=arm-linux- LOCALVERSION= -j8

Build a specific dtb

    ~/ti-linux-kernel$ make ARCH=arm CROSS_COMPILE=arm-linux- am335x-bonegreen.dtb
      DTC     arch/arm/boot/dts/am335x-bonegreen.dtb

You can generate patches from this kernel source tree and add them to the same patch directory as the other kernel patches and they will be included in your next Buildroot build of the system.

This is the basic workflow I used to generate the current kernel patches.

[buildroot]: https://buildroot.org/
[bbb]: https://beagleboard.org/
[bbb-pru]: http://elinux.org/Ti_AM33XX_PRUSSv2
[pruss-uio]: http://arago-project.org/git/projects/?p=linux-am33x.git;a=commit;h=f1a304e7941cc76353363a139cbb6a4b1ca7c737
[bbb-pru-uio-doc]: http://www.jumpnowtek.com/beaglebone/Working-with-the-BeagleBone-PRUs.html