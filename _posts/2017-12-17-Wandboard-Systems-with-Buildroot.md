---
layout: post
title: Building Wandboard Systems with Buildroot
description: "Building customized Linux systems for Wandboards using Buildroot"
date: 2017-12-27 07:35:00
categories: wandboard
tags: [linux, wandboard, buildroot]
---

This post is about building Linux systems for [i.MX6 Wandboards][wandboard] boards using [Buildroot][buildroot].

Buildroot is a popular alternative to [Yocto][yocto] for building custom embedded Linux systems.

With a few exceptions you can build a similar Linux system with either tool.

I am using a [Buildroot clone][jumpnow-buildroot] I created in Github to track my Buildroot customizations.

The `[master]` branch of the repository is a mirror of the official Buildroot repository.

The default `[jumpnow]` branch has a few additions on top of `[master]` for my own customizations and is what I am using for these examples.

The **defconfig** is where non-default build information is stored. There is a generic **wandboard\_defconfig** in the Buildroot repo.

You will want to create a custom **defconfig** for your project. The one I am using is called **jumpnow\_wandboard\_defconfig**.

To build a system, run the following (see the **ccache** notes below)

    ~$ git clone -b jumpnow https://github.com/jumpnow/buildroot
    ~$ cd buildroot
    ~/buildroot$ make jumpnow_wandboard_defconfig
    ~/buildroot$ make

**Note:** Don't run make with a **-jN** argument. The main Makefile is not designed to be run as a parallel build. The sub-projects will be run in parallel automatically.

If you are missing tools on your workstation, you will get error messages telling you what you are missing. The dependencies are nothing out of the ordinary for a developer workstation and you can search the web for the particular packages you need to install for your distro.

The command

    make jumpnow_wandboard_defconfig

created a `.config` file that completely describes to Buildroot how to generate the system.

When the build is done, insert an SD card and copy the image like this

    ~/buildroot$ sudo dd if=output/images/wand-sdcard.img of=/dev/sdb bs=1M

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

    ~/buildroot$ make O=/br5/wand jumpnow_wandboard_defconfig

After that, go to the directory you chose to run the Buildroot make commands

    ~/buildroot$ cd /br5/wand
    /br5/wand$ make menuconfig (optional)
    /br5/wand$ make

In this particular case I have `/br5/wand` on a drive partition separate from my workstation rootfs and my home directory.

#### System Overview

I am using wandboard quads for some network services on my LAN. They run headless so I have all display modules stripped from my kernels.

Attach a serial console and you will see this on boot

    Welcome to Buildroot
    wandboard login:

The only user is **root** with password **jumpnowtek**. This is set in the **defconfig**.

    # uname -a
    Linux wandboard 4.14.6-jumpnow #1 SMP Sun Dec 17 05:03:55 EST 2017 armv7l GNU/Linux

    # free
                  total        used        free      shared  buff/cache   available
    Mem:        2063808       16308     2028664          72       18836     1988884
    Swap:             0           0           0

The images are only **2GB** in size, again specified in the **defconfig**, but the system uses less then **100M**.

    # df -h
    Filesystem                Size      Used Available Use% Mounted on
    /dev/root                 1.8G     88.8M      1.6G   5% /
    devtmpfs                999.2M         0    999.2M   0% /dev
    tmpfs                  1007.7M         0   1007.7M   0% /dev/shm
    tmpfs                  1007.7M     28.0K   1007.7M   0% /tmp
    tmpfs                  1007.7M     44.0K   1007.7M   0% /run

Both ethernet and wifi work.

    # ifconfig -a
    eth0      Link encap:Ethernet  HWaddr 00:1F:7B:B4:03:79
              inet addr:192.168.10.114  Bcast:192.168.10.255  Mask:255.255.255.0
              inet6 addr: fe80::21f:7bff:feb4:379/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:95 errors:0 dropped:0 overruns:0 frame:0
              TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:6846 (6.6 KiB)  TX bytes:1550 (1.5 KiB)

    lo        Link encap:Local Loopback
              inet addr:127.0.0.1  Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

    wlan0     Link encap:Ethernet  HWaddr 40:2C:F4:AE:14:B0
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)


An ssh server is running, but not much else

    # netstat -an
    Active Internet connections (servers and established)
    Proto Recv-Q Send-Q Local Address           Foreign Address         State
    tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
    tcp        0      0 :::22                   :::*                    LISTEN
    Active UNIX domain sockets (servers and established)
    Proto RefCnt Flags       Type       State         I-Node Path
    unix  3      [ ]         DGRAM                     10507 /dev/log
    unix  2      [ ACC ]     SEQPACKET  LISTENING       1148 /run/udev/control
    unix  2      [ ]         DGRAM                     11948
    unix  3      [ ]         DGRAM                     11953
    unix  3      [ ]         DGRAM                     11952

And I have **Python3** installed

    # python3
    Python 3.6.3 (default, Dec 17 2017, 04:56:51)
    [GCC 6.4.0] on linux
    Type "help", "copyright", "credits" or "license" for more information.
    >>> quit()

for some things I am working on.

#### Using the Buildroot cross-toolchain

Some quick notes on using the cross-toolchain.

The toolchain gets installed under the build output/host directory.

In my example where I used an external build directory of `/br5/wand`

    ~/buildroot$ make O=/br5/wand jumpnow_wandboard_defconfig

my build output ended up here

    /br5/wand/host

The cross-compiler and associated tools can be found under

    /br5/wand/host/usr/bin

The toolchain is not **relocatable**. You must use it in place.

To use add the path `/br5/wand/host/usr/bin` to your **PATH** environment variable and invoke the compiler by name, in this case *arm-linux-gcc*, *arm-linux-g++*, etc...

Some quick examples, first add the PATH to the cross-compiler

    $ export PATH=/br5/wand/host/usr/bin:${PATH}
    $ echo $PATH
    /br5/wand/host/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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
    serialecho: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 4.14.0, not stripped


[buildroot]: https://buildroot.org/
[wandboard]: http://www.wandboard.org/
[yocto]: https://www.yoctoproject.org/
[jumpnow-buildroot]: https://github.com/jumpnow/buildroot
[ccache]: https://ccache.samba.org/
[buildroot-docs]: http://nightly.buildroot.org/manual.html
