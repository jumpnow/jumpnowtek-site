---
layout: post
title: Running Snort on OpenBSD
description: "Running a Snort IDS on OpenBSD"
date: 2018-11-21 18:00:00
categories: security
tags: [openbsd, snort, bridging]
---

In order to get some practice with a network IDS I installed [Snort][snort] on an [OpenBSD][openbsd] machine that was available.

The things I am most interested in are writing custom rules and on the offensive side, evading detection. 

The original network looked like this on a single subnet.

    outside --- fw --- switch --- switch
                          |          |
                         test       dev
                       machines   machines

The two switches are in different parts of the building and I want to monitor traffic between test and dev machines.

Since neither of the switches supports a [network tap][network-tap], I am running the IDS machine as a transparent bridge placed like this

    outside --- fw --- switch --- ids --- switch

With this kind of setup is nothing else on the network has to change other then where I plug in two of the ethernet cables.

### OpenBSD

I am using an dual-core amd64 machine with 3 GigE nics for the hardware.

The operating system is OpenBSD 6.4. I installed the compiler sets, but no X11 or games.

The 3 nics show up as **re0**, **em0** and **em1**. 

The **re0** interface has a static IP that I use to access the machine.

The **em** interfaces used for the bridge do not need IP addresses

    ~$ cat /etc/hostname.em0
    up

    ~$ cat /etc/hostname.em1
    up

And here is the bridge interface

    ~$ cat /etc/hostname.bridge0
    add em0
    add em1
    up

When running it looks like this

    ~$ ifconfig -a
    ...
    em0: flags=8b43<UP,BROADCAST,RUNNING,PROMISC,ALLMULTI,SIMPLEX,MULTICAST> mtu 1500
            lladdr 00:1b:21:a2:a0:52
            index 1 priority 0 llprio 3
            media: Ethernet autoselect (1000baseT full-duplex,rxpause,txpause)
            status: active
    em1: flags=8b43<UP,BROADCAST,RUNNING,PROMISC,ALLMULTI,SIMPLEX,MULTICAST> mtu 1500
            lladdr 00:1b:21:a2:a0:53
            index 2 priority 0 llprio 3
            media: Ethernet autoselect (1000baseT full-duplex,rxpause,txpause)
            status: active
    ...
    bridge0: flags=41<UP,RUNNING>
            index 6 llprio 3
            groups: bridge
            priority 32768 hellotime 2 fwddelay 15 maxage 20 holdcnt 6 proto rstp
            em0 flags=3<LEARNING,DISCOVER>
                    port 1 ifpriority 0 ifcost 0
            em1 flags=3<LEARNING,DISCOVER>
                    port 2 ifpriority 0 ifcost 0
    pflog0: flags=141<UP,RUNNING,PROMISC> mtu 33136
            index 7 priority 0 llprio 3
            groups: pflog

### Snort Setup

For more details see [this post][lteo_net_post] from the maintainer of the Snort port on OpenBSD.

Snort can be installed with the package manager.

    ~# pkg_add snort

I am using the [oinkcode][oinkcode] ruleset. 

After downloading, install the ruleset like this

    ~# tar -C /etc/snort -xzf snortrules-snapshot-2990.tar.gz


At a minimum, tell Snort which interface to watch

    ~$ grep -n em0 /etc/snort/snort.conf
    44:config interface: em0

You can use [rcctl][rcctl] to control Snort.

    # rcctl start snort
    # rcctl stop snort
    # rcctl restart snort

This will enable starting at boot.

    # rcctl enable snort

Snort alerts are logged here

    /var/snort/log/alert

I did not install a GUI for Snort, but tail works fine. 

    ~# tail -f /var/snort/log/alert

After that its all about customizing the rules for your LAN.

### Customizing rules

Here is a quick change to catch noisy [Nmap][nmap] scans.

Edit /etc/snort/snort.conf and modify these two lines

    - # preprocessor sfportscan: proto { all } memcap { 10000000 } sense_level { low }
    + preprocessor sfportscan: proto { all } scan_type { all } memcap { 10000000 } sense_level { low }

and

    - # include $PREPROC_RULE_PATH/preprocessor.rules
    + include $PREPROC_RULE_PATH/preprocessor.rules

Restart snort.

Running a scan of a **dev** machine from a **test** machine

    ~# nmap 192.168.10.4

This shows up in the snort alert log

    [**] [122:1:1] (portscan) TCP Portscan [**]
    [Classification: Attempted Information Leak] [Priority: 2]
    11/22-13:45:54.091767 192.168.10.240 -> 192.168.10.4
    RESERVED TTL:39 TOS:0x0 ID:59253 IpLen:20 DgmLen:165

Or with a UDP scan

    ~# nmap -sU 192.168.10.4

Alerts like this

    [**] [122:17:1] (portscan) UDP Portscan [**]
    [Classification: Attempted Information Leak] [Priority: 2]
    11/22-13:46:33.592670 192.168.10.240 -> 192.168.10.4
    RESERVED TTL:128 TOS:0x0 ID:11208 IpLen:20 DgmLen:166

### Firewalling on the bridge

You can add firewall rules to the bridge.

For example, just fooling around

    ~# cat /etc/pf.conf

    br0_if = "em0"

    nameserver = "192.168.10.1"

    set skip on lo

    # block a noisy AP
    block in quick on $br0_if proto udp to port ssdp

    # force everyone to use our nameserver
    pass in log quick on $br0_if proto { tcp, udp } from any \
        to ! $nameserver port domain rdr-to $nameserver


To watch firewall log events in real-time

    ~# tcpdump -i pflog0 -s 160 -e -n -ttt

Or to look at the firewall log

    ~# tcpdump -r /var/log/pflog -s 160 -e -n -ttt | less


[openbsd]: https://www.openbsd.org
[snort]: https://snort.org
[lteo_net_post]: http://lteo.net/blog/2016/10/26/testing-your-snort-rules-redux/
[oinkcode]: https://www.snort.org/users/sign_in
[rcctl]: https://man.openbsd.org/rcctl
[network-tap]: https://en.wikipedia.org/wiki/Network_tap
[nmap]: https://nmap.org/