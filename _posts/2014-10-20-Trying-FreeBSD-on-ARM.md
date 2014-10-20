---
layout: post
title: Getting started with FreeBSD on ARM
description: "Some initial notes on running FreeBSD on a Wandboard-Quad"
date: 2014-09-30 10:30:00
categories: freebsd
tags: [freebsd, arm, wandboard]
---

Some initial notes getting started [FreeBSD][freebsd] on ARM boards.

*FreeBSD* already supports a number of [arm boards][freebsd-arm].

In particular, a lot of the boards I have laying around are supported

* [wandboard][wandboard]
* [beaglebone black][beagleboard] and white
* [raspberry-pi][rpi]
* [pandaboard][pandaboard]
* beagleboard

Unfortunately no Gumstix [Duovero][duovero] or [Overo][overo].


## Quick start

The [FreeBSD][freebsd] site has some pre-built [binaries][freebsd-download] for a number of boards. I'm going to start with the development *11.0* binaries. *10.0* is the current *FreeBSD* production version.

Working from a nix machine and choosing a quad-core [wandboard][wandboard] as the first test...

Download a *wandboard* image

	~/freebsd$ wget ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Unzip it

    ~/freebsd$ bunzip2 FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Copy it to a microSD card (assuming the SD card shows up at */dev/sdb*)

    ~/freebsd$ sudo dd if=FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img of=/dev/sdb bs=4M

Insert into a *wandboard-quad* with serial console access (1152008N1) 

Here is the [boot log][freebsd-boot-log].

The root user has no password.

If you had an ethernet cable plugged in you should get a *dhcp* address.

A nice feature is that the filesystem got expanded to fill the SD card during the first boot.

    root@wandboard:~ # df -h
    Filesystem        Size    Used   Avail Capacity  Mounted on
    /dev/mmcsd0s2a     14G    403M     13G     3%    /
    devfs             1.0K    1.0K      0B   100%    /dev
    /dev/mmcsd0s1      50M    260K     50M     1%    /boot/msdos
    tmpfs              30M    4.0K     30M     0%    /tmp
    tmpfs              15M     52K     15M     0%    /var/log
    tmpfs             5.0M    4.0K    5.0M     0%    /var/tmp


Not much running other then *dhcpclient* and *sshd*.

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

A running *ssh* server is a convenience for me since I almost always install one. To disable the *ssh* server, you would change this line in `/etc/rc.conf`

    sshd_enable="YES"

Root logins over *ssh* are not allowed by default. 

To get in with root, you can do this

1. Add a password to root
2. Edit `/etc/ssh/sshd_config` to *PermitRootLogin yes*
3. Then restart sshd.

    root@wandboard:~ # service sshd restart

And you should be able to ssh in as *root*.

Or you could add another user.

### Date/time

Set the timezone

    root@wandboard:~ # cp /usr/share/zoneinfo/EST5EDT /etc/localtime

The *ntpdate* daemon will set time on startup. Enable it in `/etc/rc.conf`

    ntpdate_enable="YES"

Kick it to update once

    root@wandboard:~ # service ntpdate start 

TODO: Use *ntp* instead for continuous time updates


Next up, building some *ports*...


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

