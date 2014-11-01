---
layout: post
title: Setting the Overo Ethernet MAC
description: "Using ethtool to set the Overo ethernet MAC"
date: 2014-09-02 09:30:00
categories: gumstix overo
tags: [linux, gumstix, overo, ethtool]
---

You can use *ethtool* to set or change the Overo *LAN9221* ethernet MAC.

First the *magic* number 165 (0xa5)

    root@overo:~# ethtool -E eth0 value 0xa5 offset 0x00

Then the new *MAC* (example `96:D7:1B:3B:A8:FC`)

    root@overo:~# ethtool -E eth0 value 0x96 offset 0x01
    root@overo:~# ethtool -E eth0 value 0xd7 offset 0x02
    root@overo:~# ethtool -E eth0 value 0xab offset 0x03
    root@overo:~# ethtool -E eth0 value 0x3b offset 0x04
    root@overo:~# ethtool -E eth0 value 0xa8 offset 0x05
    root@overo:~# ethtool -E eth0 value 0xfc offset 0x06

Read it back

    root@overo:~# ethtool -e eth0
    Offset          Values
    ------          ------
    0x0000:         a5 96 d7 1b 3b a8 fc ff ff ff ff ff ff ff ff ff
    0x0010:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0020:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0030:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0040:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0050:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0060:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff
    0x0070:         ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff ff


Reboot and check the value

    root@fit:~# ifconfig eth0
    eth0      Link encap:Ethernet  HWaddr 96:D7:1B:3B:A8:FC
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
              Interrupt:80
