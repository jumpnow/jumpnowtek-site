---
layout: post
title: FreeBSD Duovero USB Wireless
description: "Enabling drivers for USB wireless on a FreeBSD Duovero system"
date: 2014-11-11 12:35:00
categories: freebsd
tags: [freebsd, gumstix, duovero, usb, wireless]
---

It was getting painful working without a network on the FreeBSD Duovero systems I've been playing with. So I took a look at what was involved to get a USB WIFI dongle working.

One of the changes was to go back and get the *USB Host* initialization code I deleted in  `sys/arm/ti/omap4/duovero/duovero.c` when I copied it from `head/sys/arm/ti/omap4/pandaboard/pandaboard.c`. 

The Pandaboard has a built-in USB/ethernet controller that the Duovero doesn't. But the code I deleted enables the USB Host controller for anything on the USB Host port. (I thought at the time it was initialization only for the USB/ethernet.)

After that I needed to add some wifi drivers to the kernel.

I had some cheap [Edimax EW-7811Un][edimax] USB/wifi dongles I was using with [RaspberryPis][rpi].

I plugged one into my FreeBSD build workstation to see what driver loaded. [urtwn(4)][urtwn]. Then I followed the instructions to add the appropriate driver to the kernel config `sys/arm/conf/DUOVERO`.

After a rebuild and the *edimax* dongle was detected and the driver loaded.

    root@duovero:~ # dmesg | grep usb
    usbus0: EHCI version 1.0
    usbus0 on ehci0
    usbus0: 480Mbps High Speed USB v2.0
    ugen0.1: <Texas Instruments> at usbus0
    uhub0: <Texas Instruments EHCI root HUB, class 9/0, rev 2.00/1.00, addr 1> on usbus0
    Root mount waiting for: usbus0
    Root mount waiting for: usbus0
    Root mount waiting for: usbus0
    ugen0.2: <vendor 0x7392> at usbus0
    urtwn0: <vendor 0x7392 product 0x7811, class 0/0, rev 2.00/2.00, addr 2> on usbus0

    root@duovero:~ # dmesg | grep urtwn
    urtwn0: <vendor 0x7392 product 0x7811, class 0/0, rev 2.00/2.00, addr 2> on usbus0
    urtwn0: MAC/BB RTL8188CUS, RF 6052 1T1R


Full boot log is [here][boot-log].

The *Quick Start* section of the [Wireless Networking][wireless-networking] chapter of the [FreeBSD Handbook][freebsd-handbook] was all I needed for userland setup.

The changes were to add a new [wpa_supplicant.conf(5)][wpa-supplicant-conf]

    root@duovero:~ # cat /etc/wpa_supplicant.conf
    network={
            ssid="jumpnow"
            psk="november"
    }
 
And two lines added to [rc.conf(5)][rc-conf]

    wlans_urtwn0="wlan0"
    ifconfig_wlan0="WPA SYNCDHCP"

After restarting the network

    root@duovero:~ # service netif restart

or after a reboot, the network came up.

    root@duovero:~ # ifconfig -a
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet6 ::1 prefixlen 128
            inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
            inet 127.0.0.1 netmask 0xff000000
            nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
    urtwn0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 2290
            ether 80:1f:02:70:93:0f
            media: IEEE 802.11 Wireless Ethernet autoselect mode 11g
            status: associated
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
    wlan0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
            ether 80:1f:02:70:93:0f
            inet 192.168.10.103 netmask 0xffffff00 broadcast 192.168.10.255
            ssid jumpnow channel 9 (2452 MHz 11g) bssid e4:f4:c6:0d:91:f2
            country US authmode WPA2/802.11i privacy ON deftxkey UNDEF
            AES-CCM 2:128-bit txpower 0 bmiss 7 scanvalid 60 bgscan
            bgscanintvl 300 bgscanidle 250 roam:rssi 7 roam:rate 5 protmode CTS
            roaming MANUAL
            media: IEEE 802.11 Wireless Ethernet OFDM/54Mbps mode 11g
            status: associated
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>

    root@duovero:~ # ping www.freebsd.org
    PING wfe0.ysv.freebsd.org (8.8.178.110): 56 data bytes
    64 bytes from 8.8.178.110: icmp_seq=0 ttl=54 time=102.102 ms
    64 bytes from 8.8.178.110: icmp_seq=1 ttl=54 time=94.432 ms
    64 bytes from 8.8.178.110: icmp_seq=2 ttl=54 time=95.169 ms
    ^C
    --- wfe0.ysv.freebsd.org ping statistics ---
    3 packets transmitted, 3 packets received, 0.0% packet loss
    round-trip min/avg/max/stddev = 94.432/97.234/102.102/3.455 ms

I had another type of mini-USB wifi dongle, a [TRENDnet NSpeed][trendnet-nspeed]. I figured out the driver the same way, plugging it into a workstation and watching the log. The driver for this device is [rsu(4)][rsu].

I added this driver to the Duovero board file `sys/arm/conf/DUOVERO`. My wifi driver section now looks like this

    # USB Wireless
    device         rum                     # Ralink Technology RT2501USB wireless NICs
    device         urtwn                   # Realtek RTL8188CU/RTL8188EU/RTL8192CU
    device         urtwnfw
    device         rsu                     # Realtek RTL8188SU/RTL8192SU
    device         rsufw
    device         firmware

