---
layout: post
title: Compiling Raspberry Pi Overlays with Buildroot
date: 2017-01-18 06:18:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, overlays, kernel]
---

The Buildroot kernel makefile will build the main DTB for the RPi board from the kernel sources, but it doesn't build any of the RPi DTBO overlays.

Instead the DTBO overlays are installed as part of the **rpi-firmware** package as simple copies from the [github.com/raspberrypi/firmware][rpi-firmware-repo] repository.

This is inconvenient from the workflow I've been using with the RPis where I've been combining kernel changes with overlay changes in the same kernel patches and letting them build as part of the kernel. 

This seems like the right approach since changes are to the same source repository. This is the way I  develop and test the patches when working on the kernel outside the Buildroot system.

So I added some [modifications to the kernel make files][rpi-overlay-patch] to build the in-tree RPi overlays.

And I [modified the rpi-firmware makefile][rpi-firmware-patch] to disable copying the overlays when the kernel is building them.

It seems to work okay.

Some small examples are [here][hardware-pwm-overlay-patch] and [here][ads1015-enable-patch], but this will also work for some bigger patches I have for customer projects.  

Here the latest builds from my [buildroot repo][jumpnow-buildroot] showing some custom [-with-clk pwm][jumpnow-hardware-pwm] dtbos getting installed. 

    # uname -a
    Linux buildroot 4.4.43-v7 #1 SMP Tue Jan 17 07:26:59 EST 2017 armv7l GNU/Linux

    # mount /dev/mmcblk0p1 /mnt
    # ls /mnt/overlays/*pwm*
    /mnt/overlays/i2c-pwm-pca9685a.dtbo    /mnt/overlays/pwm-with-clk.dtbo
    /mnt/overlays/pwm-2chan-with-clk.dtbo  /mnt/overlays/pwm.dtbo


Another advantage is reuse of the same kernel patches I've been using with [Yocto][jumpnow-rpi-yocto].

The changes to **linux.mk** aren't big, but they are specific to the RPi boards.

I'll see what happens when I try to upstream this.

[rpi-overlay-patch]: https://github.com/jumpnow/buildroot/commit/cbd238f95a2cf6844befa4116211c283df21ee58
[rpi-firmware-patch]: https://github.com/jumpnow/buildroot/commit/4740828cb5e3c90c40f4da231930f5118ac06b53
[rpi-firmware-repo]: https://github.com/raspberrypi/firmware
[hardware-pwm-overlay-patch]: https://github.com/jumpnow/buildroot/commit/e1245506a204dbaad10277d1463254c7537e58c7
[ads1015-enable-patch]: https://github.com/jumpnow/buildroot/commit/6b3f826feb205a5454b0ebb655b915b400eba49d
[jumpnow-buildroot]: https://github.com/jumpnow/buildroot
[jumpnow-rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[jumpnow-hardware-pwm]: http://www.jumpnowtek.com/rpi/Using-the-Raspberry-Pi-Hardware-PWM-timers.html