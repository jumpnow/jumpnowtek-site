---
layout: post
title: Duovero Access Point
date: 2015-06-25 11:00:00
categories: gumstix-linux
tags: [gumstix, duovero, linux, wifi, access point, hostap]
---

These instructions are based on a system running a `4.1` Linux kernel built from the sources described in this [Building Duovero Systems with Yocto][yocto-duovero] post.

The [Gumstix Duovero Zephyr][gumstix-duovero] come with a built-in combination `wifi/bluetooth` radio.

The wifi radio supports operating as an *access point*.

The *Duovero Zephyr* uses a Marvell SD8787 radio attached to the SDIO bus.

The `mwifiex` and `mwifiex_sdio` are the kernel modules needed.

The Marvell drivers also require the `sd8787_uapsta.bin` binary firmware.

When you boot the Duovero you'll get a single wireless interface `mlan0` that can be used as a *managed* or *ad-hoc* client.

The system will look something like this running on a [Gumstix Parlor][gumstix-parlor] expansion board

    root@duovero:~# ifconfig -a
    eth0      Link encap:Ethernet  HWaddr 00:15:C9:28:F8:95
              inet addr:192.168.10.102  Bcast:192.168.10.255  Mask:255.255.255.0
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:6896 errors:0 dropped:18 overruns:0 frame:0
              TX packets:3906 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:4009505 (3.8 MiB)  TX bytes:415290 (405.5 KiB)
              Interrupt:71

    lo        Link encap:Local Loopback
              inet addr:127.0.0.1  Mask:255.0.0.0
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:0
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)

    mlan0     Link encap:Ethernet  HWaddr 00:19:88:24:FB:9C
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)


You can check the Marvell firmware version by looking at the boot log

    root@duovero:~# dmesg | grep mwifiex
    [    4.902313] mwifiex_sdio mmc1:0001:1: WLAN FW is active
    [    5.193237] mwifiex_sdio mmc1:0001:1: driver_version = mwifiex 1.0 (14.66.9.p96)

To enable an *access point* interface called `uap0` run the following command

    root@duovero:~# iw phy0 interface add uap0 type __ap

The following interface will then show up

    uap0      Link encap:Ethernet  HWaddr 00:19:88:24:FB:9C
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:30461 errors:0 dropped:0 overruns:0 frame:0
              TX packets:52523 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000
              RX bytes:2310017 (2.2 MiB)  TX bytes:78326100 (74.6 MiB)


The standard Linux software for access point management is [hostapd][hostapd].

There is a recipe for *hostapd v2.3* called *hostap-daemon* in the [meta-duovero][meta-duovero] layer. One [patch][a6cc060] was backed out to get it to work with the Duovero.

You can find the recipe with [patch here][hostapd-patch].

The *hostap-daemon* init script (`/etc/init.d/hostapd`) handles bringing up the `uap0` interface and running `ifup uap0` to assign an IP address before starting the *hostapd* daemon.

If you want a full Duovero rootfs image recipe, you can use this [console-image.bb][console-image]. It includes some useful AP tools like a *dhcp server* and the *iptables* utility.

If you just want to try out some binaries, you can find them at [jumpnowtek.com/downloads/duovero/fido][duovero-binaries].

### Configuration

You will need to customize a few configuration files for your own use.

#### uap0 - /etc/network/interfaces

In `/etc/network/interfaces`, the `uap0` interface is given a default IP address of `192.168.5.1` that you can change.

    --- /etc/network/interfaces ---
    ...
	### access point interface
	iface uap0 inet static
	       address 192.168.5.1
	       netmask 255.255.255.0

#### hostapd - /etc/hostapd.conf

The `hostapd` configuration file is `/etc/hostapd.conf`. There is a simple `WPA/WPA2` example that you can modify.

    --- /etc/hostapd.conf ---
    interface=uap0
    driver=nl80211
    channel=7
    ssid=duovero
    ignore_broadcast_ssid=0
    wpa=3
    wpa_passphrase=duovero-secret
    rsn_pairwise=CCMP

Replace the values for *ssid* and *wpa_passphrase*. The *wpa_passphrase* has to be at least 8 characters long.

To create an open access point, you could use an even simpler configuration like this

    --- /etc/hostapd.conf ---
    interface=uap0
    driver=nl80211
    channel=7
    ssid=duovero

An explanation for all of the *hostapd.conf* options can be found here - [hostapd.conf][hostapd-conf].

