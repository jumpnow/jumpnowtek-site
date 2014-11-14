---
layout: post
title: FreeBSD Duovero I2C
description: "Working with I2C on a FreeBSD Duovero system"
date: 2014-11-13 14:17:00
categories: freebsd
tags: [freebsd, gumstix, duovero, i2c]
---

The [Gumstix Duovero][duovero] has 4 I2C buses. 

With the [duovero.dts][duovero-dts] I'm currently using, they show up like this

    root@duovero:~/qdac # ofwdump -a
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

    root@duovero:~/qdac # dmesg | grep iic
    iichb0: <TI I2C Controller> mem 0x48070000-0x480700ff irq 88 on simplebus0
    iichb0: I2C revision 4.0 FIFO size: 16 bytes
    iicbus0: <OFW I2C bus> on iichb0
    iic0: <I2C generic I/O> on iicbus0
    iichb1: <TI I2C Controller> mem 0x48072000-0x480720ff irq 89 on simplebus0
    iichb1: I2C revision 4.0 FIFO size: 16 bytes
    iicbus1: <OFW I2C bus> on iichb1
    iic1: <I2C generic I/O> on iicbus1
    iichb2: <TI I2C Controller> mem 0x48060000-0x480600ff irq 93 on simplebus0
    iichb2: I2C revision 4.0 FIFO size: 16 bytes
    iicbus2: <OFW I2C bus> on iichb2
    iic2: <I2C generic I/O> on iicbus2
    iichb3: <TI I2C Controller> mem 0x48350000-0x483500ff irq 95 on simplebus0
    iichb3: I2C revision 4.0 FIFO size: 16 bytes
    iicbus3: <OFW I2C bus> on iichb3
    iic3: <I2C generic I/O> on iicbus3


The [Duovero Parlor][duovero-parlor] board only brings out one *I2C* bus to the 40-pin header, **I2C2_SCL** and **I2C2_SDA** on pins **12** and **14**.

Because it was already sitting on my desk, the first device I tried was an [MCP4728][mcp4728] 12-Bit 4-channel DAC. I already had a Duovero connected to an [MCP4728 eval board][mcp4728-evalboard] through a [level shifter][level-shifter]. I knew the hardware was working since I'd just written a Linux userland driver for the board for another project. 

I was only looking at porting the *FreeBSD* differences.

*FreeBSD* has a utility program [i2c(8)][i2c] much like the [i2cdetect(8)][i2cdetect] utility for *Linux*. Unfortunately [i2c(8)][i2c] doesn't work with the current *OMAP4* driver for *FreeBSD*. The driver does not support the *ioctls* that [i2c(8)][i2c] wants to use, particularly **I2CSTART**.

The list of *ioctls* a FreeBSD I2C driver ought to support can be found in [iic(4)][iic]. I learned that from this [interesting article][vzaigrin-i2c-ktrace] by [Vadim Zaigrin][vzaigrin] about using [ktrace(4)][ktrace] to debug the *I2C* bus on a Raspberry Pi.


Here's what the [kdump(4)][kdump] output looks like on the Duovero when running this command

    root@duovero:~ # ktrace -t+ i2c -s -f /dev/iic1

[kdump output][kdump-output]
 
The important lines are these repeated failures

    807 i2c      CALL  ioctl(0x3,I2CSTART,0xbffffc30)
    807 i2c      RET   ioctl -1 errno 6 Device not configured

In this case, that's an indication the *ioctl* is not supported.

Looking at the source (`sys/arm/ti/ti_i2c.c`) the *OMAP4* driver does support **I2CRDWR**, so that's what I used.

I got some [code ported][mcp4728-qdac-c] to use the **I2CRDWR** ioctls (see *qdac_write_reg()* and *qdac_read_regs()*), but still no joy communicating.

At this point I had no idea what *FreeBSD* was using for the *I2C* clock. I did know that the *MCP4728* worked at either *100 kHz* or *400 kHz*.

I put an oscope on the `SCL` line and found the clock running at *842 kHz*.

Enabling **DEBUG** in the `sys/arm/ti/ti_i2c.c` driver showed that the communications were timing out waiting for a response. Not unexpected given the unusual clock frequency.  

That *842 kHz* is most likely a mistake. The [iicbus(4)][iicbus] tries to set a default bus speed of **IIC_FASTEST** when it resets *I2C* buses. For the `OMAP4` code, the **IIC_FASTEST** was trying for *1 MHZ*, but the wrong divider values were being used.

For reference, the formula from table 23.8 of the OMAP4 TRM is

    scl = i2c_fclk / ( ( psc + 1) * ( (scll + 7) + (sclh + 5) ) )

I don't think *1 MHz* is a particularly good default either, so I added a [simple patch][default-speed-patch] to make it a more reasonable *400 kHz*. The change does require a kernel rebuild.

Something on my `TODO` list is try and figure out if it's possible to change the *I2C* bus speed from userland. I think I see how to do it from a kernel driver, but that's more then I want to try just yet. It would also be nice to be able to set the default `<clock-speed>` from a *dts* file. Another `TODO`.

After rebuilding the kernel, the [qdac][qdac] program worked just fine. You can see some sample output in the repository `README`. 

The changes are actually pretty minor between the *FreeBSD* and *Linux* versions. I could just `ifdef` them and have one [qdac][qdac] codebase, but I was too lazy today.


[duovero]: https://store.gumstix.com/index.php/category/43/
[duovero-dts]: https://github.com/scottellis/duovero-freebsd/blob/master/sys/boot/fdt/dts/arm/duovero.dts
[default-speed-patch]: https://github.com/scottellis/duovero-freebsd/blob/master/patches/omap4-i2c-default-speed.patch
[duovero-parlor]: https://store.gumstix.com/index.php/products/287/
[i2c]: http://www.freebsd.org/cgi/man.cgi?query=i2c&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[i2cdetect]: http://linux.die.net/man/8/i2cdetect
[iic]: http://www.freebsd.org/cgi/man.cgi?query=iic&sektion=4&apropos=0&manpath=FreeBSD+11-current
[vzaigrin-i2c-ktrace]: http://vzaigrin.wordpress.com/2014/04/28/working-with-i2c-in-freebsd-on-raspberry-pi/
[vzaigrin]: http://vzaigrin.wordpress.com/
[ktrace]: http://www.freebsd.org/cgi/man.cgi?query=ktrace&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html
[kdump]: http://www.freebsd.org/cgi/man.cgi?query=kdump&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html
[kdump-output]: https://gist.github.com/scottellis/460c0bb15871a9ff3843
[mcp4728-qdac-c]: https://github.com/scottellis/qdac/blob/master/mcp4728-qdac.c
[qdac]: https://github.com/scottellis/qdac
[mcp4728]: http://ww1.microchip.com/downloads/en/DeviceDoc/22187E.pdf
[mcp4728-evalboard]: http://www.digikey.com/product-search/en/programmers-development-systems/evaluation-boards-digital-to-analog-converters-dacs/2622540?k=mcp4728
[iicbus]: http://www.freebsd.org/cgi/man.cgi?query=iicbus&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html
[level-shifter]: https://www.sparkfun.com/products/12009