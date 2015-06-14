---
layout: post
title: BeagleBone Black Kernel Development
description: "Customizing the BeagleBone Black kernel and device tree"
date: 2015-06-13 11:00:00
categories: beaglebone 
tags: [linux, beaglebone, yocto]
---

Once you've built a basic [BeagleBone Black system][bbb-yocto] with the [Yocto Project][yocto] tools, you will probably want to customize the kernel or the device tree that gets loaded at boot.

What follows are some steps I've been using.

### Cross-compiler

First off you'll need a cross-compiler. The Yocto tools will build you one that you can easily install on multiple machines.

I'm assuming you've already built a Yocto system using [these instructions][bbb-yocto] or something similar.

First, choose the architecture where you'll be running the cross-compiler by setting the *SDKMACHINE* variable in your `local.conf` file.

    SDKMACHINE = "x86_64"

The choices are *i686* for 32-bit build workstations or *x86_64* for 64-bit workstations.

Setup the Yocto build environment

    ~$ source poky-fido/oe-init-build-env ~/bbb/build

Then build the sdk installer with the *populate_sdk* command, specifying an image file.
    
    ~/bbb/build$ bitbake -c populate_sdk console-image

When finished, the sdk installer will end up here

    <TMPDIR>/deploy/sdk/poky-glibc-x86_64-console-image-cortexa8hf-vfp-neon-toolchain-1.8.sh

If you run it and accept the defaults, the cross-tools will get installed under `/opt/poky/1.8`.


### Fetch the Linux source

I prefer to work outside of the Yocto TMPDIR when I work on the kernel. I find it much faster then invoking *bitbake* for every build.

The first step is to get the same kernel source that Yocto was using. The kernel recipe has the repository location, branch and commit that was used by Yocto.

For the `meta-bbb` repository, the kernel recipe is

    meta-bbb/recipes-kernel/linux/linux-stable_4.0.bb

These lines have the details

    SRCREV = "be4cb235441a691ee63ba5e00843a9c210be5b8a"
    SRC_URI = " \
        git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git;branch=linux-4.0.y \

Here are the commands to checkout that same kernel source

    $ cd ~/bbb
    $ git clone git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
    $ cd linux-stable
    $ git checkout -b linux-4.0.y origin/linux-4.0.y

That gets you to the correct git branch. Depending on whether I've kept the `meta-bbb` repository up-to-date, the current commit on the *linux-4.0.y* branch may or may not match the **SRCREV** in the recipe. If they don't match, you can checkout a particular older commit explicitly or you can modify the recipe to use the latest commit. Since this is the **stable** branch of Linux, any changes should be minimal and primarily bug fixes.

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

