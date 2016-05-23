---
layout: post
title: Building Overo Systems with Yocto
description: "Building customized systems for Gumstix Overo using tools from the Yocto Project"
date: 2016-05-23 08:30:00
categories: gumstix-linux 
tags: [linux, gumstix, overo, yocto]
---

Some notes on building systems for [Gumstix Overo][overo] boards using tools from the [Yocto Project][yocto].

The [meta-overo][meta-overo] *layer* generates some basic systems with packages to support, C, C++, Qt5, Perl and Python development.

I use this as a template when starting new *Overo* projects.

### System Info

The Yocto version is `2.1` the `[krogoth]` branch.

The `4.4.11` Linux kernel comes from the [linux-stable][linux-stable] repository.

The [u-boot][uboot] version is `2016.05`.

These are **sysvinit** systems using [eudev][eudev].

The Qt version is `5.6.0`. By default there is no *X11* and no desktop installed. [Qt][qt] gui applications can be run using the `-platform linuxfb` switch.

A light-weight *X11* desktop can be added with minimal changes to the build configuration.

Perl `5.22` and Python `2.7.11` each with a number of modules is included.

### Ubuntu Setup

I primarily use Ubuntu *15.10* and *16.04* 64-bit server installations. Other versions should work.

You will need at least the following packages installed

    build-essential
    chrpath
    diffstat
    gawk
    git
    libncurses5-dev
    pkg-config
    subversion
    texi2html
    texinfo

You also want to change the default Ubuntu shell from `dash` to `bash` by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Fedora Setup

I have also used a Fedora *23* 64-bit workstation.

The extra packages I needed to install for Yocto were

    chrpath
    perl-bignum
    perl-Thread-Queue
    texinfo

and the package group

    Development Tools

There might be more packages required since I had already installed *qt-creator* and the *Development Tools* group before I did the first build with Yocto.

Fedora already uses `bash` as the shell. 

### Clone the dependency repositories

First the main Yocto project `poky` repository

    scott@octo:~ git clone -b krogoth git://git.yoctoproject.org/poky.git poky-krogoth

Then the `meta-openembedded` repository

    scott@octo:~$ cd poky-krogoth
    scott@octo:~/poky-krogoth$ git clone -b krogoth git://git.openembedded.org/meta-openembedded

And the `meta-qt5` repository

    scott@octo:~/poky-krogoth$ git clone -b krogoth https://github.com/meta-qt5/meta-qt5.git


I usually keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-overo repository

Create a sub-directory for the `meta-overo` repository before cloning

    scott@octo:~$ mkdir ~/overo
    scott@octo:~$ cd ~/overo
    scott@octo:~/overo$ git clone -b krogoth git://github.com/jumpnow/meta-overo

The `meta-overo/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/overo/` with the `meta-overo` layer.

You could manually create the directory structure like this

    scott@octo:~$ mkdir -p ~/overo/build/conf

Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/overo/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-overo/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@octo:~/overo$ cp meta-overo/conf/local.conf-sample build/conf/local.conf
    scott@octo:~/overo$ cp meta-overo/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the above instructions when cloning. 

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-krogoth/
         meta-openembedded/
         meta-qt5/
         ...

    ~/overo/
        meta-overo/
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

The default location is in the `build` directory, in this example `~/overo/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/overo/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/overo/build/sstate-cache`.

 
### Run the build

You need to source the environment every time you want to run a build. The `oe-init-build-env` when run a second time will not overwrite your customized conf files.

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/overo/build

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
    scott@octo:~/overo/build$


Those 'Common targets' may or may not build successfully. I have never tried them.

There are a few custom images available in the [meta-overo][meta-overo] layer. The recipes for these image can be found in `meta-overo/images/`

    console-image.bb
    qt5-image.bb

Place your own image recipes in this same directory.

#### console-image

A basic console developer image. See the recipe `meta-overo/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    perl and python
    ssh/scp server and client
    wireless support
    kernel modules

The *console-image* has a line

    inherit core-image

which is `poky-krogoth/meta/classes/core-image.bbclass` and pulls in some required base packages. This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` with the associated development headers and `qmake`.

### Build

To build the `console-image` run the following command

    scott@octo:~/overo/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this.

    scott@octo:~/overo/build$ bitbake -c cleansstate zip
    scott@octo:~/overo/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/overo/build$ bitbake console-image

To build the `qt5-image` it would be

    scott@octo:~/overo/build$ bitbake qt5-image

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.
 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/overo/`.

The `meta-overo/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@octo:~/overo/meta-overo$ lsblk
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

    scott@octo:~$ cd ~/overo/meta-overo/scripts
    scott@octo:~/overo/meta-overo/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@octo:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) and a u-boot script `uEnv.txt` to the boot partition of the SD card.

A `uEnv.txt` is required until I upgrade u-boot. The reason is I'm using an *ext4* filesystem since *ext3* was deprecated in the newest kernels. But the default u-boot environment thinks the rootfs will be *ext3*. 

There is a default `uEnv.txt` provided (assumes an Overo Storm and a Tobi expansion board)

    meta-overo/scripts/uEnv.txt

It's a simple text file. Modify it to suit your COM, board, configuration, etc...

This `copy_boot.sh` script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/overo/tmp-krogoth"

Then I would export this environment variable before running `copy_boot.sh`

    scott@octo:~/overo/meta-overo/scripts$ export OETMP=/oe9/overo/tmp-krogoth

Then run the `copy_boot.sh` script passing the location of SD card

    scott@octo:~/overo/meta-overo/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the *zImage* kernel, the device tree binaries and the rest of the operating system to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, for example `console` or `qt5`. The default is `console`.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `overo`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/overo/meta-overo/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/overo/meta-overo/scripts$ ./copy_rootfs.sh sdb qt5 overo1

The *copy_rootfs.sh* script will take longer to run and depends a lot on the size and quality of your SD card.

The copy scripts will **NOT** unmount partitions automatically. If the partition that is supposed to be the on the SD card is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe9/overo/tmp-krogoth
    scott@octo:~$ cd overo/meta-overo/scripts
    scott@octo:~/overo/meta-overo/scripts$ ./copy_boot.sh sdb
    scott@octo:~/overo/meta-overo/scripts$ ./copy_rootfs.sh sdb console overo2

Both *copy_boot.sh* and *copy_rootfs.sh* are simple scripts easily modified for custom use.


#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/overo/build

    scott@octo:~/overo/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [post][bbb-kernel] for some ways to go about customizing and rebuilding the *Overo* kernel or generating a new device tree. Replace **bbb** with **overo** when reading.

#### Package management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].


[overo]: https://store.gumstix.com/index.php/category/33/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-overo]: https://github.com/jumpnow/meta-overo
[lsblk]: http://linux.die.net/man/8/lsblk
[serialecho]: https://github.com/scottellis/serialecho
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bbb-kernel]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev