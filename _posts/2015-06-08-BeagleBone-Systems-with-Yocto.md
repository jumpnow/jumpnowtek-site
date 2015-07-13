---
layout: post
title: Building BeagleBone Black Systems with Yocto
description: "Building customized systems for the BeagleBone Black using tools from the Yocto Project"
date: 2015-07-13 05:17:00
categories: beaglebone
tags: [linux, beaglebone, yocto]
---

These instructions are for building generic developer systems for [BeagleBone Black][beagleboard] boards primarily for C, C++ and Qt programmers. The example systems also include Perl and Python.

The `meta-bbb` layer described below **should** be modified for your own particular project. 

The *image recipes* under `meta-bbb/images` are examples with some common packages I find useful. 

The Yocto version is `1.8.0` the `[fido]` branch.

The Linux `4.1.2` kernel comes from the [Linux stable][linux-stable] repository.

The [u-boot][uboot] version is `2015.07-rc3`.

These are *sysvinit* systems.

The Qt version is `5.4.3`. There is no *X11* and no desktop installed. [Qt][qt] gui applications can be run using the `-platform linuxfb` switch. I suspect *QML* apps will not work since I don't have *OpenGL* support in the these systems. My projects on SOC boards like the BBB tend to be touchscreen instrument interfaces with simple UI controls and 2D graphs.

Perl `5.20` with several hundred common modules is included.

Python `2.7.9` is included with enough modules to run [Bottle python][bottle-python] web applications.

*Device tree* binaries are generated and installed that support *HDMI* (bbb-hdmi.dtb), the *4DCape 7-inch* touchscreen (bbb-4dcape70t.dtb) and the *New Haven 5-inch* touchscreen (bbb-nh5cape.dtb). They are easy to switch between using `/boot/uEnv.txt` and all work with the installed *Qt* binaries.

*spidev* on SPI bus 1, *I2C1* and *I2C2* are configured for use from the *P9* header. The following kernel patches under `meta-bbb/recipes-kernel/linux/linux-stable-4.1/` add this functionality

* 0001-spidev-Add-generic-compatible-dt-id.patch
* 0002-Add-bbb-spi1-spidev-dtsi.patch
* 0003-Add-bbb-i2c1-dtsi.patch
* 0004-Add-bbb-i2c2-dtsi.patch

See the respective patches for the particular P9 header pins to use.

There is an small *spidev* test program [spiloop][spiloop] in the *console-image*.

### Ubuntu Packages

I've been building systems with this layer using *Ubuntu 15.04* 64-bit workstations.

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

The defaults for all of these should work just fine. Adjustments are optional.

##### BB\_NUMBER\_THREADS

Set to the number of cores on your build machine. This will significantly speed up the builds.

##### PARALLEL\_MAKE

Set to the number of cores on your build machine. Same as *BB_NUMBER_THREADS*

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 35GB. You probably want at least 50GB available.

The default location if left commented will be `~/bbb/build/tmp`.

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
    scott@octo:~/bbb/build$


Those 'Common targets' may or may not build successfully. I have never tried them.

Instead, there are two custom images available in the meta-bbb layer. The recipes for these images can be found under `meta-bbb/images/`

* console-image.bb
* qt5-image.bb

Add your custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-bbb/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    perl and a number of commonly used modules

The *console-image* has a line

    inherit core-image

which is `poky-fido/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` with the associated development headers and `qmake`.

### Build

To build the `console-image` run the following command

    scott@octo:~/bbb/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    scott@octo:~/bbb/build$ bitbake -c cleansstate zip
    scott@octo:~/bbb/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/bbb/build$ bitbake console-image

To build the `qt5-image` it would be

    scott@octo:~/bbb/build$ bitbake qt5-image

