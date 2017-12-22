---
layout: post
title: Building Beaglebone Systems with Buildroot
description: "Building customized systems for the BeagleBone Black using Buildroot"
date: 2017-12-22 09:17:00
categories: beaglebone
tags: [linux, beaglebone, bbb, buildroot, qt5, pyqt, pyqt5, pru]
---

This post is about building Linux systems for [beaglebone][bbb] boards using [Buildroot][buildroot].

Buildroot is a popular alternative to [Yocto][yocto] for building custom embedded Linux systems. 

With a few exceptions you can build a similar Linux system with either tool. 

I am using a [Buildroot clone][jumpnow-buildroot] I created in Github to track my Buildroot customizations.

The `[master]` branch of the repository is a mirror of the official Buildroot repository. 

The default `[jumpnow]` branch has a few additions on top of `[master]` for my own customizations and is what I am using for these examples.

The **defconfig** is where non-default build information is stored.

You will want to create a custom **defconfig** for your project. The one I am using is called **jumpnow\_bbb\_defconfig**.

To build a system, run the following (see the **ccache** notes below)

    ~$ git clone -b jumpnow https://github.com/jumpnow/buildroot
    ~$ cd buildroot
    ~/buildroot$ make jumpnow_bbb_defconfig
    ~/buildroot$ make

**Note:** Don't run make with a **-jN** argument. The main Makefile is not designed to be run as a parallel build. The sub-projects will be run in parallel automatically.

If you are missing tools on your workstation, you will get error messages telling you what you are missing. The dependencies are nothing out of the ordinary for a developer workstation and you can search the web for the particular packages you need to install for your distro. 

The command
 
    make jumpnow_bbb_defconfig 

created a `.config` file that completely describes to Buildroot how to generate the system.

When the build is done, insert an SD card and copy the image like this

    ~/buildroot$ sudo dd if=output/images/bbb-sdcard.img of=/dev/sdb bs=1M

Replace `/dev/sdb` with the location the SD card shows up on your workstation.


#### Customizing the Build

The [Buildroot Documentation][buildroot-docs] is good and you should probably be reading that first.
 
One easy optimization is use [ccache][ccache] to reduce redundant work by the C/C++ preprocessor. 

Make sure your workstation has [ccache][ccache] installed, then run the Buildroot configuration tool after you have your initial *.config* generated.

    ~/buildroot$ make menuconfig 
    
Under **Build options** select **Enable compiler cache** and then save the configuration.
This will update your *.config*.

You will need the *ncurses development* package for your distribution before you can run `menuconfig`.

After that run *make* as usual to build your system. 

Another option I've been using is to save the downloaded source files to a location outside the buildroot repository. 

The download location is determined by the **BR2\_DL\_DIR** variable in the **config**

    BR2_DL_DIR="$(HOME)/dl"

Or it can be set as an environment variable in the shell

    export BR2_DL_DIR=${HOME}/dl

This allows you to share common downloads among different builds and if you ever delete the Buildroot repository you won't lose the downloads.

Another option is to build externally outside of the Buildroot repository.

You can specify it this way when you do the first `make <some_defconfig>`.

    ~/buildroot$ make O=/br5/bbb jumpnow_bbb_defconfig

After that, go to the directory you chose to run the Buildroot make commands

    ~/buildroot$ cd /br5/bbb
    /br5/rpi3$ make menuconfig (optional)
    /br5/rpi3$ make

In this particular case I have `/br5/bbb` on a drive partition separate from my workstation rootfs and my home directory.

#### System Overview

The whole point of using build systems like Buildroot or Yocto is to customize the system to your own needs.

Here is a quick look at the system built by the **jumpnow_bbb_defconfig**.

Assuming a serial console, you will get this on boot. 

    ...
    Welcome to Buildroot
    bbb login:

Login with user **root** and password **jumpnowtek**. That password is something you can set in the defconfig.

    # uname -a
    Linux bbb 4.9.71-jumpnow #1 Fri Dec 22 08:39:07 EST 2017 armv7l GNU/Linux

    # free
                  total        used        free      shared  buff/cache   available
    Mem:         501920        8388      478356         160       15176      483240
    Swap:             0           0           0

    # df -h
    Filesystem                Size      Used Available Use% Mounted on
    /dev/root                 1.8G    137.6M      1.6G   8% /
    devtmpfs                236.6M         0    236.6M   0% /dev
    tmpfs                   245.1M         0    245.1M   0% /dev/shm
    tmpfs                   245.1M     60.0K    245.0M   0% /tmp
    tmpfs                   245.1M    100.0K    245.0M   0% /run
    /dev/mmcblk0p1           31.9M    362.0K     31.6M   1% /mnt

The SD card is bigger then this, but only 2GB was configured in the partitioning in the **defconfig**. You can obviously customize this to whatever you want or not even use the **bbb-sdcard.img** to install the system. I usually don't.

    # ifconfig -a
    eth0      Link encap:Ethernet  HWaddr 84:EB:18:E2:31:2F
              inet addr:192.168.10.115  Bcast:192.168.10.255  Mask:255.255.255.0
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:135 errors:0 dropped:0 overruns:0 frame:0
              TX packets:2 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:8851 (8.6 KiB)  TX bytes:684 (684.0 B)
              Interrupt:173

    lo        Link encap:Local Loopback
              inet addr:127.0.0.1  Mask:255.0.0.0
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

I booted a Beaglebone Green board for this example. There are dtbs installed for a number of different use cases. Some are standard, some are custom.

    # ls /boot
    am335x-boneblack.dtb           bbb-hdmi.dtb
    am335x-bonegreen-wireless.dtb  bbb-nh5cape.dtb
    am335x-bonegreen.dtb           bbb-nhd7cape.dtb
    bbb-4dcape43t.dtb              bbb-nohdmi.dtb
    bbb-4dcape50t.dtb              zImage
    bbb-4dcape70t.dtb

If you want to change the dtb that is used, edit **uEnv.txt** on the first partition. The partition is mounted automatically at **/mnt**.

    # mount
    /dev/root on / type ext4 (rw,relatime,data=ordered)
    devtmpfs on /dev type devtmpfs (rw,relatime,size=242256k,nr_inodes=60564,mode=755)
    proc on /proc type proc (rw,relatime)
    devpts on /dev/pts type devpts (rw,relatime,gid=5,mode=620,ptmxmode=000)
    tmpfs on /dev/shm type tmpfs (rw,relatime,mode=777)
    tmpfs on /tmp type tmpfs (rw,relatime)
    tmpfs on /run type tmpfs (rw,nosuid,nodev,relatime,mode=755)
    sysfs on /sys type sysfs (rw,relatime)
    /dev/mmcblk0p1 on /mnt type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=iso8859-1,shortname=mixed,errors=remount-ro)

    # ls -l /mnt
    total 362
    -rwxr-xr-x    1 root     root         62632 Dec 22  2017 MLO
    -rwxr-xr-x    1 root     root        303392 Dec 22  2017 u-boot.img
    -rwxr-xr-x    1 root     root           566 Dec 22  2017 uEnv.txt

If you run a dtb and board that has a display you can try a couple of custom Qt apps that are installed.

This is a Qt widgets app

    # ls /usr/bin/tspress
    /usr/bin/tspress

This is a PyQt5 app

    # ls /usr/bin/pytouch.py
    /usr/bin/pytouch.py

Both use the **linuxfb** Qt backend setup in the environment.

    # env
    USER=root
    SHLVL=1
    HOME=/root
    PAGER=/bin/more
    PS1=#
    LOGNAME=root
    TERM=vt100
    PATH=/bin:/sbin:/usr/bin:/usr/sbin
    SHELL=/bin/sh
    QT_QPA_PLATFORM=linuxfb
    PWD=/root
    EDITOR=/bin/vi


#### Using the Buildroot cross-toolchain

Some quick notes on using the cross-toolchain.

The toolchain gets installed under the build output/host directory.

In my example where I used an external build directory of `/br5/bbb`

    ~/buildroot$ make O=/br5/bbb jumpnow_bbb_defconfig

my build output ended up here

    /br5/bbb/host

The cross-compiler and associated tools can be found under

    /br5/bbb/host/usr/bin

The toolchain is not **relocatable**. You must use it in place.

To use add the path `/br5/bbb/host/usr/bin` to your **PATH** environment variable and invoke the compiler by name, in this case *arm-linux-gcc*, *arm-linux-g++*, etc...

Some quick examples, first add the PATH to the cross-compiler

    $ export PATH=/br5/bbb/host/usr/bin:${PATH}
    $ echo $PATH
    /br5/bbb/host/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

A simple C, Makefile example

    ~/projects$ git clone https://github.com/scottellis/serialecho
    Cloning into 'serialecho'...

    ~/projects$ cd serialecho/

    ~/projects/serialecho$ cat Makefile
    TARGET = serialecho

    $(TARGET) : serialecho.c
            $(CC) serialecho.c -o $(TARGET)

    clean:
            rm -f $(TARGET)

    ~/projects/serialecho$ export CC=arm-linux-gcc

    ~/projects/serialecho$ make
    arm-linux-gcc serialecho.c -o serialecho

    ~/projects/serialecho$ file serialecho
    serialecho: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 4.9.0, not stripped


[buildroot]: https://buildroot.org/
[bbb]: https://beagleboard.org/
[yocto]: https://www.yoctoproject.org/
