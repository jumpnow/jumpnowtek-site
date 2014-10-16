---
layout: post
title: FreeBSD ARM notes
description: "Running FreeBSD on ARM boards"
date: 2014-09-30 10:30:00
categories: freebsd
tags: [freebsd, arm]
---

Some notes on running [FreeBSD][freebsd] on ARM boards. Just getting started so any problems are probably my fault.

*FreeBSD* already runs on a number of [arm boards][freebsd-arm].

In particular, a lot of the boards I have laying around are already supported

* [wandboard][wandboard]
* [beaglebone black][beagleboard] and white
* [raspberry-pi][rpi]
* [pandaboard][pandaboard]
* beagleboard

Gumstix [Duovero][duovero] and [Overo][overo] support would be really great. Maybe a future project.


## Initial Goal

Primary

* Ethernet
* Wifi
* USB host
* Qt4 or Qt5
* Syntro webcam application

Secondary 

* gpio
* i2c
* spi
* bluetooth

Not important

* displays
* audio


## Quick start

The [FreeBSD][freebsd] site has some pre-built [binaries][freebsd-download] for a number of small ARM boards. I'm going with the development *11.0* binaries.

Working from a Ubuntu Linux machine and choosing a quad-core wandboard as the first test board...

Download a *wandboard* image

	~/freebsd$ wget ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Unzip it

    ~/freebsd$ bunzip2 FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Copy it to a microSD card (assuming the SD card shows up at */dev/sdb*)

    ~/freebsd$ sudo dd if=FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img of=/dev/sdb bs=4M

Insert into a *wandboard-quad* with serial console access (1152008N1) 

Here is the [boot log][freebsd-boot-log].

The root user has no password.

Ethernet should try to get a *dhcp* address.

A nice feature is that the filesystem got expanded during the first boot.

    root@wandboard:~ # df -h
    Filesystem        Size    Used   Avail Capacity  Mounted on
    /dev/mmcsd0s2a     14G    403M     13G     3%    /
    devfs             1.0K    1.0K      0B   100%    /dev
    /dev/mmcsd0s1      50M    260K     50M     1%    /boot/msdos
    tmpfs              30M    4.0K     30M     0%    /tmp
    tmpfs              15M     52K     15M     0%    /var/log
    tmpfs             5.0M    4.0K    5.0M     0%    /var/tmp



Also nice is that hardly anything is running by default.

    root@wandboard:~ # ps -ax
    PID TT  STAT      TIME COMMAND
      0  -  DLs    0:00.01 [kernel]
      1  -  ILs    0:00.04 /sbin/init --
      2  -  DL     0:00.00 [cam]
      3  -  DL     0:00.00 [sctp_iterator]
      4  -  DL     0:00.04 [mmcsd0: mmc/sd card]
      5  -  DL     0:00.05 [pagedaemon]
      6  -  DL     0:00.00 [vmdaemon]
      7  -  DL     0:00.00 [pagezero]
      8  -  DL     0:00.04 [bufdaemon]
      9  -  DL     0:00.01 [vnlru]
     10  -  RL   128:27.66 [idle]
     11  -  WL     0:01.53 [intr]
     12  -  DL     0:00.10 [geom]
     13  -  DL     0:00.18 [rand_harvestq]
     14  -  DL     0:00.04 [usb]
     15  -  DL     0:00.04 [syncer]
    259  -  Is     0:00.02 /sbin/devd
    278  -  Is     0:00.01 dhclient: ffec0 [priv] (dhclient)
    396  -  Is     0:00.01 dhclient: ffec0 (dhclient)
    499  -  Is     0:00.02 casperd: zygote (casperd)
    500  -  Is     0:00.03 /sbin/casperd
    704  -  Is     0:00.02 /usr/sbin/sshd
    705  -  Ss     0:00.24 sshd: root@pts/0 (sshd)
    643 u0  Is     0:00.05 login [pam] (login)
    644 u0  I+     0:00.13 -csh (csh)
    709  0  Ss     0:00.10 -csh (csh)
    729  0  R+     0:00.01 ps -ax


### SSH Login

One thing that is running is an *sshd* server.

Root logins over *ssh* are not allowed by default. 

To change this

1. Add a password to root
2. Edit `/etc/ssh/sshd_config` to *PermitRootLogin yes*
3. Then restart sshd.

    root@wandboard:~ # service sshd restart

And you should be able to ssh in.


### Date/time

Set the timezone

    root@wandboard:~ # cp /usr/share/zoneinfo/EST5EDT /etc/localtime

The *ntpdate* daemon will set time on startup. Enable it in `/etc/rc.conf`

    ntpdate_enable="YES"

Kick it to update once

    root@wandboard:~ # service ntpdate start 

TODO: Use *ntp* instead for continuous time updates


## Packages

I don't think there is an official prebuilt package repository for the development *FreeBSD 11* branch, so I'm building some ports myself. [Qt][qt-site] and whatever *FreeBSD* uses for access to webcams. I think it's [Webcamd][webcamd], but I'm not sure. The goal is to port a version of [SyntroLCam][syntrolcam] to *FreeBSD*. 


