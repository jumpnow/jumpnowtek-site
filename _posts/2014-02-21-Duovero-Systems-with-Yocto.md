---
layout: post
title: Building Duovero Systems with Yocto
description: "Building customized systems for Gumstix Duovero using tools from the Yocto Project"
date: 2014-02-21 12:58:00
categories: gumstix duovero
tags: [linux, gumstix, duovero, yocto]
---

The results from these instructions are generic developer systems targeting C/C++ and Qt programmers. You will likely want to modify them for any particular project. 

There is no X11 and no desktop installed on any of these systems. The embedded Qt images can be used to run GUI applications using the -qws switch. 

The Linux 3.6 kernel comes from the Linux mainline with some patches from Gumstix and a few of my own.

The Yocto version is 1.5.1 (Poky 10.0.1), the [dora] branch.

The images are **sysvinit** based not **systemd**. I am using the **systemd-udev v206** package instead of the stand-alone **udev v182** package because I've found it to be more reliable when it comes to loading binary firmware for the Duovero wifi/bluetooth radio.

### Ubuntu Packages

I've settled on Ubuntu workstations as my build platforms for now. Currently I'm using a 13.04 and 13.10 64-bit systems.

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

You'll also want to change the default Ubuntu shell from **dash** to **bash** by running this command
 
    dpkg-reconfigure dash

### Clone the dependency repositories

First the main Yocto project **poky** repository

    scott@hex:~ git clone git://git.yoctoproject.org/poky.git poky-dora
    scott@hex:~$ cd ~/poky-dora
    scott@hex:~/poky-dora$ git checkout -b dora origin/dora

Next the **meta-openembedded** repository

    scott@hex:~/poky-dora$ git clone git://git.openembedded.org/meta-openembedded
    scott@hex:~/poky-dora$ cd meta-openembedded
    scott@hex:~/poky-dora/meta-openembedded$ git checkout -b dora origin/dora
    scott@hex:~/poky-dora/meta-openembedded$ cd ..

The **meta-gumstix** repository

    scott@hex:~/poky-dora$ git clone git://github.com/gumstix/meta-gumstix
    scott@hex:~/poky-dora$ cd meta-gumstix
    scott@hex:~/poky-dora/meta-gumstix$ git checkout -b dora origin/dora
    scott@hex:~/poky-dora/meta-gumstix$ cd ..

Finally the **meta-duovero** repository

    scott@hex:~/poky-dora$ cd ..
    scott@hex:~$ mkdir duovero
    scott@hex:~$ cd duovero
    scott@hex:~/duovero$ git clone git://github.com/scottellis/meta-duovero


I put the **meta-duovero** repository in a different sub-directory because while the first 3 repositories can be shared, the **meta-duovero** repository may or may not be Duovero specific. I am not testing it with anything other then Duoveros.

The **meta-duovero/README.md** file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. They don't have to be followed explicitly. All the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis just to keep straight the different projects I'm working on and so I can quickly switch between projects. For this example I'll put the build directory under **~/duovero/** with the **meta-duovero** layer.

    scott@hex:~$ cd ~/poky-dora
    scott@hex:~/poky-dora$ source oe-init-build-env ~/duovero/build
    scott@hex:~/duovero/build$ ls
    conf

### Customize the conf files

The oe-init-build-env script generated some generic scripts in the **build/conf** directory.
We want to replace those with the templates in the **meta-duovero/conf** directory.

	scott@hex:~/duovero/build$ cp ~/duovero/meta-duovero/conf/local.conf.sample \
      conf/local.conf
    scott@hex:~/duovero/build$ cp ~/duovero/meta-duovero/conf/bblayers.conf.sample \
      conf/bblayers.conf


### Edit bblayers.conf

In **bblayers.conf** file replace **${HOME}** with the appropriate path to the meta-layer repositories on your system if you modified any of the above instructions when cloning. 

### Edit local.conf

The variables you may want to customize are the following:

    BB_NUMBER_THREADS
    PARALLEL_MAKE
    TMPDIR
    DL_DIR
    SSTATE_DIR
    SDKMACHINE


##### BB\_NUMBER\_THREADS

Set to the number of cores on your build machine.

##### PARALLEL\_MAKE

Set to the number of cores on your build machine.

##### TMPDIR

This is where temporary build files and the final build executables will end up. Expect at least 35GB to be required. You probably want at least 50GB available.

