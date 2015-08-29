---
layout: post
title: Working on the BeagleBone Kernel
description: "Working on and customizing the BeagleBone Black kernel"
date: 2015-08-29 05:27:00
categories: beaglebone 
tags: [linux, beaglebone, kernel]
---

Once you've built a basic [BeagleBone Black system][bbb-yocto] with the [Yocto Project][yocto] tools, you will probably want to customize the kernel or the device tree that gets loaded at boot.

## General

The default Linux kernel is referred to as **virtual/kernel** when building with *bitbake*.

For example:

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel

or

    ~/bbb/build$ bitbake virtual/kernel


Which kernel to use comes from this line in `meta-bbb/conf/machine/beaglebone.conf`

    PREFERRED\_PROVIDER\_virtual/kernel = "linux-stable"

Kernel recipes are here `meta-bbb/recipes-kernel/linux/`

The default kernel recipe is `linux-stable_4.1.bb`

Kernel patches and config file are searched for under `meta-bbb/recipes-kernel/linux/linux-stable-4.1/` because of this line in the kernel recipe

    FILESEXTRAPATHS_prepend := "${THISDIR}/linux-stable-4.1:"

The kernel config file is `meta-bbb/recipes-kernel/linux/linux-stable-4.1/beaglebone/defconfig`.

If you had multiple *linux-stable* recipes, maybe *linux-stable_4.0.bb* and *linux-stable_4.1.bb* then the highest revision number, 4.1 in this case, would be used. To specify an earlier version, you could use a line like this in `build/conf/local.conf`

    PREFERRED\_VERSION\_linux-stable = "4.0"

When Yocto builds the *linux-stable-4.1* kernel, it does so under this directory

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r12

The *r12* revision comes from this line in the kernel recipe

    PR = "r12"

Here's a look at that directory after a build

    scott@octo:~/bbb/build/tmp/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r12$ ls -l
    total 228
    -rw-r--r--  1 scott scott   674 Aug 28 14:59 0001-spidev-Add-generic-compatible-dt-id.patch
    -rw-r--r--  1 scott scott  1627 Aug 28 14:59 0002-Add-bbb-spi1-spidev-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Aug 28 14:59 0003-Add-bbb-i2c1-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Aug 28 14:59 0004-Add-bbb-i2c2-dtsi.patch
    -rw-r--r--  1 scott scott  3222 Aug 28 14:59 0005-Add-bbb-hdmi-dts.patch
    -rw-r--r--  1 scott scott  4436 Aug 28 14:59 0006-Add-bbb-4dcape70t-dts.patch
    -rw-r--r--  1 scott scott 15054 Aug 28 14:59 0007-Add-ft5x06-touchscreen-driver.patch
    -rw-r--r--  1 scott scott  5093 Aug 28 14:59 0008-Add-bbb-nh5cape-dts.patch
    -rw-r--r--  1 scott scott  2374 Aug 28 14:59 0009-Add-4dcape70t-button-dtsi.patch
    -rw-r--r--  1 scott scott  1125 Aug 28 14:59 0010-4dcape70t-dts-include-button-dtsi-comment-out-spi.patch
    -rw-r--r--  1 scott scott   766 Aug 28 14:59 0011-mmc-Allow-writes-to-mmcblkboot-partitions.patch
    -rw-r--r--  1 scott scott   753 Aug 28 14:59 0012-4dcape70t-Increase-charge-delay.patch
    -rw-r--r--  1 scott scott  1139 Aug 28 14:59 0013-Add-uart4-dtsi.patch
    -rw-r--r--  1 scott scott  1582 Aug 28 14:59 0014-Include-uart4-dtsi-in-bbb-dts-files.patch
    -rw-r--r--  1 scott scott  5048 Aug 28 14:59 0015-bbb-nh5cape-Fix-bpp-for-24-bit-color.patch
    -rw-r--r--  1 scott scott  1092 Aug 28 14:59 0016-Revert-usb-musb-dsps-just-start-polling-already.patch
    -rw-r--r--  1 scott scott 84935 Aug 28 14:59 defconfig
    drwxr-xr-x  3 scott scott  4096 Aug 28 15:29 deploy-ipks
    drwxr-xr-x  2 scott scott  4096 Aug 28 15:28 deploy-linux-stable
    lrwxrwxrwx  1 scott scott    65 Aug 28 14:59 git -> /oe4/bbb/tmp-poky-fido-build/work-shared/beaglebone/kernel-source
    drwxr-xr-x  5 scott scott  4096 Aug 28 15:28 image
    drwxrwxr-x  3 scott scott  4096 Aug 28 15:05 license-destdir
    drwxr-xr-x 20 scott scott  4096 Aug 29 04:51 linux-beaglebone-standard-build
    drwxr-xr-x  4 scott scott  4096 Aug 28 15:28 package
    drwxr-xr-x 71 scott scott  4096 Aug 28 15:30 packages-split
    drwxr-xr-x  7 scott scott  4096 Aug 28 15:28 pkgdata
    drwxrwxr-x  2 scott scott  4096 Aug 28 15:28 pseudo
    drwxr-xr-x  3 scott scott  4096 Aug 28 15:28 sysroot-destdir
    drwxrwxr-x  2 scott scott 12288 Aug 29 04:51 temp