To get started
 
Fetch the ports tree

    root@wandboard:~ # portsnap fetch

First time usage

	root@wandboard:~ # portsnap extract

The systems comes with a *C* compiler and associated development tools

    root@wandboard:/usr/ports/ports-mgmt/pkg # which cc
    /usr/bin/cc
    
    root@wandboard:/usr/ports/ports-mgmt/pkg # cc --version
    FreeBSD clang version 3.4.1 (tags/RELEASE_34/dot1-final 208032) 20140512
    Target: armv6--freebsd11.0-gnueabi
    Thread model: posix

Generate a ports index (optional, takes awhile)

    root@wandboard:/usr/ports # make index

Since I never plan to connect a display, I'm setting some default flags in `/etc/make.conf` so they apply to all ports

	OPTIONS_UNSET= X11 GUI CUPS DOCS EXAMPLES NLS

    OPTIONS_SET= IPV6 THREADS


Search for a port

    root@wandboard:/usr/ports # make search name=iperf
    Port:   iperf-2.0.5
    Path:   /usr/ports/benchmarks/iperf
    Info:   Tool to measure maximum TCP and UDP bandwidth
    Maint:  sunpoet@FreeBSD.org
    B-deps:
    R-deps:
    WWW:    http://iperf.sourceforge.net/
    
    Port:   iperf3-3.0.8
    Path:   /usr/ports/benchmarks/iperf3
    Info:   Improved tool to measure TCP and UDP bandwidth
    Maint:  bmah@FreeBSD.org
    B-deps:
    R-deps:
    WWW:    https://github.com/esnet/iperf

List dependencies before building

    root@wandboard:/usr/ports/benchmarks/iperf # make all-depends-list
    /usr/ports/ports-mgmt/pkg

The *iperf* port has only one dependency - *pkg*

Build a port, this will build and install dependencies as well

    root@wandboard:/usr/ports/benchmarks/iperf # make install iperf
    ...

When it completes

    root@wandboard:/usr/ports/benchmarks/iperf # which iperf
    /usr/local/bin/iperf

    root@wandboard:/usr/ports/benchmarks/iperf # iperf -v
    iperf version 2.0.5 (08 Jul 2010) pthreads

Something a little bigger

    root@wandboard:/usr/ports # make search name=python27
    Port:   python27-2.7.8_5
    Path:   /usr/ports/lang/python27
    Info:   Interpreted object-oriented programming language
    Maint:  python@FreeBSD.org
    B-deps: gettext-0.18.3.1_1 indexinfo-0.2 pkgconf-0.9.7 readline-6.3.8
    R-deps: gettext-0.18.3.1_1 indexinfo-0.2 readline-6.3.8
    WWW:    http://www.python.org/

    root@wandboard:/usr/ports # cd lang/python27
    root@wandboard:/usr/ports/lang/python27 # make install

You'll get a dialog for a few options not in `/etc/make.conf`

    DEBUG (=n)
    PYMALLOC (=y)
    SEM (=y)
    UCS2 (=n)
    UCS4 (=y)

(I am accepting the defaults for all packages unless I specify otherwise.)

The *readline* build will also prompt for some config settings.

When it's done

    root@wandboard:/usr/ports/lang/python27 # ls /usr/local/bin
    2to3-2.7                idle2.7                 iperf                   pkgconf                 python2.7
    dialog4ports            indexinfo               pkg-config              pydoc2.7                python2.7-config

    root@wandboard:/usr/ports/lang/python27 # python2.7
    Python 2.7.8 (default, Oct  4 2014, 12:44:55)
    [GCC 4.2.1 Compatible FreeBSD Clang 3.4.1 (tags/RELEASE_34/dot1-final 208032)] on freebsd11
    Type "help", "copyright", "credits" or "license" for more information.
    >>> print 5+6
    11
    >>> quit()

Make it the default (probably a more standard way)

    root@wandboard:/usr/ports/lang/python27 # ln -s /usr/local/bin/python2.7 /usr/local/bin/python

    root@wandboard:/usr/ports/lang/python27 # python --version
    Python 2.7.8


[freebsd]: http://www.freebsd.org
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/
[freebsd-arm]: https://wiki.freebsd.org/FreeBSD/arm
[wandboard]: http://www.wandboard.org/
[beagleboard]: http://www.beagleboard.org/
[rpi]: http://www.raspberrypi.org/
[pandaboard]: http://www.pandaboard.org/
[overo]: https://store.gumstix.com/index.php/category/33/
[duovero]: https://store.gumstix.com/index.php/category/43/
[openbsd]: http://www.openbsd.org
[freebsd-boot-log]: https://gist.github.com/scottellis/1f9439f8ddd4fb87718e
[qt-site]: http://qt-project.org/
[webcamd]: http://www.selasky.org/hans_petter/video4bsd/
[syntrolcam]: https://github.com/Syntro/SyntroLCam

