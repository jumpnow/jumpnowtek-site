---
layout: post
title: BeagleBone Black Kernel Development
description: "Customizing the BeagleBone Black kernel"
date: 2015-06-13 11:00:00
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

Currently there is only one recipe `linux-stable_4.0.bb`

Kernel patches and config file are searched for under `meta-bbb/recipes-kernel/linux/linux-stable-4.0/` because of this line in the kernel recipe

    FILESEXTRAPATHS_prepend := "${THISDIR}/linux-stable-4.0:"

The kernel config file is `meta-bbb/recipes-kernel/linux/linux-stable-4.0/beaglebone/defconfig`.

If you had multiple *linux-stable* recipes, maybe *linux-stable_4.0.bb* and *linux-stable_4.1.bb* then the highest revision number, 4.1 in this case, would be used. To specify an earlier version, you could use a line like this in `build/conf/local.conf`

    PREFERRED\_VERSION\_linux-stable = "4.0"

When Yocto builds the *linux-stable-4.0* kernel, it does so under this directory

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.0-r1

The *r1* revision comes from this line in the kernel recipe

    PR = "r1"

Here's a look at that directory after a build

    scott@octo:~/bbb/build/tmp/work/beaglebone-poky-linux-gnueabi/linux-stable/4.0-r1$ ls -l
    total 196
    -rw-r--r--  1 scott scott  1616 Jun 14 08:54 0001-Add-bbb-spi1-spidev-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Jun 14 08:54 0002-Add-bbb-i2c1-dtsi.patch
    -rw-r--r--  1 scott scott  1189 Jun 14 08:54 0003-Add-bbb-i2c2-dtsi.patch
    -rw-r--r--  1 scott scott  3222 Jun 14 08:54 0004-Add-bbb-hdmi-dts.patch
    -rw-r--r--  1 scott scott  4408 Jun 14 08:54 0005-Add-bbb-4dcape70t-dts.patch
    -rw-r--r--  1 scott scott 15054 Jun 14 08:54 0006-Add-ft5x06-touchscreen-driver.patch
    -rw-r--r--  1 scott scott  5324 Jun 14 08:54 0007-Add-bbb-nh5cape-dts.patch
    -rw-r--r--  1 scott scott 84694 Jun 14 08:54 defconfig
    drwxr-xr-x  3 scott scott  4096 Jun 14 09:02 deploy-ipks
    drwxr-xr-x  2 scott scott  4096 Jun 13 09:23 deploy-linux-stable
    lrwxrwxrwx  1 scott scott    62 Jun 14 08:54 git -> /home/scott/bbb/build/tmp/work-shared/beaglebone/kernel-source
    drwxr-xr-x  5 scott scott  4096 Jun 14 09:02 image
    drwxrwxr-x  3 scott scott  4096 Jun 13 09:15 license-destdir
    drwxr-xr-x 20 scott scott  4096 Jun 14 09:02 linux-beaglebone-standard-build
    drwxr-xr-x  4 scott scott  4096 Jun 14 09:02 package
    drwxr-xr-x 66 scott scott  4096 Jun 14 09:02 packages-split
    drwxr-xr-x  7 scott scott  4096 Jun 14 09:02 pkgdata
    drwxrwxr-x  2 scott scott  4096 Jun 14 09:02 pseudo
    drwxr-xr-x  3 scott scott  4096 Jun 14 09:02 sysroot-destdir
    drwxrwxr-x  2 scott scott 20480 Jun 14 09:02 temp

The patches and defconfig are the same files from `meta-bbb/recipes-kernel/linux/linux-stable-4.0/`

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

    <TMPDIR>/work/beaglebone-poky-linux-gnueabi/linux-stable/4.0-r1/linux-beaglebone-standard-build/.config

Copy that `.config` file to

    ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.0/beaglebone/defconfig

Then rebuild your kernel

    ~/bbb/build$ bitbake -c cleansstate virtual/kernel && bitbake virtual/kernel



## Working outside of Yocto

It's often more convenient to work on the kernel outside of the Yocto build system. It's definitely faster.

### Cross-compiler

The Yocto tools will build a cross-compiler with headers and libraries that you can easily install on multiple machines.

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

The kernel recipe *linux-stable_4.0.bb* has the repository location, branch and commit of the kernel source used by Yocto.

These lines have the details

    SRCREV = "be4cb235441a691ee63ba5e00843a9c210be5b8a"
    SRC_URI = " \
        git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;branch=linux-4.0.y \

Here are the commands to checkout that same kernel source

    $ cd ~/bbb
    $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
    $ cd linux-stable
    $ git checkout -b linux-4.0.y origin/linux-4.0.y

That gets you to the correct git branch. Depending on whether I've kept the `meta-bbb` repository up-to-date, the current commit on the *linux-4.0.y* branch may or may not match the **SRCREV** in the recipe. If they don't match, you can checkout a particular older commit explicitly or you can modify the recipe to use the latest commit. Checking out the same branch is usually sufficient.

### Apply existing patches

Currently the `meta-bbb/recipes-kernel/linux/linux-stable_4.0.bb` recipe has a number of patches that I've included to add support for spidev, i2c and a few touchscreens. Use *git* to apply these same patches to your new linux-stable repository.

Start by creating a working branch

    ~$ cd ~/bbb/linux-stable
    ~/bbb/linux-stable$ checkout -b work

Now apply the patches. Here's all of them at once.

    ~/bbb/linux-stable$ git am ../meta-bbb/recipes-kernel/linux/linux-stable-4.0/*.patch

Or you could apply them individually.

### Default kernel config

Copy the kernel config file that Yocto use to the new linux-stable repository.

    cp ~/bbb/meta-bbb/recipes-kernel/linux/linux-stable-4.0/beaglebone/defconfig ~/bbb/linux-stable/.config

If you make changes to the config that you want to keep, make sure to copy it back to `meta-bbb/.../defconfig`



[bbb-yocto]: http://www.jumpnowtek.com/yocto/BeagleBone-Systems-with-Yocto.html
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[menuconfig-bug-report]: https://bugzilla.yoctoproject.org/show_bug.cgi?id=7791
