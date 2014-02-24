---
layout: post
title: Duovero Access Point
date: 2014-01-14 20:44:00
categories: gumstix duovero
tags: [gumstix, duovero, linux, wifi, access point, hostap]
---

The [Gumstix Duovero Zephyr][gumstix-duovero] come with a built-in 
Wifi/Bluetooth radio. The radio supports AP mode of operation.

The Zephyr uses a Marvell SD8787 radio attached to the SDIO bus.

The **mwifiex** and **mwifiex_sdio** modules are available in Linux 3.6 which
is the default kernel for the Duovero boards.

The Marvell drivers require the **sd8787_uapsta.bin** binary firmware.

When you boot a Duovero with these drivers included you'll get two wireless
interfaces, **mlan0** and **uap0**.

The **mlan0** interface is used for client (managed and ad-hoc) connections.

The **uap0** interface is used for AP mode.
 

The system should look something like this running on a 
[Gumstix Parlor][gumstix-parlor] expansion board

    root@duovero:~# ifconfig -a
    eth0  Link encap:Ethernet  HWaddr 00:15:C9:28:F8:95
          inet addr:192.168.10.115  Bcast:192.168.10.255  Mask:255.255.255.0
          inet6 addr: fe80::215:c9ff:fe28:f895/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:103091 errors:0 dropped:2 overruns:0 frame:0
          TX packets:5352 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:12879802 (12.2 MiB)  TX bytes:564902 (551.6 KiB)
          Interrupt:204

    lo    Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          inet6 addr: ::1/128 Scope:Host
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:37 errors:0 dropped:0 overruns:0 frame:0
          TX packets:37 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:11880 (11.6 KiB)  TX bytes:11880 (11.6 KiB)

    mlan0 Link encap:Ethernet  HWaddr 00:19:88:24:FB:9C
          BROADCAST MULTICAST  MTU:1500  Metric:1
          RX packets:0 errors:0 dropped:0 overruns:0 frame:0
          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

    uap0  Link encap:Ethernet  HWaddr 00:19:88:24:FB:9C
          inet addr:192.168.40.1  Bcast:192.168.40.255  Mask:255.255.255.0
          inet6 addr: fe80::219:88ff:fe24:fb9c/64 Scope:Link
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:587 errors:0 dropped:0 overruns:0 frame:0
          TX packets:539 errors:25 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:152279 (148.7 KiB)  TX bytes:84038 (82.0 KiB)


You can check the firmware version by looking at the boot log

    root@duovero:~# dmesg | grep mwifiex
    [    4.902313] mwifiex_sdio mmc1:0001:1: WLAN FW is active
    [    5.193237] mwifiex_sdio mmc1:0001:1: driver_version = mwifiex 1.0 (14.66.9.p96)

 
The **mlan0** interface works like any other **wlan0** interface. At least 
managed mode. I haven't tried ad-hoc mode.

The standard Linux software for access point management is [hostapd][hostapd].
I'm using the [dylan] branch of Yocto to build the Duovero O/S. There is a 
recipe for hostapd v1.0 in the **meta-openembedded** repo called 
**hostap-daemon**, but I couldn't get that version to work with the **uap0** 
interface.

I found [this post][linux-wireless] on the Linux wireless mailing list. If you 
read down through it you'll see that commit 5f32f79 of the hostapd repo was 
reported working with the SD8787 radio on a DreamPlug computer. This was 
**version 2.0** of hostapd.

I built this commit of hostapd directly on the Duovero and it worked.

The commit was from December, 2011 and I really wanted something more recent. 
There have been over 2500 commits to the hostpad repo since 2011.

I tried the tip of the [hostapd repo][cgit-hostap] but no joy. After a bit of 
bisecting, commit [a6cc060][a6cc060], also from December 2011, turned out to be
the problem. The change seems targeted at **ath6k1** hardware, but is treated as
fatal if any driver like the Marvell driver does not support it. I don't have an
**ath6k1** device for testing.

I backed out the change and built hostapd from the tip of the [master] branch
and hostapd was working again on the Duovero.
 

You can find a bitbake recipe for hostap v2.0 with [patch here][hostapd-patch].

If you want a full Duovero rootfs image recipe, you can use this
[pansenti-ap-image.bb][pansenti-ap-image]. It includes some useful AP tools like
a **dhcp server**, **iptables** and the **bridge-utils8** package.


If you just want to try out some binaries, you can find them at 
[pansenti.com/duovero-ap][duovero-ap].


Make sure to grab the interfaces file for **/etc/network/interfaces**. That sets
up **uap0** with a static interface. By default **uap0** will come up as 
**192.168.40.1**, run the AP and a dhcp server will give out addresses in the **192.168.40.100-120** range.

    ssid: duovero-test
    wpa_pass: duovero-pass

**eth0** wants to be a dhcp client on the LAN.

If you connect to the AP with a client you should get an IP and then be able to
ssh into the Duovero.


I enabled some basic **netfilter** modules in the kernel, so I could do a basic
NAT router test

    root@duovero:~# sysctl -w net.ipv4.ip_forward=1
    root@duovero:~# modprobe iptable_nat
    root@duovero:~# iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    root@duovero:~# iptables -A FORWARD -i uap0 -j ACCEPT

After that a laptop using the Duovero AP was able to ping hosts on the lan that
the Duovero was connected to through the **eth0** interface. So that seems to be
working.

The dhcp server is not providing a DNS server to clients. Edit 
**/etc/dhcpd.conf** if you want to change that.

I connected some more clients to the Duovero AP. They could all communicate fine
with the AP, but they could not talk to each other. This is probably intentional
[wireless client isolation][wireless-isolation] by the mwifiex driver or Marvell
firmware. Some additional routing would need to be done by the Duovero in order
to support client-to-client communication.

More work needs to be done on the startup scripts and firewall to have a proper
routing AP out of the box, but I think most of the tools are there.


[gumstix-duovero]: https://store.gumstix.com/index.php/products/355/
[gumstix-parlor]: https://store.gumstix.com/index.php/products/287/
[hostapd]: http://wireless.kernel.org/en/users/Documentation/hostapd
[linux-wireless]: http://comments.gmane.org/gmane.linux.kernel.wireless.general/92215
[cgit-hostap]: http://w1.fi/cgit/hostap/
[a6cc060]: http://w1.fi/cgit/hostap/commit/?id=a6cc0602dd62f4b2ea02556ddcfd6baf9cd6289d
[hostapd-patch]: https://github.com/Pansenti/meta-pansenti/tree/master/recipes-connectivity/hostapd
[pansenti-ap-image]: https://github.com/Pansenti/meta-pansenti/blob/master/recipes-pansenti/images/pansenti-ap-image.bb
[duovero-ap]: http://pansenti.com/duovero-ap/
[wireless-isolation]: http://www.wirelessisolation.com/