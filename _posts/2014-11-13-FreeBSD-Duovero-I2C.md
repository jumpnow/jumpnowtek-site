---
layout: post
title: FreeBSD Duovero I2C
description: "Working with I2C on a FreeBSD Duovero system"
date: 2014-11-13 14:17:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero, i2c]
---

The [Gumstix Duovero][duovero] has 4 general purpose *I2C* buses. 

There is a 5th *I2C* bus dedicated for use with an external power management unit, a [TWL6030][twl6030] on the *Duovero*.

With the [omap443x.dts][omap443x-dts] I'm currently using, the general purpose *I2C* buses show up like this

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

### Bus speed

The default *I2C* bus speed is `100 kHz` for all ARM platforms.

The *FreeBSD* driver supports 3 different speeds: `100 kHz`, `400 kHz` and `1 MHz`.

When you provide a speed, the FreeBSD driver will try to find the speed you asked for or the next highest speed less then what you asked for.

### Changing the bus speed

You can change the *I2C* bus speed three different ways

1. In the dts file
2. Using [sysctl(8)][sysctl]
3. Using a [loader.conf(5)][loader-conf] file

### 1. Device Tree File

*clock-frequency* is a new *FreeBSD* dts property that can be used to set the initial bus speed.
 
An example can be found in [omap443x.dtsi][omap443x-dtsi]. 

Here is an excerpt for one of the buses

    ...
    i2c2: i2c@48072000 { 
            compatible = "ti,i2c"; 
            reg = <0x48072000 0x100>; 
            interrupts = <89>; 
            i2c-device-id = <2>; 
            clock-frequency = <100000>; 
    }; 
    ...

If *400 kHz* was preferred, it would be

    ...
            clock-frequency = <400000>;
    ...

### 2. sysctl

The *sysctl* option is probably the most convenient method for development.

The *i2c* bus speeds show up under *sysctl* like this

    root@duovero:~ # sysctl -a | grep iicbus | grep frequency
    dev.iicbus.0.frequency: 100000
    dev.iicbus.1.frequency: 100000
    dev.iicbus.2.frequency: 100000
    dev.iicbus.3.frequency: 100000

You can change the speed of a particular bus this way

    root@duovero:~ # sysctl dev.iicbus.2.frequency=400000
    dev.iicbus.2.frequency: 100000 -> 400000

    root@duovero:~/duovero-eeprom # sysctl -a | grep iicbus | grep frequency
    dev.iicbus.0.frequency: 100000
    dev.iicbus.1.frequency: 400000
    dev.iicbus.2.frequency: 100000
    dev.iicbus.3.frequency: 100000

Then you have to **reset** the bus using the [i2c(8)][i2c] utility for it to take effect

    root@duovero:~ # i2c -r -f /dev/iic2
    Resetting I2C controller on /dev/iic2: OK

### 3. loader.conf

Given those two methods, there doesn't seem much need for the [loader.conf(5)][loader-conf] approach. By default, the *loader.conf* framework is not even used on most FreeBSD ARM boards. It adds significantly to the boot time. 

But if you really want to, this is how you could use it.

Enable *loader.conf* functionality by adding a `/boot/loader.rc` file. You can use the example `/boot/loader.rc.sample`.

    root@duovero:~ # cp /boot/loader.rc.sample /boot/loader.rc

Then add a `/boot/loader.conf` file that contains the new i2c bus speed you want. Make sure the value has double-quotes around it.

    root@duovero:~ # cat /boot/loader.conf
    dev.iicbus.2.frequency="400000"

When you reboot the system, the new speed will be in effect.

The [Duovero Parlor][duovero-parlor] board only brings out one *I2C* bus to the 40-pin header, **I2C2_SCL** and **I2C2_SDA** on pins **12** and **14**.

Because it was already sitting on my desk, the first device I tried was an [MCP4728][mcp4728] 12-Bit 4-channel DAC. I already had a Duovero connected to an [MCP4728 eval board][mcp4728-evalboard] through a [level shifter][level-shifter]. I knew the hardware was working since I'd just written a Linux userland driver for the board for another project. 

I was only looking at porting the *FreeBSD* differences.

*FreeBSD* has a utility program [i2c(8)][i2c] much like the [i2cdetect(8)][i2cdetect] utility for *Linux*. Unfortunately [i2c(8)][i2c] doesn't work with the current *OMAP4* driver for *FreeBSD*. The driver does not support the *ioctls* that [i2c(8)][i2c] wants to use, particularly **I2CSTART**.

[iic(4)][iic] shows the *ioctls* a FreeBSD I2C driver should support.

I learned that from this [interesting article][vzaigrin-i2c-ktrace] by [Vadim Zaigrin][vzaigrin] about using [ktrace(1)][ktrace] to debug the *I2C* bus on a Raspberry Pi.


Here's what the [kdump(1)][kdump] output looks like on the Duovero when running this command

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

After rebuilding the kernel, the [qdac][qdac] program worked just fine. You can see some sample output in the repository [README][qdac-readme]. 

The changes are actually pretty minor between the *FreeBSD* and *Linux* versions. I could just `ifdef` them and have one [qdac][qdac] codebase, but I was too lazy today.


[duovero]: https://store.gumstix.com/index.php/category/43/

[duovero-dts]: https://github.com/scottellis/duovero-freebsd/blob/master/sys/boot/fdt/dts/arm/duovero.dts

[omap443x-dtsi]: https://gist.github.com/scottellis/43a18509af1b05ce3565

[default-speed-patch]: https://github.com/scottellis/duovero-freebsd/blob/master/patches/omap4-i2c-default-speed.patch

[duovero-parlor]: https://store.gumstix.com/index.php/products/287/

[i2c]: http://www.freebsd.org/cgi/man.cgi?query=i2c&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html

[i2cdetect]: http://linux.die.net/man/8/i2cdetect

[vzaigrin-i2c-ktrace]: http://vzaigrin.wordpress.com/2014/04/28/working-with-i2c-in-freebsd-on-raspberry-pi/

[vzaigrin]: http://vzaigrin.wordpress.com/

[ktrace]: http://www.freebsd.org/cgi/man.cgi?query=ktrace&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html

[kdump]: http://www.freebsd.org/cgi/man.cgi?query=kdump&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html

[kdump-output]: https://gist.github.com/scottellis/460c0bb15871a9ff3843

[mcp4728-qdac-c]: https://github.com/scottellis/qdac/blob/master/mcp4728-qdac.c

[qdac]: https://github.com/scottellis/qdac

[mcp4728]: http://ww1.microchip.com/downloads/en/DeviceDoc/22187E.pdf

[mcp4728-evalboard]: http://www.digikey.com/product-search/en/programmers-development-systems/evaluation-boards-digital-to-analog-converters-dacs/2622540?k=mcp4728

[iicbus]: http://www.freebsd.org/cgi/man.cgi?query=iicbus&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html

[level-shifter]: https://www.sparkfun.com/products/12009

[qdac-readme]: https://github.com/scottellis/qdac/blob/master/README.md

[twl6030]: http://www.ti.com/product/twl6030

[iic]: http://www.freebsd.org/cgi/man.cgi?query=iic&sektion=4&apropos=0&manpath=FreeBSD+11-current
