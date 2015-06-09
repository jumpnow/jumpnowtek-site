---
layout: post
title: Building BeagleBone Black Systems with Yocto
description: "Building customized systems for the BeagleBone Black using tools from the Yocto Project"
date: 2014-11-01 16:28:00
categories: yocto 
tags: [linux, beaglebone, yocto]
---

These instructions are for building generic developer systems for [BeagleBone Black][beagleboard] boards with a focus on C/C++ and Qt programmers. You will almost certainly want to modify the contents of the images for any particular project.

There is no `X11` and no desktop installed on any of these systems. [Qt][qt] gui applications can be run using the `-platform linuxfb` switch. The Qt version is `5.4.1`.

The Linux `4.0.4` kernel comes from the Linux stable repository.

The Yocto version is `1.8.0` the `[fido]` branch.

`sysvinit` is used for the init system. Switching to a `systemd` init system is not too hard. 

### Ubuntu Packages

I've tested this with `Ubuntu 15.04` 64-bit workstations.

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

You also want to change the default Ubuntu shell from `dash` to `bash` by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose *No* to dash when prompted.

### Clone the dependency repositories

First the main Yocto project `poky` repository

    scott@octo:~ git clone -b fido git://git.yoctoproject.org/poky.git poky-fido

Then the supporting `meta-openembedded` repository

    scott@octo:~$ cd poky-fido
    scott@octo:~/poky-fido$ git clone -b fido git://git.openembedded.org/meta-openembedded

And `meta-qt5` repository

    scott@octo:~/poky-fido$ git clone -b fido https://github.com/meta-qt5/meta-qt5.git


I keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-bbb repository

Create a sub-directory for the `meta-bbb` repository before cloning

    scott@octo:~$ mkdir ~/bbb
    scott@octo:~$ cd ~/bbb
    scott@octo:~/bbb$ git clone -b fido git://github.com/jumpnow/meta-bbb

The `meta-bbb/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/bbb/` with the `meta-bbb` layer.

    scott@octo:~$ source poky-fido/oe-init-build-env ~/bbb/build

You always need this command to setup the environment before using `bitbake`. If you only have one build environment, you can put it in your `~/.bashrc`. I work on more then one system so tend to always run it manually.
 
### Customize the conf files

The `oe-init-build-env` script generated some generic configuration files in the `build/conf` directory. You want to replace those with the conf-samples in the `meta-bbb/conf` directory.

    scott@octo:~/bbb/build$ cp ~/bbb/meta-bbb/conf/local.conf-sample conf/local.conf
    scott@octo:~/bbb/build$ cp ~/bbb/meta-bbb/conf/bblayers.conf-sample conf/bblayers.conf

You generally only have to edit these files once.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the above instructions when cloning. 

### Edit local.conf

The variables you may want to customize are the following:

- BB\_NUMBER\_THREADS
- PARALLEL\_MAKE
- TMPDIR
- DL\_DIR
- SSTATE\_DIR

The defaults should work, but I always make some adjustment.

##### BB\_NUMBER\_THREADS

Set to the number of cores on your build machine.

##### PARALLEL\_MAKE

Set to the number of cores on your build machine.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 35GB. You probably want at least 50GB available.

The default location if left commented will be `~/bbb/build/tmp`. If I'm not working in a VM, I usually put my `TMPDIRs` on dedicated partitions. Occasionally something will come up where you'll need to delete the entire `TMPDIR`. For those occasions the sequence unmount/mkfs/remount is much faster then deleting a 35+ GB directory. 

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build. Also because of some `rpath` issues with gcc, the `TMPDIR` path cannot be too short or the gcc build will fail. I haven't determined exactly how short is too short, but something like `/oe9` is too short and `/oe9/tmp-poky-fido-build` is long enough.

If you use the default location, the `TMPDIR` path is already long enough.
     
##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default directory will be `~/bbb/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is `~/bbb/build/sstate-cache`.

 
### Run the build

You need to source the environment every time you want to run a build. The `oe-init-build-env` when run a second time will not overwrite your customized conf files.

    scott@octo:~$ source poky-fido/oe-init-build-env ~/bbb/build

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
    scott@hex:~/duovero/build$


Those 'Common targets' may or may not build successfully. I have never tried them.

There are a few custom images available in the meta-bbb layer. The recipes for these image can be found in `meta-bbb/images/`

    console-image.bb
    qt5-image.bb


#### console-image

A basic console developer image. See the recipe `meta-bbb/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    kernel modules

#### qt5-image

This image includes the `console-image` and adds `Qt 5.4.1` with the associated development headers and `qmake`.

To build the `console-image` run the following command

    scott@octo:~/bbb/build$ bitbake console-image

You may run into build errors related to packages that failed to download or sometimes out of order builds. The easy solution is to clean the build for the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this.

    scott@octo:~/bbb/build$ bitbake -c cleansstate zip
    scott@octo:~/bbb/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/bbb/build$ bitbake console-image

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `TMPDIR/deploy/images/bbb/`.

The `meta-bbb/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up. You may have to look at your syslog. I'll assume `/dev/sdb` for this example.

It doesn't matter if some partitions from the SD card are mounted. The `mk2parts.sh` script will unmount them.

**BE CAREFUL** with this script. It will format any disk on your workstation.

    scott@octo:~$ cd ~/bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@bbb:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) and Linux kernel (uImage) to the boot partition of the SD card.

This script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/tmp-poky-fido-build"

Then I would export this environment variable before running `copy_boot.sh`

    scott@bbb:~/bbb/meta-bbb/scripts$ export OETMP=/oe9/tmp-poky-fido-build

Then run the `copy_boot.sh` script passing the location of SD card

    scott@bbb:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb

#### copy_rootfs.sh

This script copies files to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, either `console` or `qt5`. The default is `console`.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `beaglebone`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb qt5 bbb

The copy scripts will **NOT** unmount partitions automatically. If the partition that is supposed to be the on the SD card is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe9/tmp-poky-fido-build
    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console bbb2


#### Package management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the Duovero system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].


[beagleboard]: http://www.beagleboard.org/
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb

