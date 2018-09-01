---
layout: post
title: FreeBSD Duovero I2C - Changing bus speeds
description: "Continued I2C explorations on a FreeBSD Duovero system"
date: 2014-11-18 15:00:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero, i2c, eeprom]
---

There have been some [substantial improvements][commit-274641] to the *I2C* code for FreeBSD on ARM boards.

### 100 kHz is the default

First off, the default *I2C* bus speed is now `100 kHz` for all ARM platforms. This is a much more useful default.


### Changing the bus speed

The code tries to support 3 different speeds: `100 kHz`, `400 kHz` and `1 MHz`.

When you provide a speed, the FreeBSD driver will try to find the speed you asked for or the next highest speed below what you asked for.

Currently I have not been successful getting `1 MHz` to work with the in-tree source code. I've submitted my failed test results in this [bug report][i2c-bug] along with some alternative timing dividers that do work for me if you really need a `1 MHz` speed. No response from the FreeBSD developers on getting this committed though.

The `100 kHz` and `400 kHz` speeds are working just fine on the two different devices I have tried. Those are the common speeds used with *I2C* so this is a good improvement.

You can change the *I2C* bus speed three different ways

1. In the dts file
2. Using [sysctl(8)][sysctl]
3. Using a [loader.conf(5)][loader-conf] file

### 1. Device Tree File
An example using a dts file can be found in this [duovero.dts][duovero-dts].

Here is an excerpt for one of the buses

    ...
    i2c2: i2c@48072000 {
            compatible = "ti,i2c";
            reg = <	0x48072000 0x100 >;
            interrupts = <89>;
            interrupt-parent = <&GIC>;
            i2c-device-id = <2>;
            clock-frequency = <400000>;
    };
    ...

`clock-frequency` was the new addition to the *i2c* properties.

### 2. sysctl

The *sysctl* option is probably the most convenient method for development.

The *i2c* bus speeds show up under *sysctl* like this

    root@duovero:~ # sysctl -a | grep iicbus | grep frequency
    dev.iicbus.0.frequency: 100000
    dev.iicbus.1.frequency: 400000
    dev.iicbus.2.frequency: 400000
    dev.iicbus.3.frequency: 100000

You can change the speed of a particular bus this way

    root@duovero:~ # sysctl dev.iicbus.2.frequency=100000
    dev.iicbus.2.frequency: 400000 -> 100000

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

### duovero-eeprom

The *Duovero Parlor* board only brings out *I2C2* on the 40-pin header, but there is an *EEPROM* attached to *I2C3* on the *Parlor* board itself. The *EEPROM* part is labelled **AT24CA** on the *Parlor* schematic.

I wrote a small utility [duovero-eeprom][duovero-eeprom] that lets you read and write to the first 256 bytes of this device in 16-byte words. I wasn't sure how to address any more then that. But in practice I don't think I've had a *Gumstix* project where I needed more then a few numbers in the EEPROM.


[commit-274641]: https://svnweb.freebsd.org/base?view=revision&revision=274641
[loader-conf]: http://www.freebsd.org/cgi/man.cgi?query=loader.conf&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[duovero-dts]: https://github.com/scottellis/duovero-freebsd/blob/master/sys/boot/fdt/dts/arm/duovero.dts
[sysctl]: http://www.freebsd.org/cgi/man.cgi?query=sysctl&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[i2c]: http://www.freebsd.org/cgi/man.cgi?query=i2c&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[loader]: http://www.freebsd.org/cgi/man.cgi?query=loader&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[loader-conf]: http://www.freebsd.org/cgi/man.cgi?query=loader.conf&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[duovero-eeprom]: https://github.com/scottellis/duovero-eeprom
[i2c-bug]: http://freebsd.1045724.n5.nabble.com/Bug-195009-New-patch-arm-Use-400-kHz-as-the-default-OMAP4-I2C-bus-speed-td5965161.html
