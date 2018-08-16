---
layout: post
title: Building Odroid-C2 Systems with Yocto
description: "Building customized systems for Odroid-C2 using tools from the Yocto Project"
date: 2018-08-16 10:35:00
categories: odroid 
tags: [linux, odroid-c2, yocto]
---

This post is about building Linux systems for the [Odroid-C2][odroid-c2] using tools from the [Yocto Project][Yocto].

Yocto is a set of tools for building a custom embedded Linux distribution. The systems are usually targeted for a particular application like a commercial product.

Yocto uses what it calls **meta-layers** to define the configuration for a system build. Within each meta-layer are recipes, classes and configuration files that support the primary build tool, a python framework called **bitbake**. 

I have a Yocto layer for the **odroid-c2** called [meta-odroid-c2][meta-odroid-c2].

I am using the **odroid-c2** with some USB webcams in a monitoring system built with Qt.

### System Info

The Yocto version is **2.5.1**, the `[sumo]` branch.

The default kernel is **4.18** 64-bit. There are **4.14 LTS** and **4.17** recipes as well.

The only dtb built is **meson-gxbb-odroidc2.dtb**.

The kernel and userland are 64-bit.

The u-boot version is **2018.01**.

A **boot.scr** is required. There are source files for either SD card or eMMC booting. You can choose with a variable in **local.conf** described below.

These are **sysvinit** systems using [eudev][eudev].

Python **3.5.5** is installed as are the standard C/C++ compiler tools.

gcc/g++ **7.3.0** and associated build tools are installed.

git **2.16.1** is installed.

The Qt version is **5.10.1** built with the **linuxfb** QPA backend.

There is no hardware video acceleration.

### Ubuntu Setup

I primarily use **16.04** 64-bit servers for builds. Other versions should work.

You will need at least the following packages installed

    build-essential
    chrpath
    diffstat
    gawk
    libncurses5-dev
    texinfo

For **16.04** you also need to install the **python 2.7** package

    python2.7

And then create some links for it in `/usr/bin`

    sudo ln -sf /usr/bin/python2.7 /usr/bin/python
    sudo ln -sf /usr/bin/python2.7 /usr/bin/python2

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

For all upstream repositories, use the **[sumo]** branch.

The directory layout I am describing here is my preference. All of the paths to the meta-layers are configurable. If you choose something different, adjust the following instructions accordingly.

First the main Yocto project **poky** layer

    ~# git clone -b sumo git://git.yoctoproject.org/poky.git poky-sumo

Then the dependency layers under that

    ~$ cd poky-sumo
    ~/poky-sumo$ git clone -b sumo git://git.openembedded.org/meta-openembedded
    ~/poky-sumo$ git clone -b sumo https://github.com/meta-qt5/meta-qt5.git

These repositories shouldn't need modifications other then periodic updates and can be reused for different projects or different boards.

### Clone the meta-odroid-c2 repository

Create a sub-directory for the **meta-odroid-c2** repository before cloning

    $ mkdir ~/odroid-c2
    ~$ cd ~/odroid-c2
    ~/odroid-c2$ git clone -b sumo git://github.com/jumpnow/meta-odroid-c2

The **meta-odroid-c2/README.md** file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Again much of the following are only my conventions.
 
Choose a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under **~/odroid-c2/** with the **meta-odroid-c2** layer.

You could manually create the directory structure like this

    $ mkdir -p ~/odroid-c2/build/conf


Or you could use the Yocto environment script **oe-init-build-env** like this passing in the path to the build directory

    ~$ source poky-sumo/oe-init-build-env ~/odroid-c2/build

The Yocto environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the **meta-odroid-c2/conf** directory.

Copy them to the **build/conf** directory (removing the '-sample')

    ~/odroid-c2$ cp meta-odroid-c2/conf/local.conf-sample build/conf/local.conf
    ~/odroid-c2$ cp meta-odroid-c2/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the **oe-init-build-env** script to create the build directory, it generated some generic configuration files in the **build/conf** directory. If you want to look at them, save them with a different name before overwriting.

It is not necessary, but you may want to customize the configuration files before your first build.

**Warning:** Do not use the '**~**' character when defining directory paths in the Yocto configuration files. 

### Edit bblayers.conf

In **bblayers.conf** file replace **${HOME}** with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

**WARNING:** Do not include **meta-yocto-bsp** in your **bblayers.conf**. The Yocto BSP requirements for the odroid-c2 are in **meta-odroid-c2**.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`

    ~/poky-sumo/
         meta-openembedded/
         meta-qt5/
         ...

    ~/odroid-c2/
        meta-odroid-c2/
        build/
            conf/


### Edit local.conf

The variables you may want to customize are the following:

* TMPDIR
* DL\_DIR
* SSTATE\_DIR
* EMMC_BOOT

All of the following modifications are optional.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least **25GB**.

The default location is under the **build** directory, in this example **~/odroid-c2/build/tmp**.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and builds so I always create a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the **build** directory, **~/odroid-c2/build/sources**.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then **3GB**. I often put this somewhere else other then my home directory as well.

The default location is in the **build** directory, **~/odroid-c2/build/sstate-cache**.

#### EMMC_BOOT

If you are using an eMMC device then uncomment this line 

    EMMC_BOOT = "1"

When defined this causes the **u-boot-scr.bb** recipe to use a different source file to build the **boot.scr**. If you leave the line commented the default is to build **boot.scr** for SD card use.

The recipe is here

    meta-odroid-c2/recipes-bsp/u-boot-scr/u-boot-scr.bb

Easy enough to modify if you want to customize the boot script.

#### ROOT PASSWORD

There is only one login user by default, **root**.

The default password is set to **jumpnowtek** by these two lines in the **local.conf** file

    INHERIT += "extrausers"
    EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

Obviously you should change this.

If you want no password, convenient for development, comment those two lines and uncomment this line

    EXTRA_IMAGE_FEATURES = "debug-tweaks"
    #INHERIT += "extrausers"
    #EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

You can also change or add a password once logged in.

### Build

To build the **console-image** run the following command

    ~/odroid-c2/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    ~/odroid-c2/build$ bitbake -c cleansstate zip
    ~/odroid-c2/build$ bitbake zip

And then continue with the full build.

    ~/odroid-c2/build$ bitbake console-image

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs files can be found in 

    <TMPDIR>/deploy/images/odroid-c2/

The **meta-odroid-c2/scripts** directory has some utility scripts to format and copy the files to a microSD or eMMC card.

#### mk1part.sh

This script will partition an SD card with the single partition required for the boards. The script leaves a 4 MB empty region before the first partition for use as explained below.

Insert the microSD or eMMC with adapter into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the device. 

For example

    ~/odroid-c2/meta-odroid-c2$ lsblk
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
    sdb      8:16   1   7.4G  0 disk
    └─sdb1   8:17   1   7.4G  0 part


I would use **sdb** for the format and copy script parameters on this machine.

It doesn't matter if some partitions from the SD card are mounted. The **mk1part.sh** script will unmount them.

**BE CAREFUL** with this script. It will format any disk on your workstation.

    ~$ cd ~/odroid-c2/meta-odroid-c2/scripts
    ~/odroid-c2/meta-odroid-c2/scripts$ sudo ./mk1part.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    ~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader files (u-boot.bin and bl1.bin.hardkernel) to the *unpartitioned* 4MB beginning section of the SD card.

This script needs to know the **TMPDIR** to find the binaries. It looks for an environment variable called **OETMP**.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe6/oc2/tmp-sumo"

then I would export this environment variable before running `copy_boot.sh`

    ~/odroid-c2/meta-odroid-c2/scripts$ export OETMP=/oe9/oc2/tmp-sumo

If you didn't override the default **TMPDIR** in `local.conf`, then set it to the default **TMPDIR**

    ~/odroid-c2/meta-odroid-c2/scripts$ export OETMP=~/odroid-c2/build/tmp

Run the `copy_boot.sh` script passing the location of SD card

    ~/odroid-c2/meta-odroid-c2/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script formats the first partition of the SD card as an **ext4** filesystem and copies the operating system to it.
 
The script accepts an optional command line argument for the image type, for example **console**. Currently **console** is the only image provided, but you can create your own.

The script also accepts a **hostname** argument if you want the host name to be something other then the default **odroid-c2**.

Here's an example of how you'd run **copy\_rootfs.sh**

    ~/odroid-c2/meta-odroid-c2/scripts$ ./copy_rootfs.sh sdb

or

    ~/odroid-c2/meta-odroid-c2/scripts$ ./copy_rootfs.sh sdb console oc2

The **copy\_rootfs.sh** script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    ~$ sudo umount /dev/sdb1
    ~$ export OETMP=/oe6/oc2/tmp-sumo
    ~$ cd odroid-c2/meta-odroid-c2/scripts
    ~/odroid-c2/meta-odroid-c2/scripts$ ./copy_boot.sh sdb
    ~/odroid-c2/meta-odroid-c2/scripts$ ./copy_rootfs.sh sdb console

Both **copy\_boot.sh** and **copy\_rootfs.sh** are simple scripts easily customized.


[odroid-c2]: https://wiki.odroid.com/odroid-c2/odroid-c2
[meta-odroid-c2]: https://github.com/jumpnow/meta-odroid-c2
[linux-stable]: https://www.kernel.org/
[oe-layer-index]: http://layers.openembedded.org/layerindex/branch/master/layers/
[meta-odroid]: https://github.com/akuster/meta-odroid
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[yocto]: https://www.yoctoproject.org/
[lsblk]: http://linux.die.net/man/8/lsblk
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev
[mender]: https://mender.io/product/features