---
layout: post
title: Working on the BeagleBone Kernel
description: "Working on and customizing the BeagleBone Black kernel"
date: 2016-06-18 06:41:00
categories: beaglebone 
tags: [linux, beaglebone, kernel]
---

Once you've built a basic [BeagleBone Black system][bbb-yocto] with the [Yocto Project][yocto] tools, you will probably want to customize the kernel or the device tree that gets loaded at boot.

## General

The default Linux kernel is referred to as **virtual/kernel** when building with *bitbake*.

For example to build the kernel and modules

    ~/bbb/build$ bitbake virtual/kernel

or to clean the build

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel


Which kernel to use comes from this line in `meta-bbb/conf/machine/beaglebone.conf`

    PREFERRED_PROVIDER_virtual/kernel = "linux-stable"

The kernel recipes are found here `meta-bbb/recipes-kernel/linux/`

If you had multiple *linux-stable* recipes, maybe 

* linux-stable_4.4.bb
* linux-stable_4.5.bb 
* linux-stable_4.6.bb

then the highest revision number, **4.6** in this case, would be used. 

To specify an earlier version, you could use a line like this in `build/conf/local.conf`

    PREFERRED_VERSION_linux-stable = "4.4"

The **4.4** kernel is the latest *LTS* kernel, so that is the default kernel I am using for projects.

Kernel patches and config file are searched for under `meta-bbb/recipes-kernel/linux/linux-stable-4.4/` because of this line in the kernel recipe

    FILESEXTRAPATHS_prepend := "${THISDIR}/linux-stable-4.4:"

The kernel config file is `meta-bbb/recipes-kernel/linux/linux-stable-4.4/beaglebone/defconfig`.

When Yocto builds the *linux-stable-4.4* kernel, it does so under this directory

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.4-r14

The *r14* revision comes from this line in the kernel recipe

    PR = "r14"

It is a good idea to update the *PR* value if you make any changes to the kernel recipe. This will force a rebuild of the kernel the next time you build an image.

Here's a look at that kernel work directory after a build

    scott@fractal:~/bbb/build/conf$ ls -l /oe7/bbb/tmp-krogoth/work/beaglebone-poky-linux-gnueabi/linux-stable/4.4-r14/
    total 228
    -rw-rw-r--   1 scott scott   704 Jan 17 22:59 0001-spidev-Add-a-generic-compatible-id.patch
    -rw-rw-r--   1 scott scott  1955 Jan 17 22:59 0002-dts-Revoke-Beaglebone-i2c2-definitions.patch
    -rw-rw-r--   1 scott scott 15051 Jan 17 22:59 0003-Add-ft5x06_ts-touchscreen-driver.patch
    -rw-rw-r--   1 scott scott 27885 Jan 17 22:59 0004-dts-Add-custom-bbb-dts-files.patch
    -rw-rw-r--   1 scott scott 97256 Jan 17 22:59 defconfig
    drwxr-xr-x   3 scott scott  4096 Jun  8 08:06 deploy-ipks
    drwxr-xr-x   2 scott scott  4096 Jun  8 08:05 deploy-linux-stable
    lrwxrwxrwx   1 scott scott    57 Jun  8 08:03 git -> /oe7/bbb/tmp-krogoth/work-shared/beaglebone/kernel-source
    drwxr-xr-x   5 scott scott  4096 Jun  8 08:05 image
    drwxrwxr-x   3 scott scott  4096 Jun  8 08:03 license-destdir
    drwxr-xr-x  22 scott scott  4096 Jun  8 08:05 linux-beaglebone-standard-build
    drwxr-xr-x   4 scott scott  4096 Jun  8 08:05 package
    drwxr-xr-x 114 scott scott  4096 Jun  8 08:06 packages-split
    drwxr-xr-x   7 scott scott  4096 Jun  8 08:05 pkgdata
    drwxrwxr-x   2 scott scott  4096 Jun  8 08:05 pseudo
    drwxrwxr-x   2 scott scott  4096 Jun  8 08:05 sstate-build-deploy
    drwxr-xr-x   2 scott scott  4096 Jun  8 08:06 sstate-build-package
    drwxrwxr-x   2 scott scott  4096 Jun  8 08:06 sstate-build-packagedata
    drwxr-xr-x   2 scott scott  4096 Jun  8 08:06 sstate-build-package_qa
    drwxr-xr-x   2 scott scott  4096 Jun  8 08:06 sstate-build-package_write_ipk
    drwxrwxr-x   2 scott scott  4096 Jun  8 08:03 sstate-build-populate_lic
    drwxrwxr-x   2 scott scott  4096 Jun  8 08:05 sstate-build-populate_sysroot
    drwxr-xr-x   3 scott scott  4096 Jun  8 08:05 sysroot-destdir
    drwxrwxr-x   2 scott scott 12288 Jun  8 08:06 temp


