---
layout: post
title: Gumstix USB OTG Gadget Drivers
date: 2014-08-13 04:09:00
categories: gumstix duovero overo
tags: [gumstix, duovero, usb otg, gadget driver, g\_ether, g\_serial, g\_mass_storage]
---

All of the USB gadget drivers are built as modules.

### USB Networking

The USB *gadget* driver for networking is `g_ether`.

Load it with *modprobe*

    root@duovero:~# modprobe g_ether
    [ 2602.003479]  gadget: using random self ethernet address
    [ 2602.009094]  gadget: using random host ethernet address
    [ 2602.015472] usb0: MAC 96:8d:b9:0a:2e:04
    [ 2602.019561] usb0: HOST MAC 4e:db:41:65:e6:3a
    [ 2602.024169]  gadget: Ethernet Gadget, version: Memorial Day 2008
    [ 2602.030578]  gadget: g_ether ready
    [ 2602.233703] musb-hdrc musb-hdrc: MUSB HDRC host driver
    [ 2602.239532] musb-hdrc musb-hdrc: new USB bus registered, assigned bus number 3
    [ 2602.247314] usb usb3: New USB device found, idVendor=1d6b, idProduct=0002
    [ 2602.254455] usb usb3: New USB device strings: Mfr=3, Product=2, SerialNumber=1
    [ 2602.262023] usb usb3: Product: MUSB HDRC host driver
    [ 2602.267242] usb usb3: Manufacturer: Linux 3.6.11-jumpnow musb-hcd
    [ 2602.273620] usb usb3: SerialNumber: musb-hdrc
    [ 2602.279083] hub 3-0:1.0: USB hub found
    [ 2602.283081] hub 3-0:1.0: 1 port detected
    [ 2602.711151]  gadget: high-speed config #1: CDC Ethernet (ECM)


Or put the following line in `/etc/modules` to have it load at boot.

    g_ether

When the module is loaded you should see a `usb0` network interface.

    root@duovero:~# ifconfig usb0
    usb0      Link encap:Ethernet  HWaddr 96:8D:B9:0A:2E:04
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)


You can give the interface an address manually

    root@duovero:~# ifconfig usb0 192.168.20.2

    root@duovero:~# ifconfig usb0
    usb0      Link encap:Ethernet  HWaddr 96:8D:B9:0A:2E:04
              inet addr:192.168.20.2  Bcast:192.168.20.255  Mask:255.255.255.0
              inet6 addr: fe80::948d:b9ff:fe0a:2e04/64 Scope:Link
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)


Or you can add an entry to `/etc/network/interfaces`.

If you plug a USB cable from the Gumstix OTG port to a Linux workstation you
should see something like the following

    scott@octo:~$ tail -f /var/log/syslog
    Aug 13 04:21:23 octo kernel: [ 2724.657061] usb 1-2: new high-speed USB device number 4 using ehci-pci
    Aug 13 04:21:23 octo kernel: [ 2724.791895] usb 1-2: New USB device found, idVendor=0525, idProduct=a4a2
    Aug 13 04:21:23 octo kernel: [ 2724.791899] usb 1-2: New USB device strings: Mfr=1, Product=2, SerialNumber=0
    Aug 13 04:21:23 octo kernel: [ 2724.791901] usb 1-2: Product: RNDIS/Ethernet Gadget
    Aug 13 04:21:23 octo kernel: [ 2724.791903] usb 1-2: Manufacturer: Linux 3.6.11-jumpnow with musb-hdrc
    Aug 13 04:21:23 octo kernel: [ 2724.867155] cdc_ether 1-2:1.0 usb0: register 'cdc_ether' at usb-0000:00:12.2-2, CDC Ethernet Device, 4e:db:41:65:e6:3a
    Aug 13 04:21:23 octo kernel: [ 2724.867182] usbcore: registered new interface driver cdc_ether
    Aug 13 04:21:23 octo kernel: [ 2724.867282] usbcore: registered new interface driver cdc_subset


And you should see a new `usb0` interface on the workstation

    scott@octo:~$ ifconfig usb0
    usb0      Link encap:Ethernet  HWaddr 4e:db:41:65:e6:3a
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

Assign it an IP address on the same subnet

    scott@octo:~$ sudo ifconfig usb0 192.168.20.1

And you should have network connectivity between the two machines.

Here is a *ping* test from the Gumstix

    root@duovero:~# ping 192.168.20.1
    PING 192.168.20.1 (192.168.20.1): 56 data bytes
    64 bytes from 192.168.20.1: seq=0 ttl=64 time=0.641 ms
    64 bytes from 192.168.20.1: seq=1 ttl=64 time=0.641 ms
    ^C
    --- 192.168.20.1 ping statistics ---
    2 packets transmitted, 2 packets received, 0% packet loss
    round-trip min/avg/max = 0.641/0.641/0.641 ms

And an *ssh* test from the workstation

    scott@octo:~$ ssh root@192.168.20.2
    Warning: Permanently added '192.168.20.2' (ECDSA) to the list of known hosts.
    root@duovero:~#


### USB Serial

