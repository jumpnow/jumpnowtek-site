---
layout: post
title: FreeBSD on ARM
description: "Running FreeBSD on some ARM boards"
date: 2014-09-30 10:30:00
categories: freebsd
tags: [freebsd, arm, wandboard, raspberry pi]
---

I've been waiting to try out [FreeBSD][freebsd] on ARM boards and finally have some downtime.

*FreeBSD* already supports a number of [arm boards][freebsd-arm].

In particular, a lot of the boards I have laying around are supported

* [wandboard][wandboard]
* [beaglebone black][beagleboard] and white
* [raspberry-pi][rpi]
* [pandaboard][pandaboard]
* beagleboard

Unfortunately no Gumstix [Duovero][duovero] or [Overo][overo] at this time.


## Quick start

The [FreeBSD][freebsd] site has some pre-built [binaries][freebsd-download]. 

I'm going to be testing with the *11.0* development branch of FreeBSD (*CURRENT*). 

*10.0* is the FreeBSD *STABLE* branch (what I'm running on my [PC-BSD][pcbsd] laptop).

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


### Now with an RPi

Download, unzip and copy to an SD card

    $ wget ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-arm-armv6-RPI-B.img.bz2

    $ bunzip2 FreeBSD-11.0-CURRENT-arm-armv6-RPI-B.img.bz2

    $ sudo dd if=FreeBSD-11.0-CURRENT-arm-armv6-RPI-B.img of=/dev/sdb bs=4M

I'm using a [Sparkfun FTDI Basic Breakout][ftdi] board to get a USB serial console

    RPI      FTDI
    P1-06    GND
    P1-08    RX
    P1-10    TX

And with an ethernet cable connected, here's the initial [boot log][rpi-boot-log].

    root@raspberry-pi:/etc/ssh # ifconfig -a
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet6 ::1 prefixlen 128
            inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
            inet 127.0.0.1 netmask 0xff000000
            nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
    ue0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
            options=80001<RXCSUM,LINKSTATE>
            ether b8:27:eb:12:73:e8
            inet 192.168.10.106 netmask 0xffffff00 broadcast 192.168.10.255
            media: Ethernet autoselect (100baseTX <full-duplex>)
            status: active
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>

The network is up and an *ssh* server is running.

To allow root *ssh* logins, I'm adding a password to root and modifying `/etc/ssh/sshd_config` the way I did with the *wandboard*.

NOTE: For the RPi, something is wrong with the console terminal settings and I can't use *vi*.

The change we need for *sshd* is simple though and *sed* can be used instead

    root@raspberry-pi:~ # sed -i .bak 's/^#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

    root@raspberry-pi:~ # service sshd restart

After that, *ssh* root logins work and *vi* is functional from an *ssh* session.

TODO: Look into the console terminal problem with the RPi.

Setting up the timezone and date using *ntpdate* works the same as with the *wandboard*.

### Next

Next up, building some [ports][ports] ... 


[freebsd]: http://www.freebsd.org
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/
[freebsd-arm]: https://wiki.freebsd.org/FreeBSD/arm
[wandboard]: http://www.wandboard.org/
[beagleboard]: http://www.beagleboard.org/
[rpi]: http://www.raspberrypi.org/
[pandaboard]: http://www.pandaboard.org/
[overo]: https://store.gumstix.com/index.php/category/33/
[duovero]: https://store.gumstix.com/index.php/category/43/
[pcbsd]: http://www.pcbsd.org/
[freebsd-boot-log]: https://gist.github.com/scottellis/1f9439f8ddd4fb87718e
[ftdi]: https://www.sparkfun.com/products/9873
[rpi-boot-log]: https://gist.github.com/scottellis/8f19c93c72afca2bf1b7
[ports]: http://www.freebsd.org/ports/