The [rum(4)][rum] driver was already there.

Rebuilding and booting with the *TRENDnet* plugged in and the conf files adjusted.

    root@duovero:~ # dmesg | grep rsu
    rsu0: <vendor 0x0bda product 0x8172, class 0/0, rev 2.00/2.00, addr 2> on usbus0
    rsu0: MAC/BB RTL8712 cut 3

    root@duovero:~ # ifconfig -a
    lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> metric 0 mtu 16384
            options=600003<RXCSUM,TXCSUM,RXCSUM_IPV6,TXCSUM_IPV6>
            inet6 ::1 prefixlen 128
            inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
            inet 127.0.0.1 netmask 0xff000000
            nd6 options=21<PERFORMNUD,AUTO_LINKLOCAL>
    rsu0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 2290
            options=1<RXCSUM>
            ether 00:14:d1:6f:e6:fd
            media: IEEE 802.11 Wireless Ethernet autoselect mode 11g
            status: associated
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>
    wlan0: flags=8843<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> metric 0 mtu 1500
            ether 00:14:d1:6f:e6:fd
            inet 192.168.10.120 netmask 0xffffff00 broadcast 192.168.10.255
            ssid jumpnow channel 9 (2452 MHz 11g) bssid e4:f4:c6:0d:91:f2
            country US authmode WPA2/802.11i privacy ON deftxkey UNDEF
            AES-CCM 2:128-bit txpower 0 bmiss 7 scanvalid 60 bgscan
            bgscanintvl 300 bgscanidle 250 roam:rssi 7 roam:rate 5 protmode CTS
            roaming MANUAL
            media: IEEE 802.11 Wireless Ethernet OFDM/54Mbps mode 11g
            status: associated
            nd6 options=29<PERFORMNUD,IFDISABLED,AUTO_LINKLOCAL>

    root@duovero:~ # ping black.jumpnow
    PING black.jumpnow (192.168.10.2): 56 data bytes
    64 bytes from 192.168.10.2: icmp_seq=0 ttl=255 time=1.810 ms
    64 bytes from 192.168.10.2: icmp_seq=1 ttl=255 time=0.784 ms
    64 bytes from 192.168.10.2: icmp_seq=2 ttl=255 time=0.845 ms
    64 bytes from 192.168.10.2: icmp_seq=3 ttl=255 time=0.693 ms
    ^C
    --- black.jumpnow ping statistics ---
    4 packets transmitted, 4 packets received, 0.0% packet loss
    round-trip min/avg/max/stddev = 0.693/1.033/1.810/0.452 ms

    root@duovero:~ # ssh scott@fbsd.jumpnow
    Password for scott@fbsd:
    Last login: Tue Nov 11 15:22:19 2014 from 192.168.10.120
    FreeBSD 10.1-RC3 (GENERIC) #0 r273437: Tue Oct 21 23:55:15 UTC 2014

And now that there's a network, I enabled the [sshd(8)][sshd] service and logged in from another host.

    scott@hex:~$ ssh root@192.168.10.120
    Warning: Permanently added '192.168.10.120' (ECDSA) to the list of known hosts.
    Password for root@duovero:
    Last login: Tue Nov 11 20:26:51 2014 from hex.jumpnow
    FreeBSD 11.0-CURRENT (DUOVERO) #1 r274385: Tue Nov 11 14:51:31 EST 2014

    root@duovero:~ #


The kernel changes can be found [here][duovero-freebsd-github].

The *crochet* board configuration can be found [here][crochet] in the `[duovero]` branch.

The latest image binary can be downloaded from [here][downloads].


[edimax]: http://www.edimax.com/edimax/merchandise/merchandise_detail/data/edimax/global/wireless_adapters_n150/ew-7811un
[rpi]: http://www.raspberrypi.org/
[urtwn]: https://www.freebsd.org/cgi/man.cgi?query=urtwn&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html
[wpa-supplicant-conf]: https://www.freebsd.org/cgi/man.cgi?query=wpa_supplicant.conf&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[wpa-supplicant]: https://www.freebsd.org/cgi/man.cgi?query=wpa_supplicant&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[boot-log]: https://gist.github.com/scottellis/0413bd5198b94e74d319
[wireless-networking]: https://www.freebsd.org/doc/handbook/network-wireless.html
[rc-conf]: https://www.freebsd.org/cgi/man.cgi?query=rc.conf&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[trendnet-nspeed]: http://www.trendnet.com/products/proddetail.asp?prod=200_TEW-649UB
[rsu]: https://www.freebsd.org/cgi/man.cgi?query=rsu&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[rum]: https://www.freebsd.org/cgi/man.cgi?query=rum&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[sshd]: https://www.freebsd.org/cgi/man.cgi?query=sshd&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[duovero-freebsd-github]: https://github.com/scottellis/duovero-freebsd
[crochet]: https://github.com/scottellis/crochet-freebsd/tree/duovero
[downloads]: http://www.jumpnowtek.com/downloads/freebsd/duovero/
[freebsd-handbook]: http://www.freebsd.org/doc/en/books/handbook/