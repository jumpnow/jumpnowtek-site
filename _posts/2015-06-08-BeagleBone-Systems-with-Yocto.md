---
layout: post
title: Building BeagleBone Systems with Yocto
description: "Building customized systems for the BeagleBones using tools from the Yocto Project"
date: 2018-12-27 11:20:00
categories: beaglebone
tags: [linux, beaglebone, yocto]
---

Building systems for [BeagleBone Black][bbb] and [BeagleBone Green][bbg] boards using tools from the [Yocto Project][Yocto].

Yocto is a set of tools for building a custom embedded Linux distribution. The systems are usually targeted at particular applications like commercial products.

Yocto uses what it calls **meta-layers** to define the configuration for a system build. Within each meta-layer are recipes, classes and configuration files that support the primary build tool, a python framework called **bitbake**.

The Yocto system, while very powerful, does have a substantial learning curve. You may want to look at another popular tool for building embedded systems [Buildroot][buildroot-bbb].


The [meta-bbb][meta-bbb] layer generates some basic systems with packages that support C, C++, [Qt5][qt], Perl and Python development, the languages and tools I commonly use. Other languages are supported of course.

I use this layer as a template when starting new BeagleBone projects.

### System Info

The Yocto version is **2.6** the `[thud]` branch.

The default **4.20** Linux kernel comes from the [linux-stable][linux-stable] repository. Recipes for **4.19**, **4.14** and **4.9** LTS kernels are also available.

The [u-boot][uboot] version is `2018.07`.

These are **sysvinit** systems using [eudev][eudev].

The Qt version is **5.11.2**. There is no *X11* and no desktop installed. [Qt][qt] GUI applications can be run using the *linuxfb* platform plugin.

A light-weight **X11** desktop can be added with minimal changes to the build configuration. For instance **X11** is needed to run Java GUI apps or browser kiosk applications.

Python `3.5.6` is installed.

gcc/g++ 8.2.0 and associated build tools are installed.

git 2.18.1 is installed.

For the **4.9** and **4.14** kernels, device tree binaries are built that support

1. HDMI (`bbb-hdmi.dtb`) not for the [BBG][bbg]
2. No HDMI (`bbb-nohdmi.dtb`)
3. [4DCape 4.3-inch resistive touchscreen cape][4dcape43t] (`bbb-4dcape43t.dtb`)
4. [4DCape 7-inch resistive touchscreen cape][4dcape70t] (`bbb-4dcape70t.dtb`)
5. [Newhaven 5-inch capacitive touchscreen cape][nh5cape] (`bbb-nh5cape.dtb`, **4.9 only currently**)
6. [Newhaven 7-inch capacitive touchscreen cape][nhd7cape] (`bbb-nhd7cape.dtb`)

I have not added all display dtbs to the **4.19** kernels yet. No requests.

The DTBs are easy enough to switch between using a [u-boot][uboot] script file `uEnv.txt`

*spidev* on SPI bus 1, *I2C1* and *I2C2* and *UART4* are configured for use from the *P9* header.

There are some simple loopback test programs included in the console image.

[spiloop][spiloop] is a utility for testing the *spidev* driver.

[serialecho][serialecho] is a utility for testing *uarts*.

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

I have also used a **Fedora 27** 64-bit workstation.

The extra packages I needed were

    chrpath
    perl-bignum
    perl-Thread-Queue
    texinfo

and the package group

    Development Tools

Fedora already uses **bash** as the shell.

### Clone the repositories

    ~$ git clone -b thud git://git.yoctoproject.org/poky.git poky-thud

    ~$ cd poky-thud
    ~/poky-thud$ git clone -b thud git://git.openembedded.org/meta-openembedded
    ~/poky-thud$ git clone -b thud https://github.com/meta-qt5/meta-qt5.git

I usually keep these repositories separated since they can be shared between projects and different boards.

### Clone the meta-bbb repository

Create a sub-directory for the `meta-bbb` repository before cloning

    ~$ mkdir ~/bbb
    ~$ cd ~/bbb
    ~/bbb$ git clone -b thud git://github.com/jumpnow/meta-bbb

The `meta-bbb/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.

First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/bbb/` with the `meta-bbb` layer.

You could manually create the directory structure like this

    ~$ mkdir -p ~/bbb/build/conf


Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    ~$ source poky-thud/oe-init-build-env ~/bbb/build

The *Yocto* environment script will create the build directory if it does not already exist.

### Customize the configuration files

There are some sample configuration files in the `meta-bbb/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    ~/bbb$ cp meta-bbb/conf/local.conf.sample build/conf/local.conf
    ~/bbb$ cp meta-bbb/conf/bblayers.conf.sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

You may want to customize the configuration files before your first build.

### Edit bblayers.conf

In `bblayers.conf` file replace **${HOME}** with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-thud/
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

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/bbb/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/bbb/build/sstate-cache`.

#### ROOT PASSWORD

