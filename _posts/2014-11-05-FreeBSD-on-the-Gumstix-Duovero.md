---
layout: post
title: FreeBSD on the Gumstix Duovero
description: "Booting FreeBSD on a Gumstix Duovero"
date: 2014-11-05 06:30:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero]
---

Thanks to the fine tools from the [crochet-freebsd][crochet-freebsd] project, I was able to get a [Gumstix Duovero][duovero] booting [FreeBSD][freebsd] without too much effort.

There is no direct support for the Duovero in the FreeBSD CURRENT source tree, but there is [PandaBoard][pandaboard] support, which is another TI OMAP4430 based board. That's what I am using for now.

There is [U-Boot][uboot] support for the Duovero, so I was able to use a current U-Boot (`2014.10`) with only a few configuration [changes][uboot-duovero-patch] from what I use with Linux.

My complete *crochet* setup for the Duovero can be found [here][crochet-duovero].

Here is the [boot log][duovero-boot-log].

Note that [clang(1)][clang] was used to build the system.

A little system probing

    root@duovero:~ # sysctl -a | grep ncpu
    hw.ncpu: 2

    root@duovero:~ # sysctl -a | grep hw.physmem
    hw.physmem: 1066090496

    root@duovero:~ # ps -ax
    PID TT  STAT     TIME COMMAND
      0  -  DLs   0:02.02 [kernel]
      1  -  ILs   0:00.04 /sbin/init --
      2  -  DL    0:00.00 [cam]
      3  -  DL    0:00.04 [mmcsd0: mmc/sd card]
      4  -  DL    0:00.03 [pagedaemon]
      5  -  DL    0:00.00 [vmdaemon]
      6  -  DL    0:00.00 [pagezero]
      7  -  DL    0:00.02 [bufdaemon]
      8  -  DL    0:00.02 [syncer]
      9  -  DL    0:00.01 [vnlru]
     10  -  RL   14:57.51 [idle]
     11  -  WL    0:01.16 [intr]
     12  -  DL    0:00.10 [geom]
     13  -  DL    0:00.09 [rand_harvestq]
     14  -  DL    0:00.01 [usb]
     15  -  DL    0:00.04 [schedcpu]
    198  -  Rs    0:00.00 /sbin/devd
    267  -  Is    0:00.05 /usr/sbin/syslogd -s
    369  -  Is    0:00.01 casperd: zygote (casperd)
    370  -  Is    0:00.01 /sbin/casperd
    467  -  Ss    0:00.07 sendmail: accepting connections (sendmail)
    470  -  Is    0:00.02 sendmail: Queue runner@00:30:00 for /var/spool/clientmque
    474  -  Is    0:00.03 /usr/sbin/cron -s
    517 u0  Is    0:00.08 login [pam] (login)
    529 u0  S     0:00.14 -csh (csh)
    537 u0  R+    0:00.02 ps -ax

    root@duovero:~ # ifconfig -a
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet6 ::1 prefixlen 128
            inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
            inet 127.0.0.1 netmask 0xff000000
            nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>

    root@duovero:~ # df -h
    Filesystem        Size    Used   Avail Capacity  Mounted on
    /dev/mmcsd0s2a    7.2G    326M    6.3G     5%    /
    devfs             1.0K    1.0K      0B   100%    /dev
    /dev/mmcsd0s1     2.0M    595K    1.4M    29%    /boot/msdos

    root@duovero:~ # ls -l /boot/msdos
    total 594
    -rwxr-xr-x  1 root  wheel   49304 Nov  5 05:27 mlo
    -rwxr-xr-x  1 root  wheel  307196 Nov  5 05:27 u-boot.img
    -rwxr-xr-x  1 root  wheel  251107 Nov  5 05:27 ubldr

Since it's a BSD, the system is already complete. No *distro* packaging stuff to be done the ways it has to with *Linux*. 

For instance, here's the compiler

    root@duovero:~ # cc --version
    FreeBSD clang version 3.4.1 (tags/RELEASE_34/dot1-final 208032) 20140512
    Target: armv6--freebsd11.0-gnueabi
    Thread model: posix

I didn't install the source tree, but that's something [crochet][crochet-freebsd] supports doing as part of the image build. That should allow for native development. We'll see if that's the best way. Still new to this.

I think the next step is to add a proper Duovero configuration to the FreeBSD source. 

Then ethernet, wifi and USB Host support. That alone would cover the majority of my customer projects with the Duovero.

I've already experimented with the [FreeBSD ports][freebsd-ports] on several other ARM boards (primarily [Wandboards][wandboard]) and haven't run into any problems.

This is obviously the early stages, but it's pretty promising.

You can download the image [here][img-download].

[crochet-freebsd]: https://github.com/kientzle/crochet-freebsd
[duovero]: https://store.gumstix.com/index.php/category/43/
[freebsd]: http://www.freebsd.org
[pandaboard]: http://www.pandaboard.org/
[uboot]: http://www.denx.de/wiki/U-Boot/
[uboot-duovero-patch]: https://github.com/scottellis/crochet-freebsd/tree/duovero/board/Duovero/files
[duovero-boot-log]: https://gist.github.com/scottellis/0413bd5198b94e74d319
[clang]: https://www.freebsd.org/cgi/man.cgi?query=clang&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[freebsd-ports]: https://www.freebsd.org/ports/
[wandboard]: http://www.wandboard.org/
[crochet-duovero]: https://github.com/scottellis/crochet-freebsd/tree/duovero
[img-download]: http://www.jumpnowtek.com/downloads/freebsd/duovero/
