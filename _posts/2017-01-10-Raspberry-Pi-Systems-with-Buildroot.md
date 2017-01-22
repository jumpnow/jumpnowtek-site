---
layout: post
title: Building Raspberry Pi Systems with Buildroot
description: "Building customized systems for the Raspberry Pi using Buildroot"
date: 2017-01-22 14:04:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, qt5, pyqt, pyqt5]
---

I have started using [Buildroot][buildroot] as an alternative to [Yocto][yocto] for building Linux systems for the [Raspberry Pi][rpi-site] boards.

In general I am not interested in building *desktop* like systems that support multiple GUI applications.

In the projects I work on there is typically a single UI application running, maybe using a touchscreen. Or the projects have only a remote interface like a web service or no interface at all.

The preference for these systems is to be a small as possible, no software that isn't needed.

I do usually add [Qt5][qt] support since so many of the projects I work on use it. But since I require only one UI application at a time, the Qt [EGLFS][qpa-eglfs] platform plugin is what I want.

Buildroot is considerably simpler and light-weight in comparison to Yocto, which should be nice when it comes to assisting clients setting up their internal build systems.

So here are some notes on my what I'm using so far. 

I created a [Buildroot clone][jumpnow-buildroot] in Github.

The **[master]** branch of the repository is a mirror of the official Buildroot repository. 

The default **[rpi]** branch has a few additions on top of **[master]** for my own customizations.

The changes to **[master]** are

* Added an **rpi-wifi-firmware** package to include the non-free blobs the RPi3 radio requires. (Uses the [github.com/RPi-Distro/firmware-nonfree][rpi-distro] repo for the files.) 

* Bumped versions for the [Linux kernel][rpi-linux] and [RPi firmware][rpi-firmware] to the latest from the official RPi repositories.

* Added some custom applications primarily as an experiment in how to add custom packages to Buildroot. The source for all of them are github repos.

  1. **serialecho** - a C, Makefile based app
  2. **tspress** - a Qt5 Widgets GUI app using qmake
  3. **pytouch** - a [PyQt5][pyqt] app, the build/install for this is just a copy
 
* Added some custom Buildroot `configs` to support all the RPi boards. The configs add Qt5 (no QML), [PyQt5][pyqt] and Python3 including Numpy. This generates an image approaching 280MB, which is fairly big, but this is only for evaluation.

* Created some sample overlays for the rootfs to customize some conf files.

* Added some [kernel build patches][br-rpi-overlays] so that DTS overlays (DTBOs) are built from the kernel source and not just downloaded from the RPi firmware github repo.

* Added some custom DTS files for [hardware PWM][hardware-pwm].


The two custom `configs` are

* **jumpnow\_rpi3\_defconfig** - For the RPi2, RPi3 and CM3 boards
* **jumpnow\_rpi0\_defconfig** - For the original RPi, RPi Zero and CM1 boards
 

To build a system, run the following (see the **ccache** notes below)

    scott@t410:~$ git clone -b rpi https://github.com/jumpnow/buildroot
    scott@t410:~$ cd buildroot
    scott@t410:~/buildroot$ make jumpnow_rpi3_defconfig
    scott@t410:~/buildroot$ make

**Note:** Don't run make with a **-jN** argument. The main Makefile is not designed to be run as a parallel build. The sub-projects will be run in parallel automatically.

If you are missing tools on your workstation, you will get error messages telling you what you are missing. The dependencies are nothing out of the ordinary for a developer workstation and you can search the web for the particular packages you need to install for your Linux distribution. 

When the build is done, insert an SD card and copy the image like this

    scott@t410:~/buildroot$ sudo dd if=output/images/sdcard.img of=/dev/sdb bs=1M

Replace `/dev/sdb` for where the SD card shows up on your workstation.

The command
 
    make jumpnow_rpi3_defconfig 

created a `.config` file that completely describes to Buildroot how to generate the system.

#### Customizing the Build

The [Buildroot Documentation][buildroot-docs] is pretty good and worth a read.
 
One easy optimization is use [ccache][ccache] to reduce redundant work by the C/C++ preprocessor. 

Make sure your workstation has [ccache][ccache] installed, then run the Buildroot configuration tool after you have your initial *.config* generated.

    scott@t410:~/buildroot$ make menuconfig 
    
Under **Build options** select **Enable compiler cache** and then save the configuration.
This will update your *.config*.

You will need the *ncurses development* package for your distribution before you can run `menuconfig`.

After that run *make* as usual to build your system. 

Another option I've been using is to save the downloaded source files to a location outside the buildroot repository. 

The download location is determined by the **BR2\_DL\_DIR** environment variable which you can set globally in your shell environment or in a line like this in your *.config*

    BR2_DL_DIR="$(HOME)/br-download"

This allows you to share common downloads among different builds.

Another option is to build externally, outside the buildroot repository.

You can specify it like this when you do the first `make defconfig`

    scott@fractal:~/buildroot$ make O=/br5/rpi3 jumpnow_rpi3_defconfig
    scott@fractal:~/buildroot$ cd /br5/rpi3
    scott@fractal:/br5/rpi3$ make menuconfig (optional)
    scott@fractal:/br5/rpi3$ make