There is only one login user by default, **root**.

The default password is set to **jumpnowtek** by these two lines in the **local.conf** file

    INHERIT += "extrausers"
    EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

These two lines force a password change on first login

    INHERIT += "chageusers"
    CHAGE_USERS_PARAMS = "chage -d0 root; "

You can comment them out if you do not want that behavior.

If you want no password at all (development only hopefully), comment those four lines and uncomment this line

    EXTRA_IMAGE_FEATURES = "debug-tweaks"

    #INHERIT += "extrausers"
    #EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

    #INHERIT += "chageusers"
    #CHAGE_USERS_PARAMS = "chage -d0 root; "

You can always add or change the password once logged in.

### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The `oe-init-build-env` will not overwrite your customized conf files.

    ~$ source poky-thud/oe-init-build-env ~/bbb/build

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
* installer-image.bb

You should add your own custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-bbb/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    python3 with a number of modules

The *console-image* has a line

    inherit core-image

which is `poky-thud/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` runtime libraries.

#### installer-image

This is a minimal image meant only to run from an SD card and whose only purpose is to perform an eMMC installation.

### Build

To build the `console-image` run the following command

    ~/bbb/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    ~/bbb/build$ bitbake -c cleansstate zip
    ~/bbb/build$ bitbake zip

And then continue with the full build.

    ~/bbb/build$ bitbake console-image

To build the `qt5-image` it would be

    ~/bbb/build$ bitbake qt5-image

Or the `installer-image`

    ~/bbb/build$ bitbake installer-image

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

    ~$ cd ~/bbb/meta-bbb/scripts
    ~/bbb/meta-bbb/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    ~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the bootloaders (MLO and u-boot) to the boot partition of the SD card.

The script also copies a *uEnv.txt* file to the boot partition if it finds one in either

    <TMPDIR>/deploy/images/beaglebone/

or in the local directory where the script is run from.

If you are just starting out, you might just want to do this

    ~/bbb/meta-bbb/scripts$ cp uEnv.txt-example uEnv.txt

This *copy_boot.sh* script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe7/bbb/tmp-thud"

Then I would export this environment variable before running `copy_boot.sh`

    ~/bbb/meta-bbb/scripts$ export OETMP=/oe7/bbb/tmp-thud

Then run the `copy_boot.sh` script passing the location of SD card

    ~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the zImage Linux kernel, the device tree binaries and the rest of the operating system to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, for example **console** or **qt5**. The default is **console** if no argument is provided.

The script also accepts a **hostname** argument if you want the host name to be something other then the default **beaglebone**.

Here's an example of how you'd run **copy_rootfs.sh**

    ~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console

or

    ~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb qt5 bbb

The **copy_rootfs.sh** script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    ~$ sudo umount /dev/sdb1
    ~$ sudo umount /dev/sdb2
    ~$ export OETMP=/oe7/bbb/tmp-thud
    ~$ cd bbb/meta-bbb/scripts
    ~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    ~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb console bbb2


Both **copy_boot.sh** and **copy_rootfs.sh** are simple scripts meant to be modified for custom use.

### Booting from the SD card

The default behavior of the beaglebone is to boot from the ***eMMC*** first if it finds a bootloader there.

Holding the **S2** switch down when the bootloader starts will cause the BBB to try booting from the SD card first. The **S2** switch is above the SD card holder.

If you are using a cape, the **S2** switch is usually inaccessible or at least awkward to reach. From the back of the board a temporary jump of **P8.43** to ground when the bootloader starts will do the same thing as holding the **S2** switch.

If you prefer to always boot from the SD card you can erase any existing bootloader from the *eMMC* with something like the following

    root@beaglebone:~# dd if=/dev/zero of=/dev/mmcblk1 bs=4096 count=4096

On a system that booted from an SD card, `/dev/mmcblk0` is the SD card and `/dev/mmcblk1` is the *eMMC*.

### Installing to the eMMC

Normally you will want to use the **eMMC** over the SD card since the **eMMC** is a little faster.

You need a running system to install to the **eMMC**, since it is not accessible otherwise.

Suppose you wanted to install the **console-image** onto the **eMMC**.

First make sure you build both the **console-image** and the **installer-image** using bitbake.

First edit the **meta-bbb/scripts/emmc-uEnv.txt** file to be the **uEnv.txt** you want when using the **eMMC**. Normally you will only need to modify the **fdtfile** variable for the dtb you want.

Then when copying to the SD card, use these steps

    scott@octo:~$ export OETMP=<your-tmp-dir>
    scott@octo:~$ cd bbb/meta-bbb/scripts
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_boot.sh sdb
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_rootfs.sh sdb installer [<hostname>]
    scott@octo:~/bbb/meta-bbb/scripts$ ./copy_emmc_install.sh sdb console

When you boot from the SD card this time, it will automatically launch the eMMC installation of the console-image.

When the BBB LEDs stop flashing in **cylon-mode**, the eMMC installation is complete.