The patches and defconfig are the same files from `meta-bbb/recipes-kernel/linux/linux-stable-4.1/`

The files under `git` are the Linux source after the kernel recipe patches have been applied.

The build output happens under `linux-beaglebone-standard-build` and this is where the *defconfig* is copied to a `.config`.


## Changing the kernel config

You can invoke the standard kernel configuration editor using bitbake

    ~/bbb/build$ bitbake -c menuconfig virtual/kernel

After you make your changes and save them, the new configuration file can be found here

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r1/linux-beaglebone-standard-build/.config

Copy that `.config` file to

    ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.1/beaglebone/defconfig

Then rebuild your kernel

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel && bitbake virtual/kernel



## Working outside of Yocto

I usually find it more convenient to work on the kernel outside of the Yocto build system. Turn-around time between build iterations are definitely faster. It does require a little bit of setup first.

### Cross-compiler

The Yocto tools will build a cross-compiler with headers and libraries that you can easily install on multiple machines including the Yocto build machine which is where I'll be using it.

First, choose the architecture where you'll be running the cross-compiler by setting the *SDKMACHINE* variable in your `local.conf` file.

    SDKMACHINE = "x86_64"

The choices are *i686* for 32-bit build workstations or *x86_64* for 64-bit workstations.

Then after the normal setting up of the Yocto build environment

    ~$ source poky-fido/oe-init-build-env ~/bbb/build

build the sdk installer with the *populate_sdk* command, specifying the same image file you are using in your project.
    
    ~/bbb/build$ bitbake -c populate_sdk qt5-image

When finished, the sdk installer will end up here

    <TMPDIR>/deploy/sdk/poky-glibc-x86_64-qt5-image-cortexa8hf-vfp-neon-toolchain-1.8.sh

If you run it and accept the defaults, the cross-tools will get installed under `/opt/poky/1.8`.


### Fetch the Linux source

The kernel recipe *linux-stable_4.1.bb* has the repository location, branch and commit of the kernel source used in the Yocto build.

These lines have the details

    # v4.1.6
    SRCREV = "4ff62ca06c0c0b084f585f7a2cfcf832b21d94fc"
    SRC_URI = " \
        git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;branch=linux-4.1.y \

Here are the commands to checkout that same kernel source

    $ cd ~/bbb
    $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
    $ cd linux-stable
    $ git checkout -b linux-4.1.y origin/linux-4.1.y

That gets you to the correct git branch, but depending on whether I've kept the `meta-bbb` repository up-to-date, the current commit on the branch may or may not match the **SRCREV** in the recipe. If they don't match, you can checkout a particular older commit explicitly or you can modify the recipe to use the latest commit. Checking out the same branch is usually sufficient.

### Apply existing patches

Currently the `meta-bbb/recipes-kernel/linux/linux-stable_4.1.bb` recipe has a number of patches that I've included to add support for *spidev*, *i2c*, *uart4* and a few touchscreens. These are all completely optional and you probably want your own patches instead. You can use *git* to apply these same patches to the Linux source repository.

I usually start by creating a working branch

    ~$ cd ~/bbb/linux-stable
    ~/bbb/linux-stable$ checkout -b work