The patches and defconfig are the same files from `meta-bbb/recipes-kernel/linux/linux-stable-4.4/`

The files under `git` are the Linux source after the kernel recipe patches have been applied.

The build output happens under `linux-beaglebone-standard-build` and this is where the *defconfig* is copied to a `.config`.


## Changing the kernel config

You can invoke the standard kernel configuration editor using bitbake

    ~/bbb/build$ bitbake -c menuconfig virtual/kernel

After you make your changes and save them, the new configuration file can be found here

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.4-r14/linux-beaglebone-standard-build/.config

Copy that `.config` file to

    ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.4/beaglebone/defconfig

Then rebuild your kernel

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel && bitbake virtual/kernel

If that is successful, you then want to rebuild your image to get the new kernel and modules included in the *rootfs* for installation.

## Working outside of Yocto

I usually find it more convenient to work on the kernel outside of the Yocto build system.

A little setup is required.

### Cross-compiler

The Yocto tools will build a cross-compiler with headers and libraries that you can easily install on multiple machines including the Yocto build machine which is where I'll be using it.

First, choose the architecture where you'll be running the cross-compiler by setting the *SDKMACHINE* variable in your `local.conf` file.

    SDKMACHINE = "x86_64"

The choices are **i686** for 32-bit build workstations or **x86_64** for 64-bit workstations.

Then after the normal setting up of the Yocto build environment

    ~$ source poky-krogoth/oe-init-build-env ~/bbb/build

build the sdk installer with the *populate_sdk* command, usually specifying the same image file you are using in your project
    
    ~/bbb/build$ bitbake -c populate_sdk console-image

When finished, the sdk installer will end up here

    <TMPDIR>/deploy/sdk/poky-glibc-x86_64-console-image-cortexa8hf-vfp-neon-toolchain-2.1.sh

If you run it and accept the defaults, the cross-tools will get installed under `/opt/poky/2.1`.


### Fetch the Linux source

The kernel recipe *linux-stable_4.4.bb* has the repository location, branch and commit of the kernel source used in the Yocto build.

These lines have the details

    # v4.4.13
    SRCREV = "ba760d4302e4fce130007b8bdbce7fcafc9bd9a9"
    SRC_URI = " \
        git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;branch=linux-4.4.y \


Be sure to pay attention to the branch.
		
Here are the commands to checkout that same kernel source

    $ cd ~/bbb
    $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
    $ cd linux-stable
	
Switch to the correct branch

    $ git checkout -b linux-4.4.y origin/linux-4.4.y

That gets you to the correct git branch, but depending on whether I've kept the `meta-bbb` repository up-to-date, the current commit on the branch may or may not match the **SRCREV** in the recipe. If they don't match, you can checkout a particular older commit explicitly or you can modify the recipe to use the latest commit. Checking out the same branch is usually sufficient.

### Apply existing patches

Currently the `meta-bbb/recipes-kernel/linux/linux-stable_4.4.bb` recipe has a number of patches that I've included to add support for *spidev*, *i2c*, *uart4* and a few touchscreens. These are all completely optional and you probably want your own patches instead. 

Whatever patches you decide to use when building with *Yocto*, you can use *git* to apply these same patches to the Linux source repository outside of *Yocto*.

I usually start by creating a working branch

    ~$ cd ~/bbb/linux-stable
    ~/bbb/linux-stable$ checkout -b work

