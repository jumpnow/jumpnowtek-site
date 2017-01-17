---
layout: post
title: Building Raspberry Pi Systems with Buildroot
description: "Building customized systems for the Raspberry Pi using Buildroot"
date: 2017-01-17 08:52:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, qt5, pyqt, pyqt5]
---

Some initial experiments with [Buildroot][buildroot] as an alternative to [Yocto][yocto] for building Linux systems for [Raspberry Pi][rpi-site] boards.

In general I am not interested in building *desktop* like systems that support multiple GUI applications. The projects I work on typically have a single UI application running on a touchscreen display.

Or the projects have no user interface or maybe just a remote interface like a web service. For these projects I would like the ability to build very small systems.

Another important feature is [Qt5][qt] support since so many of the projects I work on use it. And since I require only one UI application at a time, the Qt [EGLFS][qpa-eglfs] platform plugin is what I want to use.

And finally, a build system not quite as heavy-weight as Yocto would be really nice, especially when assisting clients setting up their internal build systems.

Some nice to have features are

* Easy to add custom (proprietary) applications to the build
* Easy to choose versions for the kernel, bootloader/firmware, init system, udev provider, etc...
* Easy to patch the kernel or customize existing packages


So here are some notes on my first steps. 

I created a [Buildroot clone][jumpnow-buildroot] in Github.

The **[master]** branch of the repository is a mirror of the official Buildroot repository. 

The default **[rpi]** branch has a few additions on top of **[master]** for my own customizations.

The changes so far are

* Added an **rpi-wifi-firmware** package to include the non-free blobs the RPi3 radio requires. (Uses the [github.com/RPi-Distro/firmware-nonfree][rpi-distro] repo for the files.) 

* Bumped versions for the [Linux kernel][rpi-linux] and [RPi firmware][rpi-firmware] to the latest as of 2017-01-10 from the official RPi repositories.

* Added two custom applications, one C/Makefile app (**serialecho**) and one QtWidgets app using qmake (**tspress**), and included them in the build system configuration.
 
* Added a custom defconfig (`configs/jumpnow_rpi3_defconfig`) that incorporates the above and also adds Qt5 (no QML), [PyQt5][pyqt] and Python3 including Numpy.

* Modified the default openssh package **sshd_config** to allow root logins with no password (This is a dev only build setup).
 

To build the system, run the following (see the **ccache** notes below before running this)

    scott@t410:~$ git clone -b rpi https://github.com/jumpnow/buildroot br-rpi
    scott@t410:~$ cd br-rpi
    scott@t410:~/br-rpi$ make jumpnow_rpi3_defconfig
    scott@t410:~/br-rpi$ make

**Note:** Don't run make with a **-jN** argument. The main Makefile is not designed to be run as a parallel build. The sub-projects will be run in parallel automatically.

If you are missing tools on your workstation, you will get error messages telling you what you are missing. The dependencies are nothing out of the ordinary for a developer workstation and you can search the web for the particular packages you need to install for your Linux distribution. 

When the build is done, insert an SD card and copy the image like this

    scott@t410:~/br-rpi$ sudo dd if=output/images/sdcard.img of=/dev/sdb bs=1M

Replace `/dev/sdb` for where the SD card shows up on your workstation.

That *make jumpnow\_rpi3\_defconfig* command generated a *.config* file that describes to Buildroot how to generate your system similar to a Linux kernel configuration.
 
An easy Buildroot optimization is use [ccache][ccache] to reduce redundant work by the C/C++ preprocessor. Make sure your workstation has [ccache][ccache] installed, then run the Buildroot configuration tool after you have your initial *.config* generated.

    scott@t410:~/br-rpi$ make menuconfig 
    
Under **Build options** select **Enable compiler cache** and then save the configuration.
This will update your *.config*.

You will need the *ncurses development* package for your distribution before you can run `menuconfig`.

After that run *make* as usual to build your system. 

The [Buildroot Documentation][buildroot-docs] is pretty good and worth a read. It's not very long.

Here are a few more optimizations I've been using with my builds.

You can tell buildroot to save downloaded source files to a location outside the local buildroot repository.

The download location is determined by the **BR2\_DL\_DIR** environment variable which you can set globally in your shell environment or a line like this in your *.config*

    BR2_DL_DIR="/home/scott/br-download"

This allows you to share common downloads among different builds.

Another build option I've been using is to build externally, outside the buildroot repository.

You can specify it like this when you do the first `make defconfig`

    scott@fractal:~/br-rpi$ make O=/br5/rpi jumpnow_rpi3_defconfig
    scott@fractal:~/br-rpi$ cd /br5/rpi
    scott@fractal:/br5/rpi$ make menuconfig (optional)
    scott@fractal:/br5/rpi$ make

In this particular case I have `/br/rpi5` on a drive partition separate from my workstation rootfs and my home directory.

So what does the resulting system look like?

I uploaded an [sdcard.img here][download] if you want a quick look.

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
  

I don't have a PyQt5 application I can share right now, but I did test a closed source application I recently worked on that uses both PyQt5 and Python Numpy and it works as expected.

The one caveat is the system loader needs to be told about the RPi OpenGL libraries, so I had to run the PyQt5 app like this

    # LD_PRELOAD=libGLESv2.so ./zmon_cal_pyqt.py

I plan to look into the issue, but otherwise the PyQt5 application runs fine. I'm using **uclibc** currently and I think the first thing I'll check is whether the problem exists with a **glibc** system. 

The availability of [PyQt5][pyqt] alone might be sufficient to choose Buildroot over Yocto for a project.

So far I'm pretty happy with the systems that Buildroot is generating. 

The one feature I might miss is having a toolchain on the target device. But that's really only a development convenience and not one I use that often anyway. 

The fact that Buildroot builds so quickly compensates for that pretty well.  

I had to make some changes to the build system to get my custom RPi DTBO overlays building. I explain the problem and the approach I took to fixing it here [Compiling RPi Overlays with Buildroot][br-rpi-overlay-doc].

I'm not sure this is the right approach with Buildroot, but we'll see. 

Next up is some testing of the SDK toolchain that Buildroot generates.

More to follow...


[buildroot]: https://buildroot.org/
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
[download]: http://www.jumpnowtek.com/downloads/rpi/buildroot_rpi3/
[br-rpi-overlay-doc]: http://www.jumpnowtek.com/rpi/Compiling-Raspberry-Pi-Overlays-with-Buildroot.html