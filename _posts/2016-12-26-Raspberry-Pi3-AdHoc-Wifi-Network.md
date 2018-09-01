---
layout: post
title: Raspberry Pi 3 AdHoc Wifi Network
description: "Enabling AdHoc Wifi with the Raspberry PI 3"
date: 2016-12-26 13:22:00
categories: rpi
tags: [linux, rpi, yocto, rpi3, wifi]
---

If you are using O/S images built from my [meta-rpi][meta-rpi] Yocto meta-layer you can setup an *AdHoc* wifi network by editing `/etc/network/interfaces` like this


    root@rpi3:~# cat /etc/network/interfaces
    auto lo
    iface lo inet loopback

    #auto eth0
    iface eth0 inet dhcp

    auto wlan0
    iface wlan0 inet static
            pre-up iwconfig wlan0 mode ad-hoc essid 'rpi'
            address 192.168.5.2
            netmask 255.255.255.0


After that you should see the following after reboot or restarting the network

    root@rpi3:~# ifconfig wlan0
    wlan0     Link encap:Ethernet  HWaddr B8:27:EB:03:CE:89
              inet addr:192.168.5.2  Bcast:192.168.5.255  Mask:255.255.255.0
              inet6 addr: fe80::ba27:ebff:fe03:ce89%2122906392/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:475 errors:0 dropped:394 overruns:0 frame:0
              TX packets:123 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:73722 (71.9 KiB)  TX bytes:20828 (20.3 KiB)

    root@rpi3:~# iw wlan0 info
    Interface wlan0
            ifindex 3
            wdev 0x1
            addr b8:27:eb:03:ce:89
            ssid rpi
            type IBSS
            wiphy 0
            txpower 31.00 dBm

    root@rpi3:~# iwconfig wlan0
    wlan0     IEEE 802.11bgn  ESSID:"rpi"
              Mode:Ad-Hoc  Frequency:2.412 GHz  Cell: D2:D4:86:A3:CA:E5
              Tx-Power=31 dBm
              Retry short limit:7   RTS thr:off   Fragment thr:off
              Encryption key:off
              Power Management:on


And from a laptop running *Fedora 25* also configured for an *AdHoc* network and with an IP address of **192.168.5.3** I can communicate

     root@rpi3:~# ping 192.168.5.3
     PING 192.168.5.3 (192.168.5.3): 56 data bytes
     64 bytes from 192.168.5.3: seq=0 ttl=64 time=8.259 ms
     64 bytes from 192.168.5.3: seq=1 ttl=64 time=7.971 ms
     ^C
     --- 192.168.5.3 ping statistics ---
     2 packets transmitted, 2 packets received, 0% packet loss
     round-trip min/avg/max = 7.971/8.115/8.259 ms


     root@rpi3:~# ssh scott@192.168.5.3
     scott@192.168.5.3's password:
     Last login: Mon Dec 26 11:44:24 2016 from 192.168.5.2
     scott@t410:~$ exit
     logout
     Connection to 192.168.5.3 closed.
     root@rpi3:~#


[meta-rpi]: https://github.com/jumpnow/meta-rpi
