---
layout: post
title: Building Raspberry Pi Systems with Yocto
description: "Building customized systems for the Raspberry Pi using tools from the Yocto Project"
date: 2015-12-04 16:15:00
categories: rpi
tags: [linux, rpi, yocto]
---

Building systems for [Raspberry Pi 2][rpi] boards using tools from the [Yocto Project][Yocto].

The [meta-rpi][meta-rpi] *layer* generates some basic systems with packages to support C, C++, [Qt5][qt], Perl and Python development.

For now I'm just working with `BCM2836` quad-core *RPi 2* boards in `meta-rpi`.

The Yocto `meta-raspberrypi` layer which is handling the kernel and bootloader for this layer also supports the `BCM2835` single-core RPi boards.

When my [Raspberry Pi Zero][rpi-zero] board gets in, I'll add support here in `meta-rpi`. Until then I'm only using *RPi 2s*, since they are basically the same price with a lot more power. 

### System Info

The Yocto version is `2.0` the `[jethro]` branch.

The `4.1` Linux kernel comes from the [github.com/raspberrypi/linux][rpi-kernel] repository.

These are **sysvinit** systems.

The Qt version is `5.5.1`.

[ZeroMQ][zeromq] version `4.1.3` with development headers and libs is included.

Perl `5.22` and Python `2.7.9` each with a number of modules is included.

[omxplayer][omxplayer] for playing video and audio files from the command line, hardware accelerated.

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

    scott@octo:~ git clone -b jethro git://git.yoctoproject.org/poky.git poky-jethro

The `meta-openembedded` repository

    scott@octo:~$ cd poky-jethro
    scott@octo:~/poky-jethro$ git clone -b jethro git://git.openembedded.org/meta-openembedded

The `meta-qt5` repository

    scott@octo:~/poky-jethro$ git clone -b jethro https://github.com/meta-qt5/meta-qt5.git

And finally the `meta-raspberrypi` repository

    scott@octo:~/poky-jethro$ git clone -b jethro git://git.yoctoproject.org/meta-raspberrypi


### Clone the meta-rpi repository

Create a separate sub-directory for the `meta-rpi` repository before cloning. This is where you will be doing customizations.

    scott@octo:~$ mkdir ~/rpi
    scott@octo:~$ cd ~/rpi
    scott@octo:~/rpi$ git clone -b jethro git://github.com/jumpnow/meta-rpi

The `meta-rpi/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/rpi/` with the `meta-rpi` layer.

You could manually create the directory structure like this

    scott@octo:~$ mkdir -p ~/rpi/build/conf


Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/rpi/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-rpi/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@octo:~/rpi$ cp meta-rpi/conf/local.conf-sample build/conf/local.conf
    scott@octo:~/rpi$ cp meta-rpi/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-jethro/
         meta-openembedded/
         meta-qt5/
         meta-raspberrypi
         ...

    ~/rpi/
        meta-rpi/
        build/
            conf/


### Edit local.conf

The variables you may want to customize are the following:

- TMPDIR
- DL\_DIR
- SSTATE\_DIR

The defaults for all of these work fine. Adjustments are optional.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 50GB. You probably want at least 80GB available.

The default location is in the `build` directory, in this example `~/rpi/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/rpi/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 8GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/rpi/build/sstate-cache`.

### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The `oe-init-build-env` will not overwrite your customized conf files.

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/rpi/build

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
    scott@octo:~/rpi/build$


I don't use those *Common targets*, but instead use my own custom image recipes.

There are three custom images available in the *meta-rpi* layer. The recipes for the images can be found in `meta-rpi/images/`

* console-image.bb
* x11-image.bb
* qt5-x11-image.bb

You should add your own custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-rpi/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    perl and python with a number of modules
    omxplayer

The *console-image* has a line

    inherit core-image

which is `poky-jethro/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

#### x11-image

This image installs the lightweight *Matchbox* X11 desktop using the Yocto Sato theme.

#### qt5-x11-image

This image includes the `x11-image` and adds `Qt5` with the associated development headers and `qmake`.

### Build

To build the `console-image` run the following command

    scott@octo:~/rpi/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    scott@octo:~/rpi/build$ bitbake -c cleansstate zip
    scott@octo:~/rpi/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/rpi/build$ bitbake console-image

To build the `qt5-x11-image` it would be

    scott@octo:~/rpi/build$ bitbake qt5-x11-image

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/raspberrypi2/`.

The `meta-rpi/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the RPI.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@octo:~/rpi/meta-rpi$ lsblk
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

    scott@octo:~$ cd ~/rpi/meta-rpi/scripts
    scott@octo:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@octo:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the BCM2835 bootloader files, the Linux kenrel and RPI2 dtb and a number of DTB overlays (that I have not tried) to the boot partition of the SD card.

This *copy_boot.sh* script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe8/rpi/tmp-jethro"

Then I would export this environment variable before running `copy_boot.sh`

    scott@octo:~/rpi/meta-rpi/scripts$ export OETMP=/oe8/rpi/tmp-jethro

Then run the `copy_boot.sh` script passing the location of SD card

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the root file system to the second partition of the SD card.
 
The script accepts an optional command line argument for the image type, for example `console` or `qt5-x11`. The default is `console` if no argument is provided.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `raspberrypi2`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb qt5-x11 rpi2

The *copy\_rootfs.sh* script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe8/rpi/tmp-jethro
    scott@octo:~$ cd rpi/meta-rpi/scripts
    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdb
    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb console rpi


Both *copy\_boot.sh* and *copy\_rootfs.sh* are simple scripts easily modified for custom use. Once I get past the development stage I usually wrap them both with another script for convenience.

#### Some custom package examples

[spiloop][spiloop] is a *spidev* test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-rpi/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *19* and *21*.

[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-x11-image*.

The *bitbake recipe* is here

    meta-rpi/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

[qcolorcheck][qcolorcheck] is another simple Qt5 GUI application. I use it when working on new display drivers. It gets installed in `/usr/bin` with the *qt5-x11-image*.

The *bitbake recipe* is here

    meta-rpi/recipes-qt/qcolorcheck/qcolorcheck.bb

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/rpi/build

    scott@octo:~/rpi/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image`, `x11-image` or `qt5-x11-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `x11-image` does or create a   complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.


[rpi]: https://www.raspberrypi.org/
[rpi-zero]: https://www.raspberrypi.org/blog/raspberry-pi-zero/
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-rpi]: https://github.com/jumpnow/meta-rpi
[omxplayer]: http://elinux.org/Omxplayer
[rpi-kernel]: https://github.com/raspberrypi/linux
[tspress]: https://github.com/scottellis/tspress
[qcolorcheck]:  https://github.com/scottellis/qcolorcheck
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bitbake]: https://www.yoctoproject.org/docs/1.8/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-sh
[zeromq]: http://zeromq.org/