The `cleansstate` command (with two s's) works for image recipes as well. I typically do an

    rm <TMPDIR>/deploy/images/beaglebone/qt5-image*

or

    rm <TMPDIR>/deploy/images/beaglebone/console-image*

after running `cleansstate` on the image, otherwise you will accumulate old build files as Yocto does not automatically clean them.

You can ignore the **README\_-\_DO\_NOT\_DELETE\_FILES\_IN\_THIS\_DIRECTORY.txt** file in that directory. Any files found here are easily recreated.

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/bbb/`.

The `meta-bbb/scripts` directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@octo:~/bbb/meta-bbb$ lsblk
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

    scott@octo:~$ cd ~/bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@bbb:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloaders (MLO and u-boot) to the boot partition of the SD card.

This script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/tmp-poky-fido-build"

Then I would export this environment variable before running `copy_boot.sh`

    scott@bbb:~/bbb/meta-bbb/scripts$ export OETMP=/oe9/tmp-poky-fido-build

Then run the `copy_boot.sh` script passing the location of SD card

    scott@bbb:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the *zImage* Linux kernel, several device tree binaries (*.dtb) and the rest of the system files to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, for example `console` or `qt5`. The default is `console` if no argument is provided.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `beaglebone`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb qt5 bbb

The copy_rootfs.sh script will take longer to run and depends a lot on the quality of your SD card.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe9/tmp-poky-fido-build
    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console bbb2


Both *copy_boot.sh* and *copy_rootfs.sh* are simple scripts easily modified for custom use.

### Booting from the SD card

The **S2** switch on BBB board should be held down until the bootloader starts to force the BBB to boot from the SD card. The **S2** switch is above the SD card holder.

The default behavior of the *BBB* is to boot from the *eMMC* first if it finds a bootloader there.

If you prefer to always boot from the SD card you can erase any existing bootloader from the *eMMC* with something like the following

    root@beaglebone:~# dd if=/dev/zero of=/dev/mmcblk1 bs=4096 count=4096

This is particularly useful during development on systems where the **S2** switch is not easily accessible.

On a system that booted from an SD card, `/dev/mmcblk0` is the SD card and `/dev/mmcblk1` is the *eMMC*.

### Installing to the eMMC

You need a running system to install to the *eMMC*, since it is not accessible otherwise.

The Linux userland tools see the *eMMC* similar to an SD card, so the same scripts slightly modified can be used install a system onto the *eMMC*.

There are some scripts under `meta-bbb/scripts` that are customized for an *eMMC* installation.

* emmc_copy_boot.sh - a modified copy_boot.sh
* emmc_copy_rootfs.sh - a modified copy_rootfs.sh
* emmc_install.sh - a wrapper script
* emmc-uEnv.txt - a modified `/boot/uEnv.txt` for an *eMMC* system

The above scripts are meant to be run on the *BBB*.

This final script is meant to be run on the workstation and is used to copy the above scripts and the image binaries to the SD card.

* copy_emmc_install.sh

The arguments to *copy_emmc_install* are the SD card device and the image you want to later install on the *eMMC*. It should be run after the *copy_rootfs.sh* script.

    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_emmc_install.sh sdb console

Once you boot this SD card, you'll find the following under `/home/root/emmc` 

    root@beaglebone:~/emmc# ls -l
    total 37756
    -rwxr-xr-x 1 root root    83152 Jul  1 06:24 MLO-beaglebone
    -rw-r--r-- 1 root root 38020844 Jul  1 06:24 console-image-beaglebone.tar.xz
    -rw-r--r-- 1 root root     1112 Jul  1 06:24 emmc-uEnv.txt
    -rwxr-xr-x 1 root root     1410 Jul  1 06:24 emmc_copy_boot.sh
    -rwxr-xr-x 1 root root     2498 Jul  1 06:24 emmc_copy_rootfs.sh
    -rwxr-xr-x 1 root root      675 Jul  1 06:24 emmc_install.sh
    -rwxr-xr-x 1 root root     1240 Jul  1 06:24 mk2parts.sh
    -rwxr-xr-x 1 root root   399360 Jul  1 06:24 u-boot-beaglebone.img
    -rw-r--r-- 1 root root    30149 Jul  1 06:24 zImage-am335x-boneblack.dtb
    -rw-r--r-- 1 root root    31722 Jul  1 06:24 zImage-bbb-4dcape70t.dtb
    -rw-r--r-- 1 root root    30678 Jul  1 06:24 zImage-bbb-hdmi.dtb
    -rw-r--r-- 1 root root    31927 Jul  1 06:24 zImage-bbb-nh5cape.dtb

To install the *console-image* onto the *eMMC*, run the `emmc_install.sh` script like this

    root@beaglebone:~/emmc# ./emmc_install.sh console

It should take less then a minute to run and the output should look something like this

    root@beaglebone:~/emmc# ./emmc_install.sh console
    
    Working on /dev/mmcblk1
    
    umount: /dev/mmcblk1p1: not mounted
    umount: /dev/mmcblk1p2: not mounted
    DISK SIZE – 3867148288 bytes
    CYLINDERS – 470
    
    Okay, here we go ...
    
    === Zeroing the MBR ===
    ...
    <partitioning, formatting and copying stuff>
    ...
    Extracting console-image-beaglebone.tar.xz to /media
    Copying am335x-boneblack.dtb to /media/boot/
    Copying bbb-hdmi.dtb to /media/boot/
    Copying bbb-4dcape70t.dtb to /media/boot/
    Copying bbb-nh5cape.dtb to /media/boot/
    Writing hostname to /etc/hostname
    Copying emmc-uEnv.txt to /media/boot/uEnv.txt
    Unmounting /dev/mmcblk1p2
    Done
    Success!
    Power off, remove SD card and power up

Follow the instructions and after reboot you will be running the *console-image* from the *eMMC*.

#### Some custom package examples

[spiloop][spiloop] is a spidev test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-bbb/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *P9.29* and *P9.30*.


[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-image*.

The *bitbake recipe* is here

    meta-bbb/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-fido/oe-init-build-env ~/bbb/build

    scott@octo:~/bbb/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [article][bbb-kernel] for some ways to go about customizing and rebuilding the BBB kernel or generating a new device tree.

#### Package management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].


[beagleboard]: http://www.beagleboard.org/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[tspress]: https://github.com/scottellis/tspress
[spiloop]: https://github.com/scottellis/spiloop
[bbb-kernel]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[bottle-python]: http://bottlepy.org/docs/dev/index.html
[lsblk]: http://linux.die.net/man/8/lsblk