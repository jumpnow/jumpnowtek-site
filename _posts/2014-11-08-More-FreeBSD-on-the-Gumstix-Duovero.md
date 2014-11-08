---
layout: post
title: More FreeBSD on the Gumstix Duovero
description: "More FreeBSD on a Gumstix Duovero"
date: 2014-11-05 06:30:00
categories: freebsd
tags: [freebsd, gumstix, duovero]
---

Continuing to experiment with [FreeBSD and the Duovero][freebsd-duovero], I created the necessary kernel files to define a new *DUOVERO* machine in FreeBSD.

It's really just a copy of the *PANDABOARD* machine at this point, though I did remove the *USB ethernet* that the *Pandaboard* uses since that doesn't exist on the *Duovero*. The *Duovero* has a much better *GPMC* attached *LAN 9221* ethernet controller. 

I did add *i2c2* and *uart2* definitions to the `duovero.dts`. I chose those two devices since they are both exposed on the *Duovero Parlor* board expansion header and I wanted to try programming them with *FreeBSD*.

The kernel booted fine with the changes, but when the system reached *userland* I lost the console. I'm pretty sure this is the Linux equivalent of an `inittab` setting looking for the wrong terminal now that there are two uarts.

So I removed the *UART2* definition temporarily and the system booted fine and I kept console.

The new boot log is [here][duovero-boot-log] showing a *DUOVERO* kernel being used.

And here's the device tree dump

    root@duovero:~ # ofwdump -a
    Node 0x38:
      Node 0xb0: aliases
      Node 0x100: memory
      Node 0x138: omap4430
        Node 0x19c: interrupt-controller@48241000
        Node 0x240: omap4_prcm@4a306000
        Node 0x29c: pl310@48242000
        Node 0x300: mp_tmr@48240200
        Node 0x398: serial@48020000
        Node 0x418: scm@4a100000
        Node 0x62c: gpio
        Node 0x6dc: ehci
        Node 0x784: i2c@x48070000
        Node 0x7f4: i2c@x48072000
        Node 0x864: sdma@x48070000
        Node 0x8d0: mmc@x4809C000
      Node 0x954: chosen

where you can see the *i2c2* controller at `i2c@x48072000`.

Here is the [duovero.dts][duovero-dts] I used (not showing the removed uart2).

Now I need to go figure out how to point the *console* at the right uart in userland...

[freebsd-duovero]: http://www.jumpnowtek.com/freebsd/FreeBSD-on-the-Gumstix-Duovero.html
[duovero-boot-log]: https://gist.github.com/scottellis/0413bd5198b94e74d319
[duovero-dts]: https://github.com/scottellis/duovero-freebsd/blob/master/sys/boot/fdt/dts/arm/duovero.dts