And if you wanted to apply all of the patches at once

    ~/bbb/linux-stable$ git am ../meta-bbb/recipes-kernel/linux/linux-stable-4.4/*.patch

Or you could apply selective patches individually.

### Default kernel config

Copy the kernel config file that Yocto used to the new linux-stable repository.

    cp ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.4/beaglebone/defconfig ~/bbb/linux-stable/.config

If you make changes to the config that you want to keep, make sure to copy it back to `meta-bbb/.../defconfig`


### Building

Source the cross-tools environment

    ~$ cd bbb/linux-stable
    ~/bbb/linux-stable$ source /opt/poky/2.1/environment-setup-cortexa8hf-vfp-neon-poky-linux-gnueabi

Build a zImage, unset **LOCALVERSION** so modules already on the bbb rootfs will still load

    ~/bbb/linux-stable$ make LOCALVERSION= -j8 zImage

The `-jN` argument is optional and depends on your workstation.

Build the modules

    ~/bbb/linux-stable$ make LOCALVERSION= -j8 modules

Build the device tree binaries

    ~/bbb/linux-stable$ make bbb-hdmi.dtb
      DTC     arch/arm/boot/dts/bbb-hdmi.dtb

The device tree source files are found under `arch/arm/boot/dts/`

### Deploying

For development, deployment consists of copying over to a running beaglebone system and rebooting. I usually use **scp**.

The new *zImage* file can be found here `arch/arm/boot/zImage`. Copy it to the beaglebone `/boot/` directory.

    ~/bbb/linux-stable$ scp arch/arm/boot/zImage root@<bbb-ip-address>:/boot


I'm typically only working on one particular module at a time and therefore would only copy that particular `*.ko` module over to the appropriate bbb `/lib/modules` location.


Device tree binaries also go in `/boot`.

For example

    ~/bbb/linux-stable$ scp arch/arm/boot/dts/bbb-hdmi.dtb root@<bbb-ip-address>:/boot


Modify `uEnv.txt` to specify which **dtb** file to load.

	fdtfile="some-dtb"

The `uEnv.txt` file is on the *boot* partition which you'll normally have to mount first

    root@bbb:~# mkdir /mnt/fat
    root@bbb:~# mount /dev/mmcblk0p1 /mnt/fat

    root@bbb:~# ls -l /mnt/fat
    total 466
    -rwxr-xr-x 1 root root  64408 Aug 10  2015 MLO
    -rwxr-xr-x 1 root root 410860 Aug 10  2015 u-boot.img
    -rwxr-xr-x 1 root root    931 Aug 10  2015 uEnv.txt

After that you can edit the `uEnv.txt` file to change the **dtb** that is loaded.

### Generating a patch for Yocto

After finishing development you will probably want to integrate your changes into the Yocto build system. Yocto works with the standard patches generated by *git*.

So for instance the patch that allows using the spidev kernel driver in a DTS without the silly warnings

    0001-spidev-Add-a-generic-compatible-id.patch

was generated like this

    scott@fractal:~/bbb/linux-stable$ vi drivers/spi/spidev.c

Make the changes and save.

Here's the diff

    scott@octo:~/bbb/linux-stable$ git diff
    diff --git a/drivers/spi/spidev.c b/drivers/spi/spidev.c
    index ef008e5..59b37e9 100644
    --- a/drivers/spi/spidev.c
    +++ b/drivers/spi/spidev.c
    @@ -695,6 +695,7 @@ static struct class *spidev_class;
     static const struct of_device_id spidev_dt_ids[] = {
            { .compatible = "rohm,dh2228fv" },
            { .compatible = "lineartechnology,ltc2488" },
    +       { .compatible = "generic,spi" },
            {},
     };
     MODULE_DEVICE_TABLE(of, spidev_dt_ids);

 Now commit the change to git

    scott@fractal:~/bbb/linux-stable$ git add drivers/spi/spidev.c

    scott@octo:~/bbb/linux-stable$ git commit -m 'spidev: Add a generic compatible id'
    [work 00e179f] spidev: Add a generic compatible id
     1 file changed, 1 insertion(+)

generate a patch

    scott@octo:~/bbb/linux-stable$ git format-patch -1
    0001-spidev-Add-a-generic-compatible-id.patch


copy the patch to where Yocto will use it

    scott@fractal:~/bbb/linux-stable$ cp 0001-spidev-* \
        ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.4/


and finally add the patch to the kernel recipe `linux-stable_4.4.bb`.

Yocto will apply the patches in the order they appear in the recipe, but to make it easier to work with `git am` outside of Yocto it's useful to rename (renumber) the patches in the order you want them applied.

### External Kernel Modules

You can build external kernel modules by first *sourcing* the Yocto SDK environment as above and then pointing your Makefile *KERNELDIR* to the correct location using the `-C` switch.

For example

    scott@fractal:~/projects/hellow$ cat Makefile
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

Build the module with *make*

    scott@fractal:~/projects/hellow$ make
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

Here's a working Yocto recipe that pulls the external module source from a private *Github* repository, builds and then installs the module under `/lib/modules/${KERNEL_VERSION/kernel/drivers` on the final *rootfs*.

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