It should take a little over a minute from the time you apply power.

Power off, pull the SD card and reboot.

**NOTE** The default emmc installation will partition the eMMC for use with the emmc-upgrader scripts which support A/B rootfs upgradable systems. You can change this to partition the eMMC into two partitions by modifying this file before building the emmc-installer package.

    meta-bbb/recipe-support/emmc-installer/files/default

#### Modifying uEnv.txt

The **uEnv.txt** bootloader configuration script is where the kernel dtb is specified.

The **uEnv.txt** file is located on the first partition of the SD card or eMMC.

You can modify the **uEnv.txt** file at installation by adding a **uEnv.txt** file to the **meta-bbb/scripts** directory.

    ~/bbb/meta-bbb/scripts$ cp uEnv.txt-example uEnv.txt

And then edit the file. The **copy_boot.sh** script will pick it up and use it.

For the **uEnv.txt** file that installs onto the eMMC, edit this file directly

    scott@octo:~/bbb/meta-bbb/scripts/emmc-uEnv.txt

Be careful not to lose this line in the eMMC version of **uEnv.txt**

    bootpart=1:2

It differs from SD card **uEnv.txt** files which uses

    bootpart=0:2

You can also edit **uEnv.txt** on a running BBB system.

You first need to mount the bootloader partition

    root@bbb:~# mount /dev/mmcblk0p1 /mnt

    root@bbb:~# ls -l /mnt
    total 466
    -rwxr-xr-x 1 root root  64408 Aug 10  2015 MLO
    -rwxr-xr-x 1 root root 410860 Aug 10  2015 u-boot.img
    -rwxr-xr-x 1 root root    931 Aug 10  2015 uEnv.txt

You can edit `/etc/fstab` if you want the bootloader partition mounted all the time.

#### Some custom package examples

[spiloop][spiloop] is a *spidev* test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-bbb/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *P9.29* and *P9.30*.

[serialecho][serialecho] is a similar test app for serial ports.

The *bitbake recipe* that builds and packages *serialecho* is here

    meta-bbb/recipes-misc/serialecho/serialecho.bb

Use it to test *UART4* after placing a jumper between pins *P9.11* and *P9.13*.

[tspress][tspress] is a Qt5 GUI application installed with the **qt5-image**.

The bitbake recipe is here

    meta-bbb/recipes-qt/tspress/tspress.bb


#### Adding additional packages

To display the list of available packages from the **meta-** repositories included in **bblayers.conf**

    ~$ source poky-thud/oe-init-build-env ~/bbb/build
    ~/bbb/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the **console-image** or **qt5-image**.

2. Create a new image file and either include the **console-image** the way the **qt5-image** does or create a complete new image recipe.

The new package needs to get included directly in the **IMAGE_INSTALL** variable or indirectly through another variable in the image file.

#### Customizing the Kernel

See this [post][bbb-kernel] for some ways to go about customizing and rebuilding the BBB kernel or generating a new device tree binary.

#### Customizing U-Boot

See this [post][bbb-uboot] for similar notes on working with u-boot for the BBB.

#### Package Management

The package manager for these systems is *opkg*. The other choices are *rpm* or *apt*. You can change the package manager with the *PACKAGE_CLASSES* variable in `local.conf`.

*opkg* is the most lightweight of the Yocto package managers and the one that builds packages the quickest.

To add or upgrade packages to the system, you might be interested in using the build workstation as a [remote package repository][opkg-repo].

#### Full System Upgrades

For deployed production systems, you might prefer full system upgrades using an A/B rootfs strategy. This keeps upgrades *atomic* instead of spread out over multiple packages. It also allows for easy rollback when required.

An implementation of this idea is described here [An upgrade strategy for embedded Linux systems][ab-upgrades].

There is a **emmc-upgrader** package in the **meta-bbb** layer that will add this capability to your systems.

[bbb]: http://www.beagleboard.org/black
[bbg]: http://www.beagleboard.org/green
[buildroot-bbb]: https://jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Buildroot.html
[linux-stable]: https://www.kernel.org/
[uboot]: http://www.denx.de/wiki/U-Boot/WebHome
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[tspress]: https://github.com/scottellis/tspress
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[bbb-kernel]: https://jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: https://jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bbb-uboot]: https://jumpnowtek.com/beaglebone/Beaglebone-Black-U-Boot-Notes.html
[4dcape70t]: http://www.4dsystems.com.au/product/4DCAPE_70T/
[4dcape43t]: http://www.4dsystems.com.au/product/4DCAPE_43/
[nh5cape]: http://elinux.org/Nh5cape
[nhd7cape]: http://www.mouser.com/new/newhavendisplay/newhaven-beaglebone-cape/
[bitbake]: http://www.yoctoproject.org/docs/2.1/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-sh
[ab-upgrades]: https://jumpnowtek.com/linux/An-upgrade-strategy-for-embedded-Linux-systems.html
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev
