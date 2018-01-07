---
layout: post
title: Building Duovero Systems with Yocto
description: "Building customized systems for Gumstix Duovero using tools from the Yocto Project"
date: 2018-01-07 14:40:00
categories: gumstix-linux 
tags: [linux, gumstix, duovero, yocto]
---

This post is about building Linux systems for [Gumstix Duovero][duovero] boards using tools from the [Yocto Project][yocto].

Yocto is a set of tools for building a custom embedded Linux distribution. The systems are usually targeted for a particular application like a commercial product.

Yocto uses what it calls **meta-layers** to define the configuration for a system build. Within each meta-layer are recipes, classes and configuration files that support the primary build tool, a python framework called **bitbake**.

I have a custom Yocto layer for the Duoveros called [meta-duovero][meta-duovero]. I am not using the Gumstix Yocto meta-layer.


### System Info

The Yocto version is **2.4**, the `[rocko]` branch.

The default kernel is **4.14**. A recipe for a **4.9** kernel is also available.

The u-boot version is **2017.09**.

These are **sysvinit** systems using [eudev][eudev].

Python **3.5.3** is installed.

My systems use **sysvinit**, but Yocto supports **systemd** if you would rather use that.

Only one device tree is built with the **4.14** and **4.9** recipes, the in-tree

* omap4-duovero-parlor.dtb

Custom dtbs can be easily written.

### Ubuntu Setup

I primarily use **16.04** 64-bit servers for builds. Other versions should work.

You will need at least the following packages installed

    build-essential
    chrpath
    diffstat
    libncurses5-dev
    texinfo

For **16.04** you also need to install the **python 2.7** package

    python2.7

And then create a link for it in `/usr/bin`

    sudo ln -sf /usr/bin/python2.7 /usr/bin/python

For all versions of Ubuntu, you should change the default Ubuntu shell from **dash** to **bash** by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Fedora Setup

I have used a **Fedora 27** 64-bit workstation.

The extra packages I needed to install for Yocto were

    chrpath
    perl-bignum
    perl-Thread-Queue
    texinfo

and the package group

    Development Tools

Fedora already uses **bash** as the shell. 

### Clone the dependency repositories

For all upstream repositories, use the `[rocko]` branch.

The directory layout I am describing here is my preference. All of the paths to the meta-layers are configurable. If you choose something different, adjust the following instructions accordingly.

First the main Yocto project **poky** layer

    ~# git clone -b rocko git://git.yoctoproject.org/poky.git poky-rocko

Then the dependency layers under that

    ~$ cd poky-rocko
    ~/poky-rocko$ git clone -b rocko git://git.openembedded.org/meta-openembedded

These repositories shouldn't need modifications other then periodic updates and can be reused for different projects or different boards.

### Clone the meta-duovero repository

Create a sub-directory for the `meta-duovero` repository before cloning

    ~$ mkdir ~/duovero
    ~$ cd ~/duovero
    ~/duovero$ git clone -b rocko git://github.com/jumpnow/meta-duovero

The `meta-duovero/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Again much of the following are only my conventions.
 
Choose a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/duovero/` with the `meta-duovero` layer.

You could manually create the directory structure like this

    $ mkdir -p ~/duovero/build/conf


Or you could use the Yocto environment script **oe-init-build-env** like this passing in the path to the build directory

    ~$ source poky-rocko/oe-init-build-env ~/duovero/build

The Yocto environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the **meta-duovero/conf** directory.

Copy them to the **build/conf** directory (removing the '-sample')

    ~/duovero$ cp meta-duovero/conf/local.conf.sample build/conf/local.conf
    ~/duovero$ cp meta-duovero/conf/bblayers.conf.sample build/conf/bblayers.conf

If you used the **oe-init-build-env** script to create the build directory, it generated some generic configuration files in the **build/conf** directory. If you want to look at them, save them with a different name before overwriting.

It is not necessary, but you may want to customize the configuration files before your first build.

**Warning:** Do not use the '**~**' character when defining directory paths in the Yocto configuration files. 

### Edit bblayers.conf

In **bblayers.conf** file replace **${HOME}** with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

**WARNING:** Do not include **meta-yocto-bsp** in your **bblayers.conf**. The Yocto BSP requirements for the duovoers are in **meta-duovero**.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`

    ~/poky-rocko/
         meta-openembedded/
         ...

    ~/duovero/
        meta-duovero/
        build/
            conf/


### Edit local.conf

The variables you may want to customize are the following:

* TMPDIR
* DL\_DIR
* SSTATE\_DIR

All of the following modifications are optional.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least **50GB**.

The default location is under the **build** directory, in this example **~/duovero/build/tmp**.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and builds so I always create a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the **build** directory, **~/duovero/build/sources**.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then **8GB**. I often put this somewhere else other then my home directory as well.

The default location is in the **build** directory, **~/duovero/build/sstate-cache**.

 
### Build

To build the `console-image` run the following command

    ~/duovero/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    ~/duovero/build$ bitbake -c cleansstate zip
    ~/duovero/build$ bitbake zip

And then continue with the full build.

    ~/duovero/build$ bitbake console-image


### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/duovero/`.

The `meta-duovero/scripts` directory has some helper scripts to format and copy the files to a microSD card.

### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/duovero/`.

The `meta-duovero/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    ~/duovero/meta-duovero$ lsblk
    NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda       8:0    0 931.5G  0 disk
    |-sda1    8:1    0  93.1G  0 part /
    |-sda2    8:2    0  93.1G  0 part /home
    |-sda3    8:3    0  29.8G  0 part [SWAP]
    |-sda4    8:4    0     1K  0 part
    |-sda5    8:5    0   100G  0 part /oe5
    |-sda6    8:6    0   100G  0 part /oe6
    |-sda7    8:7    0   100G  0 part /oe7
    |-sda8    8:8    0   100G  0 part /oe8
    |-sda9    8:9    0   100G  0 part /oe9
    `-sda10   8:10   0 215.5G  0 part /oe10
    sdb       8:16   1   7.4G  0 disk
    |-sdb1    8:17   1    64M  0 part
    `-sdb2    8:18   1   7.3G  0 part

I would use `sdb` for the format and copy script parameters on this machine.
 
It doesn't matter if some partitions from the SD card are mounted. The `mk2parts.sh` script will unmount them.

**BE CAREFUL** with this script. It will format any disk on your workstation.

    ~$ cd ~/duovero/meta-duovero/scripts
    ~/duovero/meta-duovero/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    ~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) to the boot partition of the SD card.

This script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/duo/tmp-rocko"

Then I would export this environment variable before running `copy_boot.sh`

    ~/duovero/meta-duovero/scripts$ export OETMP=/oe9/duo/tmp-rocko

Then run the `copy_boot.sh` script passing the location of SD card

    ~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the **zImage** kernel, the device tree binaries and the rest of the operating system to the root file system partition of the SD card.

The script accepts an optional command line argument for the image name, for example **console**.
The default is **console** for the **console-image**.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `duovero`.

Here's an example of how you'd run `copy_rootfs.sh`

    ~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdb console

The **copy_rootfs.sh** script will take longer to run and depends a lot on the size and quality of your SD card.

The copy scripts will **NOT** unmount partitions automatically. If the partition that is supposed to be the on the SD card is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    ~$ sudo umount /dev/sdb1
    ~$ sudo umount /dev/sdb2
    ~$ export OETMP=/oe9/duo/tmp-rocko
    ~$ cd duovero/meta-duovero/scripts
    ~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdb
    ~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdb console duo2

Both **copy_boot.sh** and **copy_rootfs.sh** are simple scripts easily modified for custom use.


[duovero]: https://store.gumstix.com/index.php/category/43/
[duovero-zephyr]: https://store.gumstix.com/index.php/products/355/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[yocto]: https://www.yoctoproject.org/
[meta-duovero]: https://github.com/jumpnow/meta-duovero
[lsblk]: http://linux.die.net/man/8/lsblk
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev
