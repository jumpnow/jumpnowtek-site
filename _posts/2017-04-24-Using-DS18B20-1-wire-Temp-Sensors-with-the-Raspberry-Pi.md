---
layout: post
title: Using DS18B20 1-wire Temp Sensors with the Raspberry Pi
date: 2017-04-24 20:04:00
categories: rpi
tags: [rpi, ds18b20, temp, one-wire, w1]
---

The [DS18B20][ds18b20] one-wire thermometer is fairly easy to get working with the Raspberry Pi.

The Raspberry Pi doesn't have a dedicated hardware controller for 1-wire devices (some SOCs do), but 1-wire is a very slow bus and it doesn't take much to *bitbang* the communication using a GPIO pin.

Linux has a standard driver to do this called `w1-gpio.ko`.

There is also a `w1-therm.ko` slave driver to handle the specifics of **DS18*20** devices.

Both drivers are enabled as modules in the standard RPi kernels.

The drivers can be loaded by a device tree overlay already provided with the official RPi kernels

    w1-gpio-overlay.dtb

The overlay is the only requirement to use the DS18B20. There is no need for third-party libraries.

I'm testing with [Buildroot][buildroot-rpi] and [Yocto][yocto-rpi] built systems.

Raspbian systems include the `w1-gpio-overlay` and should work the same.


There are a couple of ways to wire the DS18B20 to the RPi. You need to provide slightly different parameters to the w1-gpio overlay depending on the method used.

## Parasitic Powering

##### Wiring

    DS18B20          RPi
    -------          ---
    VDD (red)        GND
    GND (black)      GND
    DQ (yellow)      GPIO  -- 4.7k -- 3.3v


##### config.txt

    dtoverlay=w1-gpio,pullup=1


## Non-Parasitic Powering

##### Wiring

    DS18B20          RPi
    -------          ---
    VDD (red)        3.3v
    GND (black)      GND
    DQ (yellow)      GPIO -- 4.7k -- 3.3v

##### config.txt

    dtoverlay=w1-gpio


The `w1-gpio-overlay` defaults to using **GPIO\_4** for the data pin. That's pin 7 on the header.

To specify a different GPIO pin, add a `gpiopin=<pin>` argument to the dtoverlay line.

For example, to use **GPIO\_22** (pin 15) on a parasitic setup, you would use the following

    dtoverlay=w1-gpio,pullup=1,gpiopin=22


Remember to use the RPi GPIO pin number, not the header pin number.


With the DS18B20 connected and the appropriate dtoverlay statement in `config.txt` you should see the **w1\_gpio**, **w1\_therm** and **wire** drivers loaded

    # lsmod
    Module                  Size  Used by    Not tainted
    ipv6                  405858 24 [permanent]
    w1_therm                6401  0                   <--- this
    brcmfmac              222226  0
    brcmutil                9156  1 brcmfmac
    cfg80211              543594  1 brcmfmac
    rfkill                 20944  1 cfg80211
    bcm2835_gpiomem         3900  0
    w1_gpio                 4818  0                   <--- this
    wire                   32616  2 w1_therm,w1_gpio  <--- this
    cn                      5889  1 wire
    uio_pdrv_genirq         3923  0
    uio                    10332  1 uio_pdrv_genirq
    fixed                   3285  0


The interface to the DS18B20 shows up here

    # ls /sys/bus/w1
    devices            drivers            drivers_autoprobe  drivers_probe      uevent

    # ls /sys/bus/w1/devices
    28-0000071cbc72  w1_bus_master1

The `28-0000071cbc72` directory represents this particular thermometer.

The `28` identifies a DS18B20 device.

The `0000071cbc72` represents the unique device id for this particular thermometer. This allows you to have multiple thermometers on the same data line.

Read the thermometer value by reading from `28-0000071cbc72/w1-slave`

    # cat /sys/bus/w1/devices/28-0000071cbc72/w1_slave
    73 01 4b 46 7f ff 0d 10 41 : crc=41 YES
    73 01 4b 46 7f ff 0d 10 41 t=23187

The second line *t=23187* is the temp in Celsius multiplied by 1000.

Here's a simple python script that will read the temp and convert to Fahrenheit.

    #!/usr/bin/env python3

    import glob

    def celsius_to_fahrenheit(c):
        return (c * 1.8) + 32.0


    def find_devices():
        return glob.glob('/sys/bus/w1/devices/28-*')


    def read_temp(path):
        lines = []

        with open(path + '/w1_slave') as f:
            lines = f.readlines()

        if len(lines) != 2:
            return False, 0

        if lines[0].find('YES') == -1:
            return False, 0

        d = lines[1].strip().split('=')

        if len(d) != 2:
            return False, 0

        return True, int(d[1])


    if __name__ == '__main__':

        devices = find_devices()

        for device in devices:
            valid, raw = read_temp(device)

            if valid:
                c = raw / 1000.0
                f = celsius_to_fahrenheit(c)
                print('%0.2f F' % (f))


[ds18b20]: https://www.maximintegrated.com/en/products/analog/sensors-and-sensor-interface/DS18B20.html#tab1
[buildroot-rpi]: https://jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Buildroot.html
[yocto-rpi]: https://jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
