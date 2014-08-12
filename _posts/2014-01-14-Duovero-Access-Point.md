---
layout: post
title: Duovero Access Point
date: 2014-01-14 20:44:00
categories: gumstix duovero
tags: [gumstix, duovero, linux, wifi, access point, hostap]
---

The [Gumstix Duovero Zephyr][gumstix-duovero] come with a built-in combination 
`wifi/bluetooth` radio. 

The wifi radio supports operating as an *access point*.

The *Duovero Zephyr* uses a Marvell SD8787 radio attached to the SDIO bus.

The `mwifiex` and `mwifiex_sdio` modules are available in Linux `3.6` which
is the default kernel for the Duovero boards.

The Marvell drivers require the `sd8787_uapsta.bin` binary firmware.

When you boot a Duovero with these drivers included you'll get two wireless
interfaces, `mlan0` and `uap0`.

The `mlan0` interface is used for client *managed* and *ad-hoc* mode connections.

The `uap0` interface is for *access point* mode.

--- 
#### Note

With [commit d82b49b][gumstix-disable-uap-patch] Gumstix disabled the `uap0`
interface from their Duovero kernels. You will need to remove this patch from
your kernel recipe if you are using [meta-gumstix][meta-gumstix] or you can 
use the [meta-duovero][meta-duovero] layer described below.

---

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
          inet addr:192.168.5.1  Bcast:192.168.5.255  Mask:255.255.255.0
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

 
The standard Linux software for access point management is [hostapd][hostapd].

I'm using the `[dora]` branch of Yocto to build the Duovero system.
[Instructions are here][yocto-duovero]. There is a recipe for *hostapd v1.0* 
in the *meta-openembedded* repo called *hostap-daemon*, but it doesn't work
with the Duovero.

I have new recipe for a more recent *hostapd v2.0* build in the
[meta-duovero][meta-duovero] layer. I did have to back out one [patch][a6cc060]
to the hostapd source to get it to work with the Duovero. 

You can find the recipe with [patch here][hostapd-patch].

If you want a full Duovero rootfs image recipe, you can use this
[console-image.bb][console-image]. It includes some useful AP tools like
a *dhcp server* and the *iptables* utility.

If you just want to try out some binaries, you can find them at 
[jumpnowtek.com/downloads/duovero][duovero-binaries].

### Configuration

You will need to customize a few configuration files for your own use.

#### uap0 - /etc/network/interfaces

In the `/etc/network/interfaces` file, you need to configure the `uap0`
interface. I you uncomment the example already there, `uap0` will have an IP
address of `192.168.5.1`.

    --- /etc/network/interfaces ---
    ...
	### access point interface
	auto uap0
	iface uap0 inet static
	       address 192.168.5.1
	       netmask 255.255.255.0

#### hostapd - /etc/hostapd.conf
 
The `hostapd` configuration file is `/etc/hostapd.conf`. There is a simple
`WPA/WPA2` example that you can modify.

    --- /etc/hostapd.conf ---
    interface=uap0
    driver=nl80211
    channel=7
    ssid=duovero
    ignore_broadcast_ssid=0
    wpa=3
    wpa_passphrase=duovero-secret
    rsn_pairwise=CCMP

Replace the values for *ssid* and *wpa_passphrase*. The *wpa_passphrase* has to
be at least 8 characters long. 

To create an open access point, you could use an even simpler configuration 
like this

    --- /etc/hostapd.conf ---
    interface=uap0
    driver=nl80211
    channel=7
    ssid=duovero

An explanation for all of the *hostapd.conf* options can be found here - 
[hostapd.conf][hostapd-conf].

#### hostapd - /etc/default/hostapd

You also need to enable the *hostapd* daemon in the `/etc/default/hostapd`
configuration file.

    --- /etc/default/hostapd ---
	HOSTAPD_ENABLE=yes


Change the `HOSTAPD_ENABLE` value to **yes**.

#### dhcpd - /etc/dhcp/dhcpd.conf

You probably want the *access point* to give out *dhcp* addresses. There is
a dhcp server installed in the *console-image*. 

