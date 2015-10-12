---
layout: post
title: Building Duovero Systems with Yocto
description: "Building customized systems for Gumstix Duovero using tools from the Yocto Project"
date: 2015-10-12 19:30:00
categories: gumstix-linux 
tags: [linux, gumstix, duovero, yocto]
---

Some notes on building systems for [Gumstix Duovero][duovero] boards using tools from the [Yocto Project][yocto].

The [meta-duovero][meta-duovero] layer described generates some basic systems with packages to support, C, C++, Qt5, Perl and Python development. 

I use this as a template when starting new *Duovero* projects.

### System Info

The Yocto version is `1.8.1` the `[fido]` branch.

The `4.2.3` Linux kernel comes from the [linux-stable][linux-stable] repository.

The [u-boot][uboot] version is `2015.07`.

These are **sysvinit** systems.

The Qt version is `5.4.2`. By default there is no *X11* and no desktop installed. [Qt][qt] gui applications can be run using the `-platform linuxfb` switch.

A light-weight *X11* desktop can be added with minimal changes to the build configuration.

Perl `5.20` with a number of modules is included.

Python `2.7.9` is included with at least enough packages to run [Bottle python][bottle-python] web applications. Additional packages are easily added.

The Duovero [Zephyr][duovero-zephyr] COM has a built-in Wifi/Bluetooth radio. The kernel and software to support both are included. Access point mode is supported. Some [instructions here][jumpnow-duovero-ap].

NOTE: I haven't tested Bluetooth with the 4.x kernels.

*Device tree* binaries are generated and installed that support

1. HDMI (`jumpnow-duovero-parlor.dtb`)
2. No display (`jumpnow-duovero-parlor-nodisplay.dtb`)
 
Both add *SPI* support to the kernel.

You can switch between the *dtbs* using a u-boot script file `/boot/uEnv.txt`. If you don't use a *uEnv.txt* script, then the default `omap4-duovero-parlor.dtb` will be loaded. 

An example *uEnv.txt* is in `meta-duovero/scripts`.

*spidev* on SPI bus 1 (CS 0,1,2) and SPI bus 4 (CS 0) are configured for use from the *Parlor header*.

The following kernel patches under `meta-duovero/recipes-kernel/linux/linux-stable-4.2/` add this functionality

* 0001-spidev-Add-generic-compatible-dt-id.patch
* 0002-duovero-Add-spi1-spidev-dtsi.patch
* 0003-duovero-Add-spi4-spidev-dtsi.patch

See the respective patches for the particular pins to use for the different SPI busses and CS pins.

*UART2* is available as `/dev/ttyO1` from the header pins *15* TX and *17* RX.

There are some simple loopback test programs included in the console image.
 
[spiloop][spiloop] is a utility for testing the *spidev* driver.

[serialecho][serialecho] is a utility for testing the *uart*.

There is a Qt5 test program [tspress][tspress] in the *qt5-image*.

### Ubuntu Packages

I have been using *Ubuntu 15.04* 64-bit workstations to build these systems.

You'll need at least the following packages installed

    build-essential
    git
    pkg-config
    diffstat
    texi2html
    texinfo
    gawk
    chrpath
    subversion
    libncurses5-dev
    u-boot-tools

You'll also want to change the default Ubuntu shell from `dash` to `bash` by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Clone the dependency repositories

First the main Yocto project `poky` repository

    scott@octo:~ git clone -b fido git://git.yoctoproject.org/poky.git poky-fido

Then the `meta-openembedded` repository

    scott@octo:~$ cd poky-fido
    scott@octo:~/poky-fido$ git clone -b fido git://git.openembedded.org/meta-openembedded

And `meta-qt5` repository

    scott@octo:~/poky-fido$ git clone -b fido https://github.com/meta-qt5/meta-qt5.git


I keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-duovero repository

Create a sub-directory for the `meta-duovero` repository before cloning

    scott@octo:~$ mkdir ~/duovero
    scott@octo:~$ cd ~/duovero
    scott@octo:~/duovero$ git clone -b fido git://github.com/jumpnow/meta-duovero

The `meta-duovero/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/duovero/` with the `meta-duovero` layer.

You could manually create the directory structure like this

    scott@octo:~$ mkdir -p ~/duovero/build/conf

Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@octo:~$ source poky-fido/oe-init-build-env ~/duovero/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-duovero/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@octo:~/duovero$ cp meta-duovero/conf/local.conf-sample build/conf/local.conf
    scott@octo:~/duovero$ cp meta-duovero/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the above instructions when cloning. 

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-fido/
         meta-openembedded/
         meta-qt5/
         ...

    ~/duovero/
        meta-duovero/
        build/
            conf/