The default location if left commented will be **~/duovero/build/tmp**. I usually put my TMPDIRs on dedicated partitions and often on another disk from the workstation O/S.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build. Also because of some rpath issues with gcc, the TMPDIR path cannot be too short or the gcc build will fail. I haven't determined exactly how short is too short, but something like **/oe26** is too short and **/oe26/tmp-poky-dora-build** is long enough.

If you use the default location, the TMPDIR path is long enough.
     
##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and build files so I created a general location for this outside my home directory. Make sure the build user has write permission to the directory you decide on.

The default directory will be **~/duovero/build/sources**.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 5GB. I often put this somewhere else other then my home directory as well.

The default location is **~/duovero/build/sstate-cache**.
 
##### SDK_MACHINE

Specify your workstations type, i686 for 32-bit or x86_64 for 64-bit systems.

 
### Run the build

You need to source the environment every time you want to run a build. The **oe-init-build-env** when run a second time will not overwrite your customized conf files.

    scott@hex:~$ cd ~/poky-dora
    scott@hex:~$ source oe-init-build-env ~/duovero/build

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


Those 'Common targets' may or may not build successfully. I have never tried them.

 

There are a few custom images available in the meta-duovero layer. The recipes for these image can be found in **meta-duovero/recipes-duovero/images/**

    duovero-console-image.bb
    duovero-qte-image.bb


#### duovero-console-image

A basic console developer image. See the recipe for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    wireless support
    kernel modules
    avahi daemon
    ntp daemon

#### duovero-qte-image

This image includes the **duovero-console-image** and adds Qt 4.8.5 embedded with the associated development headers and qmake.

This image also includes the **SyntroCore** and **SyntroLCam** binaries as well as the headers and libraries for doing Syntro development on the board.

To build the **duovero-console-image** run the following command

    scott@hex:~/duovero/build$ bitbake duovero-console-image

You may run into build errors related to packages that failed to download or sometimes out of order builds. The easy solution is to clean the build for the failed package and rerun the build again.

For instance if the build for **zip** failed for some reason, I would run this.

    scott@hex:~/duovero/build$ bitbake -c cleansstate zip
    scott@hex:~/duovero/build$ bitbake zip

And then continue with the full build.

    scott@hex:~/duovero/build$ bitbake duovero-console-image

 
### Copying the binaries to an SD card

After the build completes, the bootloader, kernel and rootfs image files can be found in **TMPDIR/deploy/images/duovero/**.

The **meta-duovero/scripts** directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the boards.

Insert the microSD into your workstation and note where it shows up. You may have to look at your syslog. I'll assume **/dev/sdc** for this example.

It doesn't matter if some partitions from the SD card are mounted. The **mk2parts.sh** script will unmount them.

BE CAREFUL with this script. It will format any disk on your workstation.

    scott@hex:~$ cd ~/duovero/meta-duovero/scripts
    scott@hex:~/duovero/meta-duovero/scripts$ sudo ./mk2parts.sh sdc

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use. You only have to do this once.

    scott@hex:~$ sudo mkdir /media/card


#### copy_boot.sh

This script copies the bootloader (MLO, u-boot) and Linux kernel (uImage) to the boot partition of the SD card.

This script needs to know the **TMPDIR** to find the binaries. It looks for an environment variable called **OETMP**.

For instance, if I had this in the local.conf

    TMPDIR = "/oe26/tmp-poky-dora-build"

Then I would export this environment variable before running copy_boot.sh

    scott@hex:~/duovero/meta-duovero/scripts$ export OETMP=/oe26/tmp-poky-dora-build

Then run the copy_boot.sh script passing the location of SD card

    scott@hex:~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdc

#### copy_rootfs.sh

This script copies files to the root file system partition of the SD card.

The script accepts an optional command line argument for the image type, either **console** or **qte**. The default is **console**.

The script also accepts a **hostname** argument if you want the host name to be something other then the default **duovero**.

The hostname affects the name that the device will use with avahi and the SyntroLCam stream name explained below.

Here's an example of how you'd run copy_rootfs.sh
    scott@hex:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdc console

Or
    scott@hex:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdc qte duo1

The copy scripts will **NOT** unmount partitions automatically. If the partition that is supposed to be the on the SD card is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@hex:~$ sudo umount /dev/sdc1
    scott@hex:~$ sudo umount /dev/sdc2
    scott@hex:~$ export OETMP=/oe26/tmp-poky-dora-build
    scott@hex:~$ cd duovero/meta-duovero/scripts
    scott@hex:~/duovero/meta-duovero/scripts$ ./copy_boot.sh sdc
    scott@hex:~/duovero/meta-duovero/scripts$ ./copy_rootfs.sh sdc console duo2

