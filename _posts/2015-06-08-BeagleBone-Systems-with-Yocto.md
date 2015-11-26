---
layout: post
title: Building BeagleBone Black Systems with Yocto
description: "Building customized systems for the BeagleBone Black using tools from the Yocto Project"
date: 2015-11-26 06:30:00
categories: beaglebone
tags: [linux, beaglebone, yocto]
---

Building systems for [BeagleBone Black][beagleboard] boards using tools from the [Yocto Project][Yocto].

The [meta-bbb][meta-bbb] *layer* generates some basic systems with packages to support C, C++, [Qt5][qt], Perl and Python development.

I use this as a template when starting new *BeagleBone Black* projects.


### System Info

The Yocto version is `2.0` the `[jethro]` branch.

The `4.3` Linux kernel comes from the [linux-stable][linux-stable] repository. Switching to another kernel like the `4.1` *LTS* kernel is very easy.

The [u-boot][uboot] version is `2015.07`.

These are **sysvinit** systems.

The Qt version is `5.5.1`. There is no *X11* and no desktop installed. [Qt][qt] GUI applications can be run using the `-platform linuxfb` switch.

A light-weight *X11* desktop can be added with minimal changes to the build configuration. (*X11* is needed to run Java GUI apps.)

[ZeroMQ][zeromq] version `4.1.3` with development headers and libs is included.

Perl `5.22` and Python `2.7.9` each with a number of modules is included.

*Device tree* binaries are generated and installed that support

1. HDMI (`bbb-hdmi.dtb`)
2. [4DCape 7-inch resistive touchscreen cape][4dcape] (`bbb-4dcape70t.dtb`)
3. Newhaven 5-inch capacitive touchscreen cape (`bbb-nh5cape.dtb`) 

They are easy enough to switch between using a [u-boot][uboot] script file `uEnv.txt`

*spidev* on SPI bus 1, *I2C1* and *I2C2* and *UART4* are configured for use from the *P9* header.

There are some simple loopback test programs included in the console image.
 
[spiloop][spiloop] is a utility for testing the *spidev* driver.

[serialecho][serialecho] is a utility for testing *uarts*.
  
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

Then the `meta-openembedded` repository

    scott@octo:~$ cd poky-jethro
    scott@octo:~/poky-jethro$ git clone -b jethro git://git.openembedded.org/meta-openembedded

And the `meta-qt5` repository

    scott@octo:~/poky-jethro$ git clone -b jethro https://github.com/meta-qt5/meta-qt5.git


I usually keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-bbb repository

Create a sub-directory for the `meta-bbb` repository before cloning

    scott@octo:~$ mkdir ~/bbb
    scott@octo:~$ cd ~/bbb
    scott@octo:~/bbb$ git clone -b jethro git://github.com/jumpnow/meta-bbb

The `meta-bbb/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/bbb/` with the `meta-bbb` layer.

You could manually create the directory structure like this

    scott@octo:~$ mkdir -p ~/bbb/build/conf


Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/bbb/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-bbb/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@octo:~/bbb$ cp meta-bbb/conf/local.conf-sample build/conf/local.conf
    scott@octo:~/bbb$ cp meta-bbb/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-jethro/
         meta-openembedded/
         meta-qt5/
         ...

    ~/bbb/
        meta-bbb/
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

The default location is in the `build` directory, in this example `~/bbb/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/bbb/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/bbb/build/sstate-cache`.

### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The `oe-init-build-env` will not overwrite your customized conf files.

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/bbb/build

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


I don't use those *Common targets*, but instead use my own custom image recipes.

There are two custom images available in the *meta-bbb* layer. The recipes for the images can be found in `meta-bbb/images/`

* console-image.bb
* qt5-image.bb

You should add your own custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-bbb/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    perl and python with a number of modules

The *console-image* has a line

    inherit core-image

which is `poky-jethro/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

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

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/beaglebone/`.

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

    scott@octo:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloaders (MLO and u-boot) to the boot partition of the SD card.

The script also copies a *uEnv.txt* file to the boot partition if it finds one in either 

    <TMPDIR>/deploy/images/beaglebone/

or in the local directory where the script is run from.

If you are just starting out, you might just want to do this

    scott@octo:~/bbb/meta-bbb/scripts$ cp uEnv.txt-example uEnv.txt

This *copy_boot.sh* script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe9/bbb/tmp-jethro"

Then I would export this environment variable before running `copy_boot.sh`

    scott@octo:~/bbb/meta-bbb/scripts$ export OETMP=/oe9/bbb/tmp-jethro

Then run the `copy_boot.sh` script passing the location of SD card

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the *zImage* kernel, the device tree binaries and the rest of the operating system to the root file system partition of the SD card.
 
The script accepts an optional command line argument for the image type, for example `console` or `qt5`. The default is `console` if no argument is provided.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `beaglebone`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb qt5 bbb

The *copy_rootfs.sh* script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe9/bbb/tmp-jethro
    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console bbb2


Both *copy_boot.sh* and *copy_rootfs.sh* are simple scripts easily modified for custom use.

### Booting from the SD card

The default behavior of the *BBB* is to boot from the *eMMC* first if it finds a bootloader there.

Holding the **S2** switch down when the bootloader starts will cause the BBB to try booting from the SD card first. The **S2** switch is above the SD card holder.

If you are using a cape, the **S2** switch is usually inaccessible or at least awkward to reach. From the back of the board a temporary jump of **P8.43** to ground when the bootloader starts will do the same thing as holding the **S2** switch.

