---
layout: post
title: FreeBSD on ARM
description: "Running FreeBSD on ARM SOC boards"
date: 2014-09-30 10:30:00
categories: freebsd
tags: [freebsd, arm, wandboard, raspberry pi]
---

*FreeBSD* supports a number of [arm boards][freebsd-arm].

In particular, some of the boards I have are supported

* [wandboard][wandboard]
* [beaglebone black][beagleboard] and white
* [raspberry-pi][rpi]
* [pandaboard][pandaboard]
* beagleboard


The [FreeBSD][freebsd] site has some pre-built [binaries][freebsd-download]. 

I'm going to be testing with *FreeBSD 11.0*, the *CURRENT* branch. 

*FreeBSD 10.0* is the *STABLE* branch.


## Wandboard

Starting with a quad-core [wandboard][wandboard] (and working from a Linux workstation)

Download a *wandboard* image

	~/freebsd$ wget ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Unzip it

    ~/freebsd$ bunzip2 FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img.bz2

Copy it to a microSD card (assuming the SD card shows up at */dev/sdb*)

    ~/freebsd$ sudo dd if=FreeBSD-11.0-CURRENT-arm-armv6-WANDBOARD-QUAD.img of=/dev/sdb bs=4M

Insert into a *wandboard-quad* with serial console connected through a NULL modem (1152008N1) 

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


Not much running other then [dhclient(8)][dhclient] and [sshd(8)][sshd].

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

A running [sshd(8)][sshd] server is a nice convenience since it's usually the first thing I install on Linux systems. 

If you didn't want [sshd(8)][sshd] running at startup, you would change this line in [rc.conf(5)][rc.conf] in `/etc`

    sshd_enable="YES"

Root logins over *ssh* are not allowed by default. 

To get in with root, you can do this

1. Add a password to root
2. Edit `/etc/ssh/sshd_config` to *PermitRootLogin yes*
3. Then restart sshd.

    root@wandboard:~ # service sshd restart

And you should be able to log in over ssh in as *root*.

Or you could add another non-root user.

### Date/time

Set the timezone

    root@wandboard:~ # cp /usr/share/zoneinfo/EST5EDT /etc/localtime

Since the *wandboards* have no battery backup for system time, we'll want to start an [ntpd(8)][ntpd] daemon. To do this add some entries to the [rc.conf(5)][rc.conf] file

    ntpd_enable="YES"
    ntpd_sync_on_start="YES"

And start the service

    root@wandboard:~ # service ntpd start

Because there is no battery backup, the first update to the clock will likely be larger then *1000 seconds*. This is too much of an offset for [ntpd(8)][ntpd] and will cause it to shutdown. The `ntpd_sync_on_start` setting adds the `-g` flag to the [ntpd(8)][ntpd] arguments to allow [ntpd(8)][ntpd] to perform a onetime, very large update at startup.

You can remove the line for [ntpdate(8)][ntpdate]. The service is being retired.

### Static IP

If you wanted a *static* ipv4 address, you could make the following changes to [rc.conf(5)][rc.conf]

    - ifconfig_ffec0="DHCP"
    + ifconfig_ffec0="inet <address> netmask <netmask>"
    + defaultrouter="<default router address>"
    
For example

    ifconfig_ffec0="inet 192.168.10.21 netmask 255.255.255.0"
    defaultrouter="192.168.10.2"

And then you'll probably also want to add an entry in [resolv.conf(5)][resolv.conf] for *DNS*. Here's an example for my internal lan

    root@wandboard:~ # cat /etc/resolv.conf
    search jumpnow
    nameserver 192.168.10.2

The *ffec0* portion of that *ifconfig_ffec0* entry comes from the kernel driver name for the ethernet adapter. You can see the name with [ifconfig(8)][ifconfig] 

    root@wandq2:~ # ifconfig -a
    ffec0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
            options=80008<VLAN_MTU,LINKSTATE>
            ether 00:1f:7b:b4:03:79
            inet 192.168.10.21 netmask 0xffffff00 broadcast 192.168.10.255
            media: Ethernet autoselect (1000baseT <full-duplex,master>)
            status: active
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet6 ::1 prefixlen 128
            inet6 fe80::1%lo0 prefixlen 64 scopeid 0x2
            inet 127.0.0.1 netmask 0xff000000
            nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>