### Edit local.conf

The variables you may want to customize are the following:

- TMPDIR
- DL\_DIR
- SSTATE\_DIR

The defaults work fine. Adjustments are optional.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 35GB. You probably want at least 50GB available.

The default location is in the `build` directory, in this example `~/duovero/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build. Also because of some `rpath` issues with gcc, the `TMPDIR` path cannot be too short or the gcc build will fail. I haven't determined exactly how short is too short, but something like `/oe9` is too short and `/oe9/tmp-poky-fido-build` is long enough.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/duovero/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/duovero/build/sstate-cache`.

 
### Run the build

You need to source the environment every time you want to run a build. The `oe-init-build-env` when run a second time will not overwrite your customized conf files.

    scott@octo:~$ source poky-fido/oe-init-build-env ~/duovero/build

    ### Shell environment set up for builds. ###

    You can now run 'bitbake '

    Common targets are:
        core-image-minimal
        core-image-sato
        meta-toolchain
        meta-toolchain-sdk
        adt-installer
        meta-ide-support

    You can also run generated qemu images with a command like 'runqemu qemux86'
    scott@octo:~/duovero/build$


Those 'Common targets' may or may not build successfully. I have never tried them.

There are a few custom images available in the [meta-duovero][meta-duovero] layer. The recipes for these image can be found in `meta-duovero/images/`

    console-image.bb
    qt5-image.bb

Place your own image recipes in this same directory.

#### console-image

A basic console developer image. See the recipe `meta-duovero/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    perl and python
    ssh/scp server and client
    wireless support
    kernel modules

The *console-image* has a line

    inherit core-image

which is `poky-fido/meta/classes/core-image.bbclass` and pulls in some required base packages. This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` with the associated development headers and `qmake`.

### Build

To build the `console-image` run the following command

    scott@octo:~/duovero/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this.

    scott@octo:~/duovero/build$ bitbake -c cleansstate zip
    scott@octo:~/duovero/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/duovero/build$ bitbake console-image

To build the `qt5-image` it would be

    scott@octo:~/duovero/build$ bitbake qt5-image

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.
 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/duovero/`.

The `meta-duovero/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@octo:~/duovero/meta-duovero$ lsblk
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

    scott@octo:~$ cd ~/duovero/meta-duovero/scripts
    scott@octo:~/duovero/meta-duovero/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@octo:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) to the boot partition of the SD card.

This script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/tmp-poky-fido-build"

Then I would export this environment variable before running `copy_boot.sh`

    scott@octo:~/duovero/meta-duovero/scripts$ export OETMP=/oe9/tmp-poky-fido-build

Then run the `copy_boot.sh` script passing the location of SD card

    scott@octo:~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the *zImage* kernel, the device tree binaries and the rest of the operating system to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, for example `console` or `qt5`. The default is `console`.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `duovero`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdb qt5 duo1

The *copy_rootfs.sh* script will take longer to run and depends a lot on the size and quality of your SD card.

The copy scripts will **NOT** unmount partitions automatically. If the partition that is supposed to be the on the SD card is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe9/tmp-poky-fido-build
    scott@octo:~$ cd duovero/meta-duovero/scripts
    scott@octo:~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdb
    scott@octo:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdb console duo2

Both *copy_boot.sh* and *copy_rootfs.sh* are simple scripts easily modified for custom use.

#### Some custom package examples

[spiloop][spiloop] is a spidev test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-duovero/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *J9.3* and *J9.5* for SPI bus 1 or pins *J9.25* and *J9.27* for SPI bus 4. That's if you are using one of the jumpnow dtbs that includes the spidev.dtsi files.


[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-image*.

The *bitbake recipe* is here

    meta-duovero/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-fido/oe-init-build-env ~/duovero/build

    scott@octo:~/duovero/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [post][bbb-kernel] for some ways to go about customizing and rebuilding the *Duovero* kernel or generating a new device tree. Replace **bbb** with **duovero** when reading.

#### Package management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].


[duovero]: https://store.gumstix.com/index.php/category/43/
[duovero-zephyr]: https://store.gumstix.com/index.php/products/355/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-duovero]: https://github.com/jumpnow/meta-duovero
[lsblk]: http://linux.die.net/man/8/lsblk
[tspress]: https://github.com/scottellis/tspress
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bbb-kernel]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[bottle-python]: http://bottlepy.org/docs/dev/index.html
[jumpnow-duovero-ap]: http://www.jumpnowtek.com/gumstix-linux/Duovero-Access-Point.html
