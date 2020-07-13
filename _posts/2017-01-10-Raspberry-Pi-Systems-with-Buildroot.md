---
layout: post
title: Building Raspberry Pi Systems with Buildroot
description: "Building customized systems for the Raspberry Pi using Buildroot"
date: 2020-07-13 09:10:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, qt5, pyqt, pyqt5]
---

Warning: This is an old post and the repository referenced has not been updated in several years.

This post is about building Linux systems for [Raspberry Pi][rpi] boards using [Buildroot][buildroot].

Buildroot is a popular alternative to [Yocto][yocto] for building custom embedded Linux systems.

With a few exceptions you can build a similar Linux system with either tool.

I am using a [Buildroot clone][jumpnow-buildroot] I created in Github.

The `[master]` branch of the repository is a mirror of the official Buildroot repository.

The default `[jumpnow]` branch has a few additions on top of `[master]` for my own customizations and is what I am using for these examples.

I am using a **4.14** kernel from the [official RPi repo][rpi-linux].

The demo images I am building include [Qt5][qt] support, since many of the projects I work on use it. Qt is big and if you don't need it you should remove it from the config.

Buildroot offers two versions of Qt5, **5.9.4** and **5.6.x**. I'm using **5.9.4** for the demos. I am building both the Qt [EGLFS][qpa-eglfs] and linuxfb platform plugins.

I have also included PyQt5.

Here are some of the changes to Buildroot `[master]` in my `[jumpnow]` branch.

* Newer versions of the [Linux kernel][rpi-linux] and [RPi firmware][rpi-firmware]

* Some custom applications primarily as an experiment in how to add custom packages to Buildroot. The source for all of them are public github repos.

  1. **serialecho** - a C, Makefile based app
  2. **tspress** - a Qt5 Widgets GUI app using qmake
  3. **pytouch.py** - a [PyQt5][pyqt] app

* Custom Buildroot **defconfigs** to support my images for the RPi boards.

* Sample rootfs overlays to customize conf files.

* Some [patches to the kernel build][br-rpi-overlays] so that the RPi DTS overlays (DTBOs) are built from the kernel source and not just downloaded from the RPi firmware github repo. This make its a little easier (at least for my workflow) to include custom dts overlays when you need them by just including them as kernel patches.

The **defconfig** is where non-default build information is stored. You will want to create a custom **defconfig** for your project.

The two custom **defconfigs** I am using in the demos are

* jumpnow\_rpi3\_defconfig - for the RPi2, RPi3 and CM3 boards
* jumpnow\_rpi0\_defconfig - for the original RPi, RPi0, RPi0-W and CM1 boards

These configs add [Qt5][qt] (no QML), [PyQt5][pyqt] and Python3 including Numpy.

To build a system, run the following (see the **ccache** notes below)

    ~$ git clone -b jumpnow https://github.com/jumpnow/buildroot
    ~$ cd buildroot
    ~/buildroot$ make jumpnow_rpi3_defconfig
    ~/buildroot$ make

**Note:** Don't run make with a **-jN** argument. The main Makefile is not designed to be run as a parallel build. The sub-projects will be run in parallel automatically.

If you are missing tools on your workstation, you will get error messages telling you what you are missing. The dependencies are nothing out of the ordinary for a developer workstation and you can search the web for the particular packages you need to install for your distro.

The command

    make jumpnow_rpi3_defconfig

created a `.config` file that completely describes to Buildroot how to generate the system.

When the build is done, insert an SD card and copy the image like this

    ~/buildroot$ sudo dd if=output/images/rpi3-sdcard.img of=/dev/sdb bs=1M

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

    ~/buildroot$ make O=/br5/rpi3 jumpnow_rpi3_defconfig

After that, go to the directory you chose to run the Buildroot make commands

    ~/buildroot$ cd /br5/rpi3
    /br5/rpi3$ make menuconfig (optional)
    /br5/rpi3$ make

In this particular case I have `/br5/rpi3` on a drive partition separate from my workstation rootfs and my home directory.

So what does the resulting system look like?

I uploaded some [sdcard.imgs here][download] if you want a quick look.

Here's a short run through.

The [RPi serial console][rpi-serial] console is configured and I'm running the following commands using that.

    ...
    Welcome to Buildroot
    rpi3 login: root
    Password:

The password is **jumpnowtek**. You should change it.

    # uname -a
    Linux rpi3 4.14.26-v7 #1 SMP Wed Mar 14 17:00:40 EDT 2018 armv7l GNU/Linux

    # free
                  total        used        free      shared  buff/cache   available
    Mem:         949476       16888      878480         228       54108      919040
    Swap:             0           0           0


The SD card is not fully utilized because I used the `sdcard.img` and in the config set the rootfs size to 2G.

    # df -h
    Filesystem                Size      Used Available Use% Mounted on
    /dev/root                 1.8G    222.2M      1.5G  13% /
    devtmpfs                459.1M         0    459.1M   0% /dev
    tmpfs                   463.6M         0    463.6M   0% /dev/shm
    tmpfs                   463.6M    116.0K    463.5M   0% /tmp
    tmpfs                   463.6M    112.0K    463.5M   0% /run


The system is pretty big at **220M** but that's because of all the Qt5 and Python stuff I threw in.

    # ls -l /var/log
    lrwxrwxrwx    1 root     root             6 Aug 23 07:46 /var/log -> ../tmp

Logs are going to a tmpfs which is what you normally want on an embedded system.

The expected interfaces are present. The default `/etc/network/interfaces` brings up eth0 using dhcp.

I have verified the wifi interface works.

    # ifconfig -a
    eth0      Link encap:Ethernet  HWaddr B8:27:EB:7B:E8:32
              inet addr:192.168.10.111  Bcast:192.168.10.255  Mask:255.255.255.0
              inet6 addr: fe80::ba27:ebff:fe7b:e832/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:198 errors:0 dropped:0 overruns:0 frame:0
              TX packets:161 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:17701 (17.2 KiB)  TX bytes:21539 (21.0 KiB)

    lo        Link encap:Local Loopback
              inet addr:127.0.0.1  Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

    wlan0     Link encap:Ethernet  HWaddr B8:27:EB:2E:BD:67
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

The ssh server is listening. I have one connection going.

    # netstat -an | grep tcp
    tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
    tcp        0     64 192.168.10.111:22       192.168.10.4:50602      ESTABLISHED
    tcp        0      0 :::22                   :::*                    LISTEN

I also added an **ntp** package and set the timezone to **EST5EDT** in the defconfig and that is working.

    # date
    Thu Mar 15 06:49:21 EDT 2018


My Qt Widgets touchscreen test application [tspress][tspress] works fine.

    # tspress
    Unable to query physical screen size, defaulting to 100 dpi.
    To override, set QT_QPA_EGLFS_PHYSICAL_WIDTH and QT_QPA_EGLFS_PHYSICAL_HEIGHT (in millimeters).
    Down: 667 554
    Up  : 671 554
    Down: 893 671
    Up  : 893 671
    Down: 976 482
    Up  : 976 486
    #

See the `/etc/profile.d/qt5-env.sh` script for setting Qt5 environment variables like **WIDTH** and **HEIGHT**.

I have a USB Bluetooth mouse and a USB keyboard/mouse with trackpad attached as well as a 1080p HDMI touch display.

All input devices work.

You can see from the Qt messages that the *eglfs* plugin is being used.

I did include the *linuxfb* plugin in the build just for testing.

    # ls -l /usr/lib/qt/plugins/platforms/
    total 960
    -rwxr-xr-x    1 root     root          9568 Mar 14 17:02 libqeglfs.so
    -rwxr-xr-x    1 root     root        315012 Mar 14 17:02 libqlinuxfb.so
    -rwxr-xr-x    1 root     root        133540 Mar 14 17:02 libqminimal.so
    -rwxr-xr-x    1 root     root        162612 Mar 14 17:02 libqminimalegl.so
    -rwxr-xr-x    1 root     root        146000 Mar 14 17:02 libqoffscreen.so
    -rwxr-xr-x    1 root     root        207960 Mar 14 17:02 libqvnc.so


PyQt5 applications work fine. There is small example installed called `pytouch.py`.

You can run it like this

    # pytouch.py

#### Using the Buildroot cross-toolchain

Some quick notes on using the cross-toolchain.

The toolchain gets installed under the build output/host directory.

In my example where I used an external build directory of `/br5/rpi3`

    ~/buildroot$ make O=/br5/rpi3 jumpnow_rpi3_defconfig

my build output ended up here

    /br5/rpi3/host

The cross-compiler and associated tools can be found under

    /br5/rpi3/host/usr/bin

The toolchain is not **relocatable**. You must use it in place.

To use add the path `/br5/rpi3/host/usr/bin` to your **PATH** environment variable and invoke the compiler by name, in this case *arm-linux-gcc*, *arm-linux-g++*, etc...

Some quick examples, first add the PATH to the cross-compiler

    $ export PATH=/br5/rpi3/host/usr/bin:${PATH}
    $ echo $PATH
    /br5/rpi3/host/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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

A Qt5 project, first check our Qt version

    ~/projects$ which qmake
    /br5/rpi3/host/usr/bin/qmake

    ~/projects$ qmake --version
    QMake version 3.1
    Using Qt version 5.9.2 in /br5/rpi3/host/arm-buildroot-linux-gnueabihf/sysroot/usr/lib

Fetch and build a project

    ~/projects$ git clone https://github.com/scottellis/tspress
    Cloning into 'tspress'...

    ~/projects$ cd tspress

    ~/projects/tspress$ qmake
    Info: creating stash file /home/scott/projects/tspress/.qmake.stash

    ~/projects/tspress$ make
    ... (build stuff) ...

    ~/projects/tspress$ file tspress
    tspress: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 4.9.0, not stripped


[buildroot]: https://buildroot.org/
[raspbian]: https://www.raspbian.org/
[rpi]: https://www.raspberrypi.org/
[yocto]: https://www.yoctoproject.org/
[qt]: http://www.qt.io/
[qpa-eglfs]: http://doc.qt.io/qt-5/embedded-linux.html
[rpi-distro]: https://github.com/RPi-Distro/firmware-nonfree
[rpi-firmware]: https://github.com/raspberrypi/firmware
[rpi-linux]: https://github.com/raspberrypi/linux
[pyqt]: https://www.riverbankcomputing.com/software/pyqt/intro
[jumpnow-buildroot]: https://github.com/jumpnow/buildroot
[ccache]: https://ccache.samba.org/
[buildroot-docs]: http://nightly.buildroot.org/manual.html
[rpi-serial]: https://jumpnowtek.com/rpi/RPi-Serial-Console.html
[tspress]: https://github.com/scottellis/tspress
[download]: https://jumpnowtek.com/downloads/rpi/buildroot/
[br-rpi-overlay-doc]: https://jumpnowtek.com/rpi/Compiling-Raspberry-Pi-Overlays-with-Buildroot.html
[hardware-pwm]: https://jumpnowtek.com/rpi/Using-the-Raspberry-Pi-Hardware-PWM-timers.html
[br-rpi-overlays]: https://jumpnowtek.com/rpi/Compiling-Raspberry-Pi-Overlays-with-Buildroot.html
[AB-upgrades]: https://jumpnowtek.com/yocto/An-upgrade-strategy-for-embedded-Linux-systems.html
