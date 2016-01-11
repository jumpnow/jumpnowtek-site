---
layout: post
title: Building Wandboard Systems with Yocto
description: "Building customized systems for Wandboards using tools from the Yocto Project"
date: 2016-01-11 18:22:00
categories: wandboard 
tags: [linux, wandboard, yocto]
---

Some notes on building systems for [Wandboards][wandboard] using tools from the [Yocto Project][Yocto].

The [meta-wandboard][meta-wandboard] *layer* generates some basic systems with packages to support C, C++, [Qt5][qt], Perl and Python development.

I use this as a template when starting new *Wandboard* projects.

### System Info

The Yocto version is `2.0` the `[jethro]` branch.

The `4.4.0` Linux kernel comes from the [linux-stable][linux-stable] repository.

The [u-boot][uboot] version is `2015.07`.

These are **sysvinit** systems.

The Qt version is `5.5.1`. There is no *X11* and no desktop installed. [Qt][qt] GUI applications can be run using the `-platform linuxfb` switch.

A light-weight *X11* desktop can be added with minimal changes to the build configuration. (*X11* is needed to run Java GUI apps.)

[ZeroMQ][zeromq] version `4.1.3` with development headers and libs is included.

Perl `5.22` and Python `2.7.9` each with a number of modules is included.

The following device tree binaries (dtbs) from the *linux-stable* repository are built and installed

* imx6dl-wandboard-revb1.dtb
* imx6dl-wandboard.dtb
* imx6q-wandboard-revb1.dtb
* imx6q-wandboard.dtb

*U-Boot* should detect the correct *dtb* to load at boot time.

### Ubuntu Workstation Setup

I have been using *Ubuntu 15.04* and *15.10* 64-bit workstations to build these systems.

You will need at least the following packages installed

    bc
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
    u-boot-tools

You also want to change the default Ubuntu shell from `dash` to `bash` by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Clone the dependency repositories

First the main Yocto project `poky` repository

    scott@fractal:~ git clone -b jethro git://git.yoctoproject.org/poky.git poky-jethro

Then the `meta-openembedded` repository

    scott@fractal:~$ cd poky-jethro
    scott@fractal:~/poky-jethro$ git clone -b jethro git://git.openembedded.org/meta-openembedded

And the `meta-qt5` repository

    scott@fractal:~/poky-jethro$ git clone -b jethro https://github.com/meta-qt5/meta-qt5.git


I usually keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-wandboard repository

Create a sub-directory for the `meta-wandboard` repository before cloning

    scott@octo:~$ mkdir ~/wandboard
    scott@octo:~$ cd ~/wanboard
    scott@octo:~/wandboard$ git clone -b jethro git://github.com/jumpnow/meta-wandboard

The `meta-wandboard/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/wandboard/` with the `meta-wandboard` layer.

You could manually create the directory structure like this

    scott@fractal:~$ mkdir -p ~/wandboard/build/conf


Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@fractal:~$ source poky-jethro/oe-init-build-env ~/wandboard/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-wandboard/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@fractal:~/wandboard$ cp meta-wandboard/conf/local.conf-sample build/conf/local.conf
    scott@fractal:~/wandboard$ cp meta-wandboard/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory.
It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-jethro/
         meta-openembedded/
         meta-qt5/
         ...

    ~/wandboard/
        meta-wandboard/
        build/
            conf/


### Edit local.conf

The variables you may want to customize are the following:

- TMPDIR
- DL\_DIR
- SSTATE\_DIR

The defaults for all of these work fine. Adjustments are optional.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 35GB. You probably want at least 50GB available.

The default location is in the `build` directory, in this example `~/wandboard/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/wandboard/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/wandboard/build/sstate-cache`.
 
### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The `oe-init-build-env` will not overwrite your
customized conf files.

    scott@fractal:~$ source poky-jethro/oe-init-build-env ~/wandboard/build

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
    scott@fractal:~/wandboard/build$


I don't use those *Common targets*, but instead use my own custom image recipes.

There are two custom images available in the *meta-wandboard* layer. The recipes for the images can be found in `meta-wandboard/images/`

* console-image.bb
* qt5-image.bb

You should add your own custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-wandboard/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    perl and python
    zeromq

The *console-image* has a line

    inherit core-image

which is `poky-jethro/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` with the associated development headers and `qmake`.

### Build

To build the `console-image` run the following command

    scott@fractal:~/wandboard/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    scott@fractal:~/wandboard/build$ bitbake -c cleansstate zip
    scott@fractal:~/wandboard/build$ bitbake zip

And then continue with the full build.

    scott@fractal:~/wandboard/build$ bitbake console-image

To build the `qt5-image` it would be

    scott@fractal:~/wandboard/build$ bitbake qt5-image

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/wandboard/`.

The `meta-wandboard/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards. The script leaves a 4 MB empty region before the first partition for use as explained below.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@fractal:~/wandboard/meta-wandboard$ lsblk
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

    scott@fractal:~$ cd ~/wandboard/meta-wandboard/scripts
    scott@fractal:~/wandboard/meta-wandboard/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@fractal:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloaders (MLO and u-boot) to the *unpartitioned* 4MB beginning section of the SD card.

The script also formats the first partition of the SD card as a FAT filesystem and copies the kernel (zImage) and a number of DTB files to it.

This script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/wand/tmp-jethro"

Then I would export this environment variable before running `copy_boot.sh`

    scott@fractal:~/wandboard/meta-wandboard/scripts$ export OETMP=/oe9/wand/tmp-jethro

Then run the `copy_boot.sh` script passing the location of SD card

    scott@fractal:~/wandboard/meta-wandboard/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script formats the second partition of the SD card as an *EXT4* filesystem and copies the operating system to it.
 
The script accepts an optional command line argument for the image type, for example `console` or `qt5`. The default is `console` if no argument is provided.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `wandboard`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@fractal:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdb console

or

    scott@fractal:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdb qt5 wandq

The copy_rootfs.sh script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@fractal:~$ sudo umount /dev/sdb1
    scott@fractal:~$ sudo umount /dev/sdb2
    scott@fractal:~$ export OETMP=/oe9/wand/tmp-jethro
    scott@fractal:~$ cd wandboard/meta-wandboard/scripts
    scott@fractal:~/wandboard/meta-wandboard/scripts$ ./copy_boot.sh sdb
    scott@fractal:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdb console wandq2


Both *copy_boot.sh* and *copy_rootfs.sh* are simple scripts easily modified for custom use.

#### Some custom package examples

[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-image*.

The *bitbake recipe* is here

    meta-wandboard/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@fractal:~$ source poky-jethro/oe-init-build-env ~/wandboard/build

    scott@fractal:~/wandboard/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [post][bbb-kernel] for some ways to go about customizing and rebuilding the *Wandboard* kernel or generating a new device tree. Replace **bbb** with **wandboard** when reading.

#### Package management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].


[wandboard]: http://www.wandboard.org/
[meta-wandboard]: https://github.com/jumpnow/meta-wandboard
[zeromq]: http://zeromq.org/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[tspress]: https://github.com/scottellis/tspress
[bbb-kernel]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bitbake]: https://www.yoctoproject.org/docs/1.8/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-
[zeromq]: http://zeromq.org/

