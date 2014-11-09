---
layout: post
title: FreeBSD Duovero Serial Ports
description: "Working with serial ports on a FreeBSD Duovero system"
date: 2014-11-09 09:00:00
categories: freebsd
tags: [freebsd, gumstix, duovero, serial, uart]
---

With my previous *uart* definitions in *duovero.dts* I was seeing the following identification for the uarts

    root@duovero:~ # dmesg | grep uart
    uart0: <16750 or compatible> mem 0x48020000-0x480203ff irq 106 on simplebus0
    uart0: console (115384,n,8,1)
    uart1: <ns8250> mem 0x4806c000-0x4806c3ff irq 105 on simplebus0


After looking at some code in `sys/dev/uart/uart_dev_ti8250.c` and some of the other *TI* device tree files in `sys/boot/fdt/dts/arm` I made a few changes to the *uart* definitions in my *duovero.dts* file.

In particular I changed the `compatible` property to *"ti,ns16550"* and I added a `uart-device-id` property.

I left *uart1* and *uart4* disabled since they are not accessible using the [Duovero Parlor][duovero-parlor] board that I am using.

And since I still haven't figured out how to change the *console* to be other then the first *uart*, I moved the definition for *uart3* to be first.

The resulting *dts* file is [here][duovero-dts]

And now the output looks better

    root@duovero:~ # dmesg | grep uart
    uart0: <TI UART (16550 compatible)> mem 0x48020000-0x480203ff irq 106 on simplebus0
    uart0: console (115384,n,8,1)
    uart1: <TI UART (16550 compatible)> mem 0x4806c000-0x4806c3ff irq 105 on simplebus0


The device tree dump

    root@duovero:~ # ofwdump -a
    Node 0x38:
      Node 0xb0: aliases
      Node 0x178: memory
      Node 0x1b0: omap4430
        Node 0x214: interrupt-controller@48241000
        Node 0x2b8: omap4_prcm@4a306000
        Node 0x314: pl310@48242000
        Node 0x378: mp_tmr@48240200
        Node 0x410: serial@48020000
        Node 0x4a4: serial@4806a000
        Node 0x550: serial@4806c000
        Node 0x5e4: serial@4806e000
        Node 0x690: scm@4a100000
        Node 0x8a4: gpio
        Node 0x954: ehci
        Node 0x9fc: i2c@48070000
        Node 0xa6c: i2c@48072000
        Node 0xadc: i2c@48060000
        Node 0xb4c: i2c@48350000
        Node 0xbbc: sdma@x48070000
        Node 0xc28: mmc@x4809C000
      Node 0xcac: chosen

And looking a little closer at *uart3* and *uart2*

    root@duovero:~ # ofwdump -p /omap4430/serial@48020000
    Node 0x410: serial@48020000
      compatible:
        74 69 2c 6e 73 31 36 35 35 30 00
        'ti,ns16550'
      reg:
        48 02 00 00 00 00 04 00
      reg-shift:
        00 00 00 02
      interrupts:
        00 00 00 6a
      interrupt-parent:
        00 00 00 01
      clock-frequency:
        02 dc 6c 00
        '\^B\M-\l'
      uart-device-id:
        00 00 00 02

    root@duovero:~ # ofwdump -p /omap4430/serial@4806c000
    Node 0x550: serial@4806c000
      compatible:
        74 69 2c 6e 73 31 36 35 35 30 00
        'ti,ns16550'
      reg:
        48 06 c0 00 00 00 04 00
      reg-shift:
        00 00 00 02
      interrupts:
        00 00 00 69
      interrupt-parent:
        00 00 00 01
      clock-frequency:
        02 dc 6c 00
        '\^B\M-\l'
      uart-device-id:
        00 00 00 01

I'm not sure why, but there are multiple `/dev` entries for each *uart*.

    root@duovero:~ # ls -l /dev/cu*
    crw-rw----  1 uucp  dialer  0x1f Nov  9 13:11 /dev/cuau0
    crw-rw----  1 uucp  dialer  0x20 Nov  9 13:11 /dev/cuau0.init
    crw-rw----  1 uucp  dialer  0x21 Nov  9 13:11 /dev/cuau0.lock
    crw-rw----  1 uucp  dialer  0x25 Nov  9 13:35 /dev/cuau1
    crw-rw----  1 uucp  dialer  0x26 Nov  9 13:11 /dev/cuau1.init
    crw-rw----  1 uucp  dialer  0x27 Nov  9 13:11 /dev/cuau1.lock

    root@duovero:~ # ls -l /dev/tty*
    crw-------  1 root  tty    0x1c Nov  9 13:51 /dev/ttyu0
    crw-------  1 root  wheel  0x1d Nov  9 13:11 /dev/ttyu0.init
    crw-------  1 root  wheel  0x1e Nov  9 13:11 /dev/ttyu0.lock
    crw-------  1 root  wheel  0x22 Nov  9 13:48 /dev/ttyu1
    crw-------  1 root  wheel  0x23 Nov  9 13:11 /dev/ttyu1.init
    crw-------  1 root  wheel  0x24 Nov  9 13:11 /dev/ttyu1.lock


`/dev/cuau0` and `/dev/ttyu0` reference *uart3* on my system.

`/dev/cuau1` and `/dev/ttyu1` reference *uart2*.

I need to research what the difference is.

But on to a test.

If I jumper `pin 15 (uart2.tx)` and `pin 17 (uart2.rx)` on the *Parlor* expansion header, I can run a simple echo program like [this][serialecho].

    root@duovero:~/serialecho # make
    cc -O2 -Wall serialecho.c -o serialecho

    root@duovero:~/serialecho # ./serialecho -h
    Usage: ./serialecho [-p <port>] [-s <speed>] [-h]
      -p <port>  : default /dev/ttyu1
      -s <speed> : default 115200
      -h         : show this help

    root@duovero:~/serialecho # ./serialecho
    /dev/ttyu1 @ 115200
    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    
    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    
    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz

    ^C

    root@duovero:~/serialecho # ./serialecho -p /dev/cuau1
    /dev/cuau1 @ 115200
    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz

    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    
    Wrote (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz
    Read (62): ABCDEFJHIJKLMNOPQRSTUVWXYZ1234567890abcdefjhijklmnopqrstuvwxyz


Cool!

For reference, *u-boot* is currently handling the pin-muxing of the *uart* pins.


[duovero-dts]: https://github.com/scottellis/duovero-freebsd/blob/master/sys/boot/fdt/dts/arm/duovero.dts
[duovero-parlor]: https://store.gumstix.com/index.php/products/287/
[serialecho]: https://github.com/scottellis/serialecho