And if you wanted to apply all of the patches at once

    ~/bbb/linux-stable$ git am ../meta-bbb/recipes-kernel/linux/linux-stable-4.1/*.patch

Or you could apply selective patches individually.

### Default kernel config

Copy the kernel config file that Yocto used to the new linux-stable repository.

    cp ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.1/beaglebone/defconfig ~/bbb/linux-stable/.config

If you make changes to the config that you want to keep, make sure to copy it back to `meta-bbb/.../defconfig`


### Building

Source the cross-tools environment

    ~$ cd bbb/linux-stable
    ~/bbb/linux-stable$ source /opt/poky/1.8/environment-setup-cortexa8hf-vfp-neon-poky-linux-gnueabi

Build a zImage, unset **LOCALVERSION** so modules already on the bbb rootfs will still load

    ~/bbb/linux-stable$ make LOCALVERSION= -j8 zImage

Build modules

    ~/bbb/linux-stable$ make LOCALVERSION= -j8 modules

Build device tree binaries

    ~/bbb/linux-stable$ make bbb-hdmi.dtb
      DTC     arch/arm/boot/dts/bbb-hdmi.dtb

The device tree source files are found under `arch/arm/boot/dts/`

### Deploying

For development, deployment consists of copying over to a running beaglebone system and rebooting. I usually use **scp**.

The new *zImage* file can be found here `arch/arm/boot/zImage`. Copy it to the beaglebone `/boot/` directory.

    ~/bbb/linux-stable$ scp arch/arm/boot/zImage root@<bbb-ip-address>:/boot


I'm typically only working on one particular module at a time and therefore would only copy that particular `*.ko` module over to the appropriate beaglebone `/lib/modules` location.


Device tree binaries also go in `/boot`.

For example

    ~/bbb/linux-stable$ scp arch/arm/boot/dts/bbb-hdmi.dtb root@<bbb-ip-address>:/boot


Modify `uEnv.txt` to specify which **dtb** file to load.

	fdtfile="some-dtb"

The `uEnv.txt` file is on the *boot* partition which you'll normally have to mount first

    root@bbb:~# mount /dev/mmcblk0p1 /mnt

    root@bbb:~# ls -l /mnt
    total 466
    -rwxr-xr-x 1 root root  64408 Aug 10  2015 MLO
    -rwxr-xr-x 1 root root 410860 Aug 10  2015 u-boot.img
    -rwxr-xr-x 1 root root    931 Aug 10  2015 uEnv.txt

After that you can edit the `uEnv.txt` file to change the **dtb**.

### Generating a patch for Yocto

After finishing development you will probably want to integrate your changes into the Yocto build system. Yocto works with the standard patches generated by *git*.

So for instance that patch to allow writes to the `/dev/mmcblkboot` partitions

    0011-mmc-Allow-writes-to-mmcblkboot-partitions.patch

was generated like this

    scott@octo:~/bbb/linux-stable$ vi drivers/mmc/core/mmc.c

Make the changes and save.

Here's the diff

    scott@octo:~/bbb/linux-stable$ git diff
    diff --git a/drivers/mmc/core/mmc.c b/drivers/mmc/core/mmc.c
    index f36c76f..43e1ae0 100644
    --- a/drivers/mmc/core/mmc.c
    +++ b/drivers/mmc/core/mmc.c
    @@ -417,7 +417,7 @@ static int mmc_decode_ext_csd(struct mmc_card *card, u8 *ext_csd)
                                    part_size = ext_csd[EXT_CSD_BOOT_MULT] << 17;
                                    mmc_part_add(card, part_size,
                                            EXT_CSD_PART_CONFIG_ACC_BOOT0 + idx,
    -                                       "boot%d", idx, true,
    +                                       "boot%d", idx, false,
                                            MMC_BLK_DATA_AREA_BOOT);
                            }
                    }

Now commit the change to git

    scott@octo:~/bbb/linux-stable$ git add drivers/mmc/core/mmc.c

    scott@octo:~/bbb/linux-stable$ git commit -m 'mmc: Allow writes to mmcblkboot partitions'
    [work 9b5d32c] mmc: Allow writes to mmcblkboot partitions
     1 file changed, 1 insertion(+), 1 deletion(-)

Generate a patch

    scott@octo:~/bbb/linux-stable$ git format-patch -1
    0001-mmc-Allow-writes-to-mmcblkboot-partitions.patch

Here's what it looks like

    scott@octo:~/bbb/linux-stable$ cat 0001-mmc-Allow-writes-to-mmcblkboot-partitions.patch
    From 9b5d32c20a7392867a98e463d01f77c9e7f9ec48 Mon Sep 17 00:00:00 2001
    From: Scott Ellis <scott@jumpnowtek.com>
    Date: Mon, 10 Aug 2015 08:32:23 -0400
    Subject: [PATCH] mmc: Allow writes to mmcblkboot partitions
    
    ---
     drivers/mmc/core/mmc.c | 2 +-
     1 file changed, 1 insertion(+), 1 deletion(-)
    
    diff --git a/drivers/mmc/core/mmc.c b/drivers/mmc/core/mmc.c
    index f36c76f..43e1ae0 100644
    --- a/drivers/mmc/core/mmc.c
    +++ b/drivers/mmc/core/mmc.c
    @@ -417,7 +417,7 @@ static int mmc_decode_ext_csd(struct mmc_card *card, u8 *ext_csd)
                                    part_size = ext_csd[EXT_CSD_BOOT_MULT] << 17;
                                    mmc_part_add(card, part_size,
                                            EXT_CSD_PART_CONFIG_ACC_BOOT0 + idx,
    -                                       "boot%d", idx, true,
    +                                       "boot%d", idx, false,
                                            MMC_BLK_DATA_AREA_BOOT);
                            }
                    }
    --
    2.1.4

Copy the patch to where Yocto will use it.

    scott@octo:~/bbb/linux-stable$ cp 0001-mmc-* \
        ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.1/


Then add the patch to the kernel recipe `linux-stable_4.1.bb`.

Yocto will apply the patches in the order they appear in the recipe, but to make it easier to work with `git am` outside of Yocto it's useful to rename (renumber) the patches in the order you want them applied.

That's why I renamed this same patch from `0001-` to `0011-` in the `meta-bbb` layer.

### External Kernel Modules

You can build external kernel modules by first *sourcing* the Yocto SDK environment as above and then pointing your Makefile *KERNELDIR* to the correct location using the `-C` switch.

For example

    scott@octo:~/projects/hellow$ cat Makefile
    # Makefile for the hellow kernel module

    MODULE_NAME=hellow

    ifneq ($(KERNELRELEASE),)
        obj-m := $(MODULE_NAME).o
    else
        PWD := $(shell pwd)

    default:
            $(MAKE) -C $(HOME)/bbb/linux-stable M=$(PWD) modules

    clean:
            rm -rf *~ *.ko *.o *.mod.c modules.order Module.symvers .${MODULE_NAME}* .tmp_versions

    endif

Then to build

    scott@octo:~/projects/hellow$ make
    make -C /home/scott/bbb/linux-stable M=/home/scott/projects/hellow modules
    make[1]: Entering directory '/home/scott/bbb/linux-stable'
      CC [M]  /home/scott/projects/hellow/hellow.o
      Building modules, stage 2.
      MODPOST 1 modules
      CC      /home/scott/projects/hellow/hellow.mod.o
      LD [M]  /home/scott/projects/hellow/hellow.ko
    make[1]: Leaving directory '/home/scott/bbb/linux-stable'


After that you can copy the *ko* module to the BBB using *scp* and load it manually with *insmod*.

### Adding a Yocto Recipe for an External Kernel Module

When you are done with development, you probably want your new kernel module to be built with the rest of the system.

Here's a working a recipe that pulls the external module source from a private *Github* repository

    scott@fractal:~/fit-overo/meta-fit/recipes-kernel/drivers$ cat ads1278_git.bb
    DESCRIPTION = "A kernel module for the FIT ads1278"
    LICENSE = "GPLv2"
    LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

    inherit module

    PR = "r23"

    SRCREV = "${AUTOREV}"
    SRC_URI = "git://git@github.com/Fluid-Imaging-Technologies/fit-ads1278.git;protocol=ssh"

    S = "${WORKDIR}/git"

    do_compile() {
      unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS
      oe_runmake 'KERNELDIR=${STAGING_KERNEL_DIR}'
    }
    
    do_install() {
      install -d ${D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/${PN}
      install -m 0644 ads1278${KERNEL_OBJECT_SUFFIX} ${D}${base_libdir}/modules/${KERNEL_VERSION}/kernel/drivers/${PN}
    }


You could then add the driver package, `ads128` in this example, to to the `IMAGE_INSTALL` variable for the *Yocto* image recipe you are using.


[bbb-yocto]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Yocto.html
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[menuconfig-bug-report]: https://bugzilla.yoctoproject.org/show_bug.cgi?id=7791
