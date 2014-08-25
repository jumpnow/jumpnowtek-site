---
layout: post
title: Building Wandboard Systems with Yocto
description: "Building customized systems for Wandboards using tools from the Yocto Project"
date: 2014-02-28 02:07:00
categories: wandboard
tags: [linux, wandboard, yocto]
---

These instructions are for building generic developer systems for 
[Wandboard][wandboard] boards with a focus on C/C++ and Qt programmers. You will
almost certainly want to modify the contents of the images for any particular
project. 

There is no `X11` and no desktop installed on any of these systems. The
`embedded Qt` images can be used to run GUI applications with the `-qws` switch. 

The Linux kernel version is `3.10.17`.

The Yocto version is `1.6.1` the `[daisy]` branch.

`sysvinit` is used for the init system *NOT* `systemd`.

### Ubuntu Packages

I've tested `Ubuntu 14.04` 64-bit workstations for the build.

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

You'll also want to change the default Ubuntu shell from `dash` to `bash`
by running this command from a shell
 
    dpkg-reconfigure dash

Choose bash when prompted.

### Clone the dependency repositories

The main Yocto project `poky` repository

    scott@hex:~ git clone -b daisy git://git.yoctoproject.org/poky.git poky-daisy

The `meta-openembedded` repository

    scott@hex:~$ cd ~/poky-daisy
    scott@hex:~/poky-daisy$ git clone -b daisy git://git.openembedded.org/meta-openembedded

I like to keep the *wandboard (Freescale)* only repos in a separate sub-directory.

    scott@hex:~$ mkdir ~/wandboard
	scott@hex:~$ cd ~/wandboard
  
The `meta-fsl-arm` repository

    scott@hex:~/wandboard$ git clone -b daisy git://github.com/Freescale/meta-fsl-arm

The `meta-fsl-arm-extra` repository

    scott@hex:~/wandboard$ git clone -b daisy git://github.com/Freescale/meta-fsl-arm-extra

My `meta-wandboard` repository

    scott@hex:~/wandboard$ git clone -b daisy git://github.com/jumpnow/meta-wandboard


The `meta-wandboard/README.md` file has the last commits from the dependency
repositories that I tested. You can always checkout those commits explicitly if
you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to
the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per
project basis so I can quickly switch between projects. For this example I'll
put the build directory under `~/wandboard/` with the `meta-wandboard` layer.

    scott@hex:~$ source poky-daisy/oe-init-build-env ~/wandboard/build

You always need this command to setup the environment before using `bitbake`.
If you only have one build environment, you can put it in your `~/.bashrc`.
I work on more then one system so tend to always run it manually.
 
### Customize the conf files

The `oe-init-build-env` script generated some generic configuration files in
the `build/conf` directory. You want to replace those with the conf-samples
in the `meta-wandboard/conf` directory.

	scott@hex:~/wandboard/build$ cp ~/wandboard/meta-wandboard/conf/local.conf-sample \
      conf/local.conf
    scott@hex:~/wandboard/build$ cp ~/wandboard/meta-wandboard/conf/bblayers.conf-sample \
      conf/bblayers.conf

You generally only have to edit these files once.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the
meta-layer repositories on your system if you modified any of the above
instructions when cloning. 

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

This is where temporary build files and the final build binaries will end up.
Expect to use at least 35GB. You probably want at least 50GB available.

The default location if left commented will be `~/wandboard/build/tmp`. If I'm
not working in a VM, I usually put the `TMPDIR` on dedicated partitions.
Occasionally something will come up where you'll need to delete the entire 
`TMPDIR`. For those occasions the sequence unmount/mkfs/remount is much
faster then deleting a 35+ GB directory. 

If you specify an alternate location as I do in the example conf file make sure
the directory is writable by the user running the build. Also because of some
`rpath` issues with gcc, the `TMPDIR` path cannot be too short or the gcc build
will fail. I haven't determined exactly how short is too short, but something
like `/oe20` is too short and `/oe20/tmp-poky-daisy-build` is long enough.

If you use the default location, the `TMPDIR` path is already long enough.
     
##### DL\_DIR

This is where the downloaded source files will be stored. You can share this
among configurations and build files so I created a general location for this
outside my home directory. Make sure the build user has write permission to the
directory you decide on.

The default directory will be `~/wandboard/build/sources`.

##### SSTATE\_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB.
I often put this somewhere else other then my home directory as well.

The default location is `~/wandboard/build/sstate-cache`.
 
 
### Run the build

You need to source the environment every time you want to run a build. The 
`oe-init-build-env` when run a second time will not overwrite your customized
conf files.

    scott@hex:~$ cd ~/poky-daisy
    scott@hex:~$ source oe-init-build-env ~/wandboard/build

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
    scott@hex:~/wandboard/build$

Those 'Common targets' may or may not build successfully. I have never tried
them.

There are a few custom images available in the meta-wandboard layer. The recipes
for these image can be found in `meta-wandboard/images/`

    console-image.bb
    qte-image.bb


#### console-image

A basic console developer image. See the recipe for specifics, but some of the
installed programs are

    gcc/g++ and associated build tools
    git
    opencv
    ssh/scp server and client
    wireless support
    kernel modules

#### qte-image

This image includes the `console-image` and adds Qt 4.8.5 embedded
with the associated development headers and qmake.

This image also includes the [SyntroCore][syntrocore] and [SyntroLCam][syntrolcam]
binaries as well as the headers and libraries for doing `Syntro` development
directly on the wandboard.

To build the `console-image` run the following command

    scott@hex:~/wandboard/build$ bitbake console-image

You may run into build errors related to packages that failed to download or
sometimes out of order builds. The easy solution is to clean the build for the
failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this.

    scott@hex:~/wandboard/build$ bitbake -c cleansstate zip
    scott@hex:~/wandboard/build$ bitbake zip

And then continue with the full build.

    scott@hex:~/wandboard/build$ bitbake console-image

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be
found in `TMPDIR/deploy/images/wandboard-quad/`.

The `meta-wandboard/scripts` directory has some helper scripts to format and
copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required
for the boards.

Insert the microSD into your workstation and note where it shows up. You may
have to look at your syslog. I'll assume `/dev/sdc` for this example.

It doesn't matter if some partitions from the SD card are mounted. The 
`mk2parts.sh` script will unmount them.

BE CAREFUL with this script. It will format any disk on your workstation.

    scott@hex:~$ cd ~/wandboard/meta-wandboard/scripts
    scott@hex:~/wandboard/meta-wandboard/scripts$ sudo ./mk2parts.sh sdc

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts
to use.

    scott@hex:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) and Linux kernel (uImage) to
the boot partition of the SD card.

This script needs to know the `TMPDIR` to find the binaries. It looks for an
environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe20/tmp-poky-daisy-build"

Then I would export this environment variable before running `copy_boot.sh`

    scott@hex:~/wandboard/meta-wandboard/scripts$ export OETMP=/oe20/tmp-poky-daisy-build

Then run the `copy_boot.sh` script passing the location of SD card

    scott@hex:~/wandboard/meta-wandboard/scripts$ ./copy_boot.sh sdc

#### copy_rootfs.sh

This script copies files to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, either
`console` or `qte`. The default is `console`.

The script also accepts a `hostname` argument if you want the host name to be
something other then the default `wandboard-quad`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@hex:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdc console

or

    scott@hex:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdc qte wandq

The copy scripts will **NOT** unmount partitions automatically. If the partition
that is supposed to be the on the SD card is already mounted, the script will 
complain and abort. This is for safety, mine mostly, since I run these scripts
many times a day on different machines and the SD cards show up in different
places.

Here's a realistic example session where I want to copy already built images to
a second SD card that I just inserted.

    scott@hex:~$ sudo umount /dev/sdc1
    scott@hex:~$ sudo umount /dev/sdc2
    scott@hex:~$ export OETMP=/oe20/tmp-poky-daisy-build
    scott@hex:~$ cd wandboard/meta-wandboard/scripts
    scott@hex:~/wandboard/meta-wandboard/scripts$ ./copy_boot.sh sdc
    scott@hex:~/wandboard/meta-wandboard/scripts$ ./copy_rootfs.sh sdc console wandq2


[wandboard]: http://www.wandboard.org/
[wandboard-github]: https://github.com/wandboard-org
[linux-wandboard-recipe]: https://github.com/Freescale/meta-fsl-arm-extra/blob/daisy/recipes-kernel/linux/linux-wandboard_3.10.17.bb
[syntrocore]: https://github.com/Syntro/SyntroCore
[syntrolcam]: https://github.com/Syntro/SyntroLCam
