---
layout: post
title: Running Snort on OpenBSD
description: "Running a Snort IDS on OpenBSD"
date: 2018-11-21 18:00:00
categories: security
tags: [openbsd, snort, bridging]
---

I wanted some practice with an [IDS][ids], writing custom rules, evading detection, that kind of thing.

[OpenBSD][openbsd] is generally my preferred platform for network services and though I have used [Snort][snort] before it was never on OpenBSD. So that's what I decided to use for this experiment.

The test network looks like this on a single subnet.

    outside --- fw --- switch A --- switch B
                           |            |
                        group A      group B
                        machines     machines

For testing I want to monitor traffic between group A and group B machines.

Since neither of the switches supports a [network tap][network-tap], I am going to run the IDS machine as a bridge placed like this

    outside --- fw --- switch A --- ids --- switch B

This configuration makes it easy to pull the IDS back out of the network when I am done.

### OpenBSD Setup

I am using an older dual-core amd64 machine with 3 GigE nics for the hardware.

The operating system is OpenBSD 6.4. I installed the compiler sets, but not X11 or games.

The 3 nics show up as **re0**, **em0** and **em1**. 

The **re0** interface has a static IP used for access.

    ~$ cat /etc/hostname.re0
    inet 192.168.10.2 255.255.255.0

The **em** interfaces used for the bridge do not need IP addresses.

    ~$ cat /etc/hostname.em0
    up

    ~$ cat /etc/hostname.em1
    up

And here is the bridge interface configuration

    ~$ cat /etc/hostname.bridge0
    add em0
    add em1
    blocknonip em0
    blocknonip em1
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

Pretty simple.

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

After that its just a matter of tuning the rules for the network.

### Check It

To verify things are working, here is a quick change to catch noisy [Nmap][nmap] scans.

Edit **/etc/snort/snort.conf** and modify these two lines

    - # preprocessor sfportscan: proto { all } memcap { 10000000 } sense_level { low }
    + preprocessor sfportscan: proto { all } scan_type { all } memcap { 10000000 } sense_level { low }

and

    - # include $PREPROC_RULE_PATH/preprocessor.rules
    + include $PREPROC_RULE_PATH/preprocessor.rules

Restart snort.

Now running a scan of an **A** machine from a **B** machine

    ~# nmap 192.168.10.4

produces alerts like this in the snort log

    [**] [122:1:1] (portscan) TCP Portscan [**]
    [Classification: Attempted Information Leak] [Priority: 2]
    11/22-13:45:54.091767 192.168.10.240 -> 192.168.10.4
    RESERVED TTL:39 TOS:0x0 ID:59253 IpLen:20 DgmLen:165

Or a UDP scan

    ~# nmap -sU 192.168.10.4

produces alerts like this

    [**] [122:17:1] (portscan) UDP Portscan [**]
    [Classification: Attempted Information Leak] [Priority: 2]
    11/22-13:46:33.592670 192.168.10.240 -> 192.168.10.4
    RESERVED TTL:128 TOS:0x0 ID:11208 IpLen:20 DgmLen:166

### Firewalling on the bridge

You can add firewall rules to the bridge if you want to expand the experiment.

In my setup, **em0** faces the B switch.

A simple example

    ~# cat /etc/pf.conf

    br0_if = "em0"

    nameserver = "192.168.10.1"

    # block a noisy AP in the B group
    block in quick on $br0_if proto udp to port ssdp

    # force use of a nameserver for B hosts
    pass in log quick on $br0_if proto { tcp, udp } from any \
        to ! $nameserver port domain rdr-to $nameserver

The **pf** firewall logs in pcap format.

To watch real-time events

    ~# tcpdump -i pflog0 -s 160 -e -n -ttt

The historical log

    ~# tcpdump -r /var/log/pflog -s 160 -e -n -ttt


As with all things OpenBSD, the [man pages][openbsd-man] are the definitive resource.


[ids]: https://en.wikipedia.org/wiki/Intrusion_detection_system
[openbsd]: https://www.openbsd.org
[snort]: https://snort.org
[lteo_net_post]: http://lteo.net/blog/2016/10/26/testing-your-snort-rules-redux/
[oinkcode]: https://www.snort.org/users/sign_in
[rcctl]: https://man.openbsd.org/rcctl
[network-tap]: https://en.wikipedia.org/wiki/Network_tap
[nmap]: https://nmap.org/
[openbsd-man]: https://man.openbsd.org/