If you prefer to always boot from the SD card you can erase any existing bootloader from the *eMMC* with something like the following

    root@beaglebone:~# dd if=/dev/zero of=/dev/mmcblk1 bs=4096 count=4096

On a system that booted from an SD card, `/dev/mmcblk0` is the SD card and `/dev/mmcblk1` is the *eMMC*.

### Installing to the eMMC

Typically you'll want to use the *eMMC* over the SD card since the *eMMC* is faster.

You need a running system to install to the *eMMC*, since it is not accessible otherwise.

The Linux userland tools see the *eMMC* similar to an SD card, so the same scripts slightly modified and this time run from the *BBB* can be used install a system onto the *eMMC*.

There are some scripts under `meta-bbb/scripts` that are customized for an *eMMC* installation.

* emmc\_copy\_boot.sh - a modified copy\_boot.sh
* emmc\_copy\_rootfs.sh - a modified copy\_rootfs.sh
* emmc\_install.sh - a wrapper script
* emmc-uEnv.txt - a modified `uEnv.txt` for an *eMMC* system

The above scripts are meant to be run on the *BBB*.

This final script is meant to be run on the workstation and is used to copy the above scripts and the image binaries to the SD card.

* copy\_emmc\_install.sh

The arguments to *copy\_emmc\_install* are the SD card device and the image you want to later install on the *eMMC*. It should be run after the *copy\_rootfs.sh* script.

    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb qt5
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_emmc_install.sh sdb qt5

Once you boot this SD card, you'll find the following under `/home/root/emmc` 

    root@bbb:~/emmc# ls -l
    total 53096
    -rwxr-xr-x 1 root root    64408 Aug 10 05:37 MLO-beaglebone
    -rw-r--r-- 1 root root     1112 Aug 10 05:37 emmc-uEnv.txt
    -rwxr-xr-x 1 root root     1629 Aug 10 05:37 emmc_copy_boot.sh
    -rwxr-xr-x 1 root root     1825 Aug 10 05:37 emmc_copy_rootfs.sh
    -rwxr-xr-x 1 root root      675 Aug 10 05:37 emmc_install.sh
    -rwxr-xr-x 1 root root     1240 Aug 10 05:37 mk2parts.sh
    -rw-r--r-- 1 root root 53870180 Aug 10 05:37 qt5-image-beaglebone.tar.xz
    -rwxr-xr-x 1 root root   410860 Aug 10 05:37 u-boot-beaglebone.img


To install the *qt5-image* onto the *eMMC*, run the `emmc_install.sh` script like this

    root@beaglebone:~/emmc# ./emmc_install.sh qt5

It should take less then a minute to run.

When it completes, reboot you will be running the *qt5-image* from the *eMMC*.

#### Modifying uEnv.txt

The *uEnv.txt* bootloader configuration script is where the kernel *dtb* is specified. 

The file is located on the *boot* partition. Before you can edit the file, you need to mount the *boot* partition

    root@bbb:~# mount /dev/mmcblk0p1 /mnt

    root@bbb:~# ls -l /mnt
    total 466
    -rwxr-xr-x 1 root root  64408 Aug 10  2015 MLO
    -rwxr-xr-x 1 root root 410860 Aug 10  2015 u-boot.img
    -rwxr-xr-x 1 root root    931 Aug 10  2015 uEnv.txt

You can add an entry to `/etc/fstab` if you want the *boot* partition mounted all the time.

First create a better mount point

    root@bbb:~# mkdir /mnt/boot

Then an entry like this

    /dev/mmcblk0p1       /mnt/boot          auto       defaults  0  0

added to `/etc/fstab` would work.

#### Some custom package examples

[spiloop][spiloop] is a *spidev* test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-bbb/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *P9.29* and *P9.30*.

[serialecho][serialecho] is a similar test app for serial ports.

The *bitbake recipe* that builds and packages *serialecho* is here

    meta-bbb/recipes-misc/serialecho/serialecho.bb

Use it to test *UART4* after placing a jumper between pins *P9.11* and *P9.13*.

[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-image*.

The *bitbake recipe* is here

    meta-bbb/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-jethro/oe-init-build-env ~/bbb/build

    scott@octo:~/bbb/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a   complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [post][bbb-kernel] for some ways to go about customizing and rebuilding the BBB kernel or generating a new device tree binary.

#### Customizing U-Boot

See this [post][bbb-uboot] for similar notes on working with u-boot for the BBB.

#### Package Management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].

#### Full System Upgrades

For deployed production systems, you might prefer full system upgrades using an alternate *rootfs* method. This keeps upgrades *atomic* instead of spread out over multiple packages. It also allows for easy rollback when required.

An implementation of this idea is described here [An Upgrade strategy for the BBB][bbb-upgrades] including a link to some sample code on github.

[beagleboard]: http://www.beagleboard.org/
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[tspress]: https://github.com/scottellis/tspress
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[bbb-kernel]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bbb-uboot]: http://www.jumpnowtek.com/beaglebone/Beaglebone-Black-U-Boot-Notes.html
[4dcape]: http://www.4dsystems.com.au/product/4DCAPE_70T/
[bitbake]: https://www.yoctoproject.org/docs/1.8/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-sh
[zeromq]: http://zeromq.org/
[bbb-upgrades]: http://www.jumpnowtek.com/beaglebone/Upgrade-strategy-for-BBB.html