---
layout: post
title: Working on the BeagleBone Kernel
description: "Working on and customizing the BeagleBone Black kernel"
date: 2015-06-22 14:00:00
categories: beaglebone 
tags: [linux, beaglebone, yocto]
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

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r1

The *r1* revision comes from this line in the kernel recipe

    PR = "r1"

Here's a look at that directory after a build

    scott@octo:~/bbb/build/tmp/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r1$ ls -l
    total 192
    -rw-r--r--  1 scott scott   674 Jun 22 15:01 0001-spidev-Add-generic-compatible-dt-id.patch
    -rw-r--r--  1 scott scott  1627 Jun 22 15:01 0002-Add-bbb-spi1-spidev-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Jun 22 15:01 0003-Add-bbb-i2c1-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Jun 22 15:01 0004-Add-bbb-i2c2-dtsi.patch
    -rw-r--r--  1 scott scott  3222 Jun 22 15:01 0005-Add-bbb-hdmi-dts.patch
    -rw-r--r--  1 scott scott  4436 Jun 22 15:01 0006-Add-bbb-4dcape70t-dts.patch
    -rw-r--r--  1 scott scott 15054 Jun 22 15:01 0007-Add-ft5x06-touchscreen-driver.patch
    -rw-r--r--  1 scott scott  5094 Jun 22 15:01 0008-Add-bbb-nh5cape-dts.patch
    -rw-r--r--  1 scott scott 83936 Jun 22 15:01 defconfig
    drwxr-xr-x  3 scott scott  4096 Jun 22 15:05 deploy-ipks
    drwxr-xr-x  2 scott scott  4096 Jun 22 15:05 deploy-linux-stable
    lrwxrwxrwx  1 scott scott    65 Jun 22 15:01 git -> /oe7/bbb/tmp-poky-fido-build/work-shared/beaglebone/kernel-source
    drwxr-xr-x  5 scott scott  4096 Jun 22 15:05 image
    drwxrwxr-x  3 scott scott  4096 Jun 22 15:01 license-destdir
    drwxr-xr-x 20 scott scott  4096 Jun 22 15:05 linux-beaglebone-standard-build
    drwxr-xr-x  4 scott scott  4096 Jun 22 15:05 package
    drwxr-xr-x 65 scott scott  4096 Jun 22 15:05 packages-split
    drwxr-xr-x  7 scott scott  4096 Jun 22 15:05 pkgdata
    drwxrwxr-x  2 scott scott  4096 Jun 22 15:05 pseudo
    drwxr-xr-x  3 scott scott  4096 Jun 22 15:05 sysroot-destdir
    drwxrwxr-x  2 scott scott 12288 Jun 22 15:05 temp


The patches and defconfig are the same files from `meta-bbb/recipes-kernel/linux/linux-stable-4.1/`

The files under `git` are the Linux source after the kernel recipe patches have been applied.

The build output happens under `linux-beaglebone-standard-build` and this is where the *defconfig* is copied to a `.config`.


## Changing the kernel config

**NOTE** - Using Yocto 1.8 and Ubuntu 15.04 there is a problem invoking the kernel config.
See this [bug report][menuconfig-bug-report]. Other Linux distros are probably fine.

These two workarounds both worked for me.

1. The easiest is the one mentioned in the bug report, add this to your `build/conf/local.conf`

    OE_TERMINAL = "xterm"

2. Googling I found this one line patch to one of the Yocto/Poky scripts that also works

    scott@t410:~/poky-fido$ git diff
    diff --git a/meta/lib/oe/terminal.py b/meta/lib/oe/terminal.py
    index 4f5c611..65e1ab8 100644
    --- a/meta/lib/oe/terminal.py
    +++ b/meta/lib/oe/terminal.py
    @@ -57,6 +57,8 @@ class Gnome(XTerminal):
         priority = 2
     
         def __init__(self, sh_cmd, title=None, env=None, d=None):
    +        if os.getenv('LC_ALL'): os.putenv('LC_ALL','')
    +
             # Check version
             vernum = check_terminal_version("gnome-terminal")
             if vernum and LooseVersion(vernum) >= '3.10':


I expect an official Yocto fix will be in place soon.


You can invoke the standard kernel configuration editor using bitbake

    ~/bbb/build$ bitbake -c menuconfig virtual/kernel

After you make your changes and save them, the new configuration file can be found here

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.1-r1/linux-beaglebone-standard-build/.config

Copy that `.config` file to

    ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.1/beaglebone/defconfig

Then rebuild your kernel

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel && bitbake virtual/kernel



## Working outside of Yocto

I find it more convenient to work on the kernel outside of the Yocto build system. Builds are definitely faster.

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

    SRCREV = "0f57d86787d8b1076ea8f9cbdddda2a46d534a27"
    SRC_URI = " \
        git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;branch=master \

Here are the commands to checkout that same kernel source

    $ cd ~/bbb
    $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git

If the branch was not *master*, say for instance it was *linux-4.0.y*, then you would checkout that branch

    $ cd linux-stable
    $ git checkout -b linux-4.0.y origin/linux-4.0.y

That gets you to the correct git branch, but depending on whether I've kept the `meta-bbb` repository up-to-date, the current commit on the branch may or may not match the **SRCREV** in the recipe. If they don't match, you can checkout a particular older commit explicitly or you can modify the recipe to use the latest commit. Checking out the same branch is usually sufficient.

### Apply existing patches

Currently the `meta-bbb/recipes-kernel/linux/linux-stable_4.1.bb` recipe has a number of patches that I've included to add support for *spidev*, *i2c* and a few touchscreens. Use *git* to apply these same patches to your new linux-stable repository.

Start by creating a working branch

    ~$ cd ~/bbb/linux-stable
    ~/bbb/linux-stable$ checkout -b work

Here's an example applying all of the patches at once

    ~/bbb/linux-stable$ git am ../meta-bbb/recipes-kernel/linux/linux-stable-4.1/*.patch

Or you could apply selective patches individually.

### Default kernel config

Copy the kernel config file that Yocto use to the new linux-stable repository.

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


Modify `/boot/uEnv.txt` to specify which **dtb** file to load.

	fdtfile="some-dtb"

The `meta-bbb` modified **u-boot** looks for a *uEnv.txt* file in the rootfs `/boot` directory.


[bbb-yocto]: http://www.jumpnowtek.com/yocto/BeagleBone-Systems-with-Yocto.html
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[menuconfig-bug-report]: https://bugzilla.yoctoproject.org/show_bug.cgi?id=7791