## RaspberryPi

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

The network is up and an [sshd(8)][sshd] is running.

To allow root *ssh* logins, I'm adding a password to root and modifying `/etc/ssh/sshd_config` the way I did with the *wandboard*.

NOTE: For the RPi, something is wrong with the console terminal settings and I can't use [vi(1)][vi].

The change we need for *sshd* is simple though and *sed* can be used instead

    root@raspberry-pi:~ # sed -i .bak 's/^#PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config

    root@raspberry-pi:~ # service sshd restart

After that, *ssh* root logins work and [vi(1)][vi] is functional from an *ssh* session.

TODO: Look into the console terminal problem with the RPi.

Setting up the timezone and date using [ntpd(8)][ntpd] works the same as with the *wandboard*.

## Pandaboard

Same procedure, download and unzip an image file then copy it to an SD card

    $ wget ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/FreeBSD-11.0-CURRENT-arm-armv6-PANDABOARD.img.bz2

    $ bunzip2 FreeBSD-11.0-CURRENT-arm-armv6-PANDABOARD.img.bz2

    $ sudo dd if=FreeBSD-11.0-CURRENT-arm-armv6-PANDABOARD.img of=/dev/sdb bs=1M

Connect a serial port (115200N8, no NULL modem).

Here is the initial [boot log][panda-boot-log].

And some miscellaneous system info

    root@pandaboard:~ # df -h
    Filesystem        Size    Used   Avail Capacity  Mounted on
    /dev/mmcsd0s2a    7.2G    319M    6.3G     5%    /
    devfs             1.0K    1.0K      0B   100%    /dev

    root@pandaboard:~ # sysctl -a | grep ncpu
    hw.ncpu: 2

    root@pandaboard:~ # sysctl -a | grep hw.physmem
    hw.physmem: 1066528768

After the same [sshd(8)][sshd] and [ntpd(8)][ntpd] setup and assigning a static ip

    root@pandaboard:~ # ifconfig -a
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet 127.0.0.1 netmask 0xff000000
    ue0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
            options=80001<RXCSUM,LINKSTATE>
            ether e6:96:97:c5:88:7d
            inet 192.168.10.22 netmask 0xffffff00 broadcast 192.168.10.255
            media: Ethernet autoselect (100baseTX <full-duplex>)
            status: active

### Next

Next up, building some [ports][ports] ... 


[freebsd]: http://www.freebsd.org
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/
[freebsd-arm]: https://wiki.freebsd.org/FreeBSD/arm
[wandboard]: http://www.wandboard.org/
[beagleboard]: http://www.beagleboard.org/
[rpi]: http://www.raspberrypi.org/
[pandaboard]: http://www.pandaboard.org/
[freebsd-boot-log]: https://gist.github.com/scottellis/1f9439f8ddd4fb87718e
[dhclient]: https://www.freebsd.org/cgi/man.cgi?query=sshd&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[sshd]: https://www.freebsd.org/cgi/man.cgi?query=sshd&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[ntpd]: https://www.freebsd.org/cgi/man.cgi?query=ntpd&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[ntpdate]: https://www.freebsd.org/cgi/man.cgi?query=ntpdate&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[rc.conf]: https://www.freebsd.org/cgi/man.cgi?query=rc.conf&apropos=0&sektion=5&manpath=FreeBSD+11-current&arch=default&format=html
[resolv.conf]: https://www.freebsd.org/cgi/man.cgi?query=resolv.conf&apropos=0&sektion=5&manpath=FreeBSD+11-current&arch=default&format=html
[ifconfig]: https://www.freebsd.org/cgi/man.cgi?query=ifconfig&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[vi]: https://www.freebsd.org/cgi/man.cgi?query=vi&apropos=0&sektion=1&manpath=FreeBSD+11-current&arch=default&format=html
[ftdi]: https://www.sparkfun.com/products/9873
[rpi-boot-log]: https://gist.github.com/scottellis/8f19c93c72afca2bf1b7
[panda-boot-log]: https://gist.github.com/scottellis/ead64590466cb17c3eb6
[ports]: http://www.freebsd.org/ports/
