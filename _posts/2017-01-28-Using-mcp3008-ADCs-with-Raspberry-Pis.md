---
layout: post
title: Using MCP3008 ADCs with Raspberry Pis
description: "Working with Microchip MCP3008 ADCs on the RPi"
date: 2017-01-31 08:54:00
categories: rpi
tags: [linux, rpi, mcp3008, adc]
---

The [Microchip MCP3008][mcp3008] is a popular ADC for use in a Raspberry Pi projects. You can get them from [Adafruit][adafruit-mcp3008].

They are SPI devices requiring 4 pins to the RPi (MOSI, MISO, CLK and CS).

A [Linux IIO][linux-iio] device driver for these chips exists `drivers/iio/adc/mcp320x.c` and is enabled as a loadable module in the default Raspberry Pi kernels (**CONFIG\_MCP320X**).

Here's the relevant `Kconfig` block

    config MCP320X
            tristate "Microchip Technology MCP3x01/02/04/08"
            depends on SPI
            help
              Say yes here to build support for Microchip Technology's
              MCP3001, MCP3002, MCP3004, MCP3008, MCP3201, MCP3202, MCP3204,
              MCP3208 or MCP3301 analog to digital converter.

              This driver can also be built as a module. If so, the module will be
              called mcp320x.

So other chips besides the MCP3008 are supported, but I've only tested the MCP3008.

A [device tree overlay][rpi-overlays] is necessary to enable and configure the driver for use with an RPi.

The overlay is called [mcp3008-overlay.dts][mcp3008-overlay].

The help for it in the [overlays README][overlays-README] is a bit cryptic.

    Name:   mcp3008
    Info:   Configures MCP3008 A/D converters
            For devices on spi1 or spi2, the interfaces should be enabled
            with one of the spi1-1/2/3cs and/or spi2-1/2/3cs overlays.
    Load:   dtoverlay=mcp3008,<param>[=<val>]
    Params: spi<n>-<m>-present      boolean, configure device at spi<n>, cs<m>
            spi<n>-<m>-speed        integer, set the spi bus speed for this device


The overlay takes advantage of the RPi DTS extension that allows parameters to be passed to a DTS when it's loaded.

For this overlay, the two available parameters are for telling the driver the SPI bus and CS line where the MCP3008 is attached (mandatory) and the speed you want the SPI clock to run (optional, defaults to 1MHz).

To use SPI on the RPis you need to enable it which you can do with this line in your `config.txt`

    dtparam=spi=on

SPI bus 0 is always enabled in the main DTBs for the RPis and so doesn't need any additional help.

The SPI0 pins are

* MOSI : GPIO\_10
* MISO : GPIO\_9
* CLK : GPIO\_11
* CE0 : GPIO\_8
* CE1 : GPIO\_7


Here are some SPI0 examples

**SPI0.0, 1MHz clock**

    dtoverlay=mcp3008:spi0-0-present,spi0-0-speed=1000000

**SPI0.0, 3.6Mhz clock**

    dtoverlay=mcp3008:spi0-0-present,spi0-0-speed=3600000

**SPI0.1**

    dtoverlay=mcp3008:spi0-1-present

**SPI0.0 and SPI0.1**

    dtoverlay=mcp3008:spi0-0-present,spi0-1-present


For SPI buses 1 and 2 (CM modules) you need to separately enable the bus.

There are existing overlays available to enable the SPI buses in different configurations. The CS pin or pins used can be overridden with an argument to the overlay.

The SPI1 pins configured by the spi1 overlays are

* MOSI : GPIO\_20
* MISO : GPIO\_19
* CLK : GPIO\_21
* CE0 : GPIO\_18
* CE1 : GPIO\_17
* CE2 : GPIO\_16

Here are some SPI bus 1 examples

**SPI1.0**

    dtoverlay=spi-1cs
    dtoverlay=mcp3008:spi1-0-present