The main configuration file is `/etc/dhcp/dhcpd.conf`. The provided example
assumes the `192.168.5.1` address for `uap0`.
 
    --- /etc/dhcp/dhcpd.conf

    ddns-update-style none;
    option domain-name "jumpnow";
    option domain-name-servers 192.168.10.2;

    # make uap0 the gateway for clients
    option routers 192.168.5.1;

    default-lease-time 600;
    max-lease-time 7200;
    authoritative;

    subnet 192.168.5.0 netmask 255.255.255.0 {
        range 192.168.5.100 192.168.5.120;
    }

This example configuration will give out addresses in the range
`192.168.5.100 - 192.168.5.120`.

#### dhcpd - /etc/default/dhcp-server

Here you need to specify the interface the *dhcp server* should listen on.

    --- /etc/default/dhcp-server
    INTERFACES="uap0"


After making all of the configuration changes, you can restart the systems
manually. 

This will stop the applicable services

    root@duovero# /etc/init.d/dhcp-server stop
    root@duovero# /etc/init.d/hostapd stop
	root@duovero# ifdown uap0

This will start the services

    root@duovero# ifup uap0
    root@duovero# /etc/init.d/hostapd start
    root@duovero# /etc/init.d/dhcp-server start


Or you can just reboot.

 
You should now be able to connect to the Duovero *access point* with a client.
You should get an IP address from the *dhcp server*.

From the client you should be able to *ssh* into the *access point* at 
`192.168.5.1` or whatever address you gave `uap0`.

#### Routing

--- This section is still a work in progress. ---

I enabled some basic *netfilter* modules in the kernel. Enough so that I could
do some basic *NAT* routing

The first thing is to enable packet forwarding in the kernel

    root@duovero:~# sysctl -w net.ipv4.ip_forward=1

To make this permanent uncomment this line in `/etc/sysctl.conf`

    --- /etc/sysctl.conf ---
    ...
    # Uncomment the next line to enable packet forwarding for IPv4
    net.ipv4.ip_forward=1
    ...


Load the `iptable_nat` kernel module
 
    root@duovero:~# modprobe iptable_nat
    [ 2109.500854] ip_tables: (C) 2000-2006 Netfilter Core Team
    [ 2109.516845] nf_conntrack version 0.5.0 (15836 buckets, 63344 max)

To have this kernel module load at boot

    root@duovero:~# echo iptable_nat > /etc/modules


Add a basic *NAT routing* rule using the `eth0` interface

    root@duovero:~# iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


After that clients using the Duovero AP should be able to see the network
that eth0 is attached to and browse the Internet if a valid *nameserver* was
given out by the Duovero *dhcp server*.


TODO: Add a script to load firewall rules at startup

#### Client isolation

I connected some more clients to the Duovero AP. They could all communicate fine
with the AP, but they could **not** talk to each other. 

This is probably intentional [wireless client isolation][wireless-isolation] by
the `mwifiex` driver or Marvell firmware. Some additional routing would need to
be done by the Duovero in order to support client-to-client communication.

#### Summary

This is a pretty simple access point implementation, but it should be enough
to get a project started.

[gumstix-duovero]: https://store.gumstix.com/index.php/products/355/
[gumstix-disable-uap-patch]: https://github.com/gumstix/meta-gumstix/commit/d82b49bfbbd4e35271ab928f1217636f86725d95
[gumstix-parlor]: https://store.gumstix.com/index.php/products/287/
[hostapd]: http://wireless.kernel.org/en/users/Documentation/hostapd
[yocto-duovero]: http://www.jumpnowtek.com/gumstix/duovero/Duovero-Systems-with-Yocto.html
[meta-duovero]: https://github.com/jumpnow/meta-duovero/tree/dora
[linux-wireless]: http://comments.gmane.org/gmane.linux.kernel.wireless.general/92215
[cgit-hostap]: http://w1.fi/cgit/hostap/
[a6cc060]: http://w1.fi/cgit/hostap/commit/?id=a6cc0602dd62f4b2ea02556ddcfd6baf9cd6289d
[hostapd-patch]: https://github.com/jumpnow/meta-duovero/tree/dora/recipes-connectivity/hostapd
[console-image]: https://github.com/jumpnow/meta-duovero/blob/dora/images/console-image.bb
[duovero-binaries]: http://jumpnowtek.com/downloads/duovero/
[hostapd-conf]: http://hostap.epitest.fi/cgit/hostap/plain/hostapd/hostapd.conf
[wireless-isolation]: http://www.wirelessisolation.com/
[meta-gumstix]: https://github.com/gumstix/meta-gumstix