#### hostapd - /etc/default/hostapd

You also need to enable the *hostapd* daemon in the `/etc/default/hostapd` configuration file.

    --- /etc/default/hostapd ---
	HOSTAPD_ENABLE=yes


Change the `HOSTAPD_ENABLE` value to **yes**.

#### dhcpd - /etc/dhcp/dhcpd.conf

You probably want the *access point* to give out *dhcp* addresses. There is a dhcp server installed in the *console-image*.

The main configuration file is `/etc/dhcp/dhcpd.conf`. The provided example assumes the `192.168.5.1` address for `uap0`.

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

This example configuration will give out addresses in the range `192.168.5.100 - 192.168.5.120`.

#### dhcpd - /etc/default/dhcp-server

Here you need to specify the interface the *dhcp server* should listen on.

    --- /etc/default/dhcp-server
    INTERFACES="uap0"


After making all of the configuration changes, you can restart the systems manually.

This will stop the applicable services

    root@duovero# /etc/init.d/dhcp-server stop
    root@duovero# /etc/init.d/hostapd stop
	root@duovero# ifdown uap0

This will start the services

    root@duovero# ifup uap0
    root@duovero# /etc/init.d/hostapd start
    root@duovero# /etc/init.d/dhcp-server start


Or you can just reboot.


You should now be able to connect to the Duovero *access point* with a client. You should get an IP address from the *dhcp server*.

From the client you should be able to *ssh* into the *access point* at `192.168.5.1` or whatever address you gave `uap0`.

#### Routing

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

To have this kernel module load at boot you could do this

    root@duovero:~# echo iptable_nat > /etc/modules


Add a basic *NAT routing* rule using the `eth0` interface

    root@duovero:~# iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE


There is a `/etc/init.d/firewall` init script included in the *console-image* that will load the `iptable_nat` kernel module and add the NAT rule to iptables at startup.

To enable the *firewall* script, modify `/etc/default/firewall` and set *FIREWALL_ENABLE* to *yes*.

After that clients using the Duovero AP should be able to see the network that eth0 is attached to and browse the Internet if a valid *nameserver* was given out by the Duovero *dhcp server*.


#### Client Isolation

I connected some more clients to the Duovero AP. They could all communicate fine with the AP, but they could **not** talk to each other.

This is probably intentional [wireless client isolation][wireless-isolation] by the `mwifiex` driver or Marvell firmware. Some additional routing would need to be done by the Duovero in order to support client-to-client communication.

#### Max Clients

A user on the [Gumstix Mailing List][gumstix-mailing-list] posted that 10 clients was the maximum the AP driver was accepting. I have not verified.

#### Summary

This is a pretty simple access point implementation, but it should be enough to get a project started.

[gumstix-duovero]: https://store.gumstix.com/index.php/products/355/
[gumstix-disable-uap-patch]: https://github.com/gumstix/meta-gumstix/commit/d82b49bfbbd4e35271ab928f1217636f86725d95
[gumstix-parlor]: https://store.gumstix.com/index.php/products/287/
[hostapd]: http://wireless.kernel.org/en/users/Documentation/hostapd
[yocto-duovero]: https://jumpnowtek.com/gumstix/duovero/Duovero-Systems-with-Yocto.html
[meta-duovero]: https://github.com/jumpnow/meta-duovero/tree/fido
[linux-wireless]: http://comments.gmane.org/gmane.linux.kernel.wireless.general/92215
[cgit-hostap]: http://w1.fi/cgit/hostap/
[a6cc060]: http://w1.fi/cgit/hostap/commit/?id=a6cc0602dd62f4b2ea02556ddcfd6baf9cd6289d
[hostapd-patch]: https://github.com/jumpnow/meta-duovero/tree/fido/recipes-connectivity/hostapd
[console-image]: https://github.com/jumpnow/meta-duovero/blob/fido/images/console-image.bb
[duovero-binaries]: https://jumpnowtek.com/downloads/duovero/fido
[hostapd-conf]: http://hostap.epitest.fi/cgit/hostap/plain/hostapd/hostapd.conf
[wireless-isolation]: http://www.wirelessisolation.com/
[meta-gumstix]: https://github.com/gumstix/meta-gumstix
[gumstix-mailing-list]: http://gumstix.8.x6.nabble.com/max-clients-supported-with-duovero-zephyr-as-access-point-td4969406.html