In this particular case I have `/br/rpi3` on a drive partition separate from my workstation rootfs and my home directory.

So what does the resulting system look like?

I uploaded some [sdcard.imgs here][download] if you want a quick look.

Here's a short run through.

The [RPi serial console][rpi-serial] console is configured and I'm running the following commands using that.

    Welcome to Buildroot
    buildroot login: root

    # uname -a
    Linux buildroot 4.4.43-v7 #1 SMP Tue Jan 17 07:26:59 EST 2017 armv7l GNU/Linux

    # free
                 total       used       free     shared    buffers     cached
    Mem:        911192      35448     875744        156       3332      10948
    -/+ buffers/cache:      21168     890024
    Swap:            0          0          0

The SD card is not fully utilized because we used the `sdcard.img` and didn't resize. That's easily fixed with some setup scripts I'll get to later.

    # df -h
    Filesystem                Size      Used Available Use% Mounted on
    /dev/root               203.1M    176.7M     12.2M  94% /
    devtmpfs                440.7M         0    440.7M   0% /dev
    tmpfs                   444.9M         0    444.9M   0% /dev/shm
    tmpfs                   444.9M     40.0K    444.9M   0% /tmp
    tmpfs                   444.9M    116.0K    444.8M   0% /run

The system is pretty big at **177M** but that's because of all the Qt5 and Python stuff I threw in.

    # ls -l /var/log
    lrwxrwxrwx    1 root     root             6 Jan  9 14:24 /var/log -> ../tmp

Logs are going to a tmpfs which is what you normally want on an embedded system.

The expected interfaces are present. The default `/etc/network/interfaces` brings up eth0 using dhcp.

I have verified the wifi interface works. 

    # ifconfig -a
    eth0      Link encap:Ethernet  HWaddr B8:27:EB:56:9B:DC
              inet addr:192.168.10.116  Bcast:192.168.10.255  Mask:255.255.255.0
              inet6 addr: fe80::ba27:ebff:fe56:9bdc/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:50 errors:0 dropped:0 overruns:0 frame:0
              TX packets:45 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
             RX bytes:4493 (4.3 KiB)  TX bytes:4946 (4.8 KiB)

    lo        Link encap:Local Loopback
              inet addr:127.0.0.1  Mask:255.0.0.0
              inet6 addr: ::1/128 Scope:Host
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

    wlan0     Link encap:Ethernet  HWaddr B8:27:EB:03:CE:89
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)


The ssh server is listening and I can use it.

    # netstat -an | grep tcp
    tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN
    tcp        0      0 :::22                   :::*                    LISTEN

I also added an **ntp** package and set the timezone to **EST5EDT** in the defconfig and that is working.

    # date
    Tue Jan 10 15:50:24 EST 2017

My little Qt Widgets touchscreen test application [tspress][tspress] works fine.

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

I have a USB Bluetooth mouse and a USB keyboard/mouse trackpad attached as well as an HDMI display.
They all work.

You can see from the Qt messages that the *eglfs* plugin is being used.

I did include the *linuxfb* plugin in the build just for testing.

    # ls -l /usr/lib/qt/plugins/platforms/
    total 656
    -rwxr-xr-x    1 root     root          7544 Jan 10 09:26 libqeglfs.so
    -rwxr-xr-x    1 root     root        283680 Jan 10 09:26 libqlinuxfb.so
    -rwxr-xr-x    1 root     root        119840 Jan 10 09:26 libqminimal.so
    -rwxr-xr-x    1 root     root        147044 Jan 10 09:26 libqminimalegl.so
    -rwxr-xr-x    1 root     root        106472 Jan 10 09:26 libqoffscreen.so
  

There is currently a linker issue with running PyQt5 applications. The work-around I've been using is to invoke the applications with an **LD_PRELOAD** statement like this

    # LD_PRELOAD=libGLESv2.so pytouch.py

This is still on the **TODO** to look into.

So far I'm pretty happy with the systems that Buildroot is generating.  

The one feature that might be missed is having a toolchain on the target device to do native compiles. This is really only a development convenience, production builds usually strip any tools like this.

Next up is some testing of the SDK toolchain that Buildroot generates.


[buildroot]: https://buildroot.org/
[raspbian]: https://www.raspbian.org/
[rpi-site]: https://www.raspberrypi.org/
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
[rpi-serial]: http://www.jumpnowtek.com/rpi/RPi-Serial-Console.html
[tspress]: https://github.com/scottellis/tspress
[download]: http://www.jumpnowtek.com/downloads/rpi/buildroot/
[br-rpi-overlay-doc]: http://www.jumpnowtek.com/rpi/Compiling-Raspberry-Pi-Overlays-with-Buildroot.html
[hardware-pwm]: http://www.jumpnowtek.com/rpi/Using-the-Raspberry-Pi-Hardware-PWM-timers.html
[br-rpi-overlays]: http://www.jumpnowtek.com/rpi/Compiling-Raspberry-Pi-Overlays-with-Buildroot.html