**SPI1.2**

    dtoverlay=spi-1cs:cs0_pin=16
    dtoverlay=mcp3008:spi1-0-present

Note that `spi1-0-present` is used for the mcp3008 overlay argument since this is still the first SPI1 device the kernel finds.

**SPI1.0 and SPI1.1**

    dtoverlay=spi1-2cs
    dtoverlay=mcp3008:spi1-0-present,spi1-1-present


With the mcp3008 overlay loaded you should see the mcp320x driver

    root@rpi3:~# lsmod
    Module                  Size  Used by
    ipv6                  349231  26
    mcp320x                 6136  0
    industrialio           33957  1 mcp320x
    brcmfmac              188704  0
    brcmutil                5789  1 brcmfmac
    cfg80211              437224  1 brcmfmac
    rfkill                 16838  1 cfg80211
    bcm2835_gpiomem         3036  0
    spi_bcm2835             6626  0
    bcm2835_wdt             3225  0
    uio_pdrv_genirq         3164  0
    uio                     8128  1 uio_pdrv_genirq

The mcp320x driver interface is through sysfs.

The first device will be found here `/sys/bus/iio/devices/iio:device0`

Additional devices will be `device1`, `device2`, etc...

    root@rpi3:~# ls /sys/bus/iio/devices/iio\:device0
    dev                       in_voltage2-voltage3_raw  in_voltage5_raw           name
    in_voltage-voltage_scale  in_voltage2_raw           in_voltage6-voltage7_raw  of_node
    in_voltage0-voltage1_raw  in_voltage3_raw           in_voltage6_raw           power
    in_voltage0_raw           in_voltage4-voltage5_raw  in_voltage7_raw           subsystem
    in_voltage1_raw           in_voltage4_raw           in_voltage_scale          uevent


To get the value of channel 0 of the ADC do a read of `in_voltage0_raw`

    root@rpi3:~# cat /sys/bus/iio/devices/iio\:device0/in_voltage0_raw
    514

You could script it with something like this (read channels 0 and 1 every 3 seconds)

    #!/bin/sh

    while true; do
            for i in 0 1; do
                    echo -n "adc[${i}]: "
                    cat /sys/bus/iio/devices/iio:device0/in_voltage${i}_raw
            done

            echo ""
            sleep 3
    done

To go fast you'll probably want to code something.

Here's a little C program you can use for testing [mcp3008-poll][mcp3008-poll].

With the bus running at 3.6 MHz (MCP3008 powered at 5V) I get around 40 KHz sample speed for one channel reads with an RPi3.

    # mcp3008-poll -d0 0

    (use ctrl-c to stop)

    ADC                0
    Read   750001:   380  ^C

    Summary
      Elapsed: 19.09 seconds
        Reads: 750875
         Rate: 39323.67 Hz

The sampling speed scales as you would expect with multiple channels

    # mcp3008-poll -d0 0 1

    (use ctrl-c to stop)

    ADC                0      1
    Read   626001:   380    381  ^C

    Summary
      Elapsed: 31.82 seconds
        Reads: 626293
         Rate: 19680.62 Hz

When using the sysfs interface, remember to either open/close the file handle between reads or reset the file location back to zero before each read.

In C, something like this

    lseek(fd, 0, SEEK_SET)

[mcp3008]: https://cdn-shop.adafruit.com/datasheets/MCP3008.pdf
[adafruit-mcp3008]: https://www.adafruit.com/product/856
[linux-iio]: https://wiki.analog.com/software/linux/docs/iio/iio
[rpi-overlays]: https://www.raspberrypi.org/documentation/configuration/device-tree.md
[mcp3008-overlay]: https://github.com/raspberrypi/linux/blob/rpi-4.4.y/arch/arm/boot/dts/overlays/mcp3008-overlay.dts
[overlays-README]: https://github.com/raspberrypi/linux/blob/rpi-4.4.y/arch/arm/boot/dts/overlays/README
[mcp3008-poll]: https://github.com/scottellis/mcp3008-poll