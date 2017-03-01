---
layout: post
title: Using ADS1115 ADCs with Raspberry Pis
description: "Working with TI ADS1015 and ADS1115 ADCs on the RPi"
date: 2017-03-01 11:06:00
categories: rpi
tags: [linux, rpi, ads1115, ads1015, adc]
---

The Texas Instruments [ADS1115][ads1115] is another multi-channel ADC that is easy to work with on the Raspberry Pi. AdaFruit sells a [breakout board][adafruit-ads1115] for the ADS1115.

The RPi 4.9 kernels have the *ads1015.ko* kernel module enabled. 

Here is the help for the module
    
    config SENSORS_ADS1015
            tristate "Texas Instruments ADS1015"
            depends on I2C
            help
              If you say yes here you get support for Texas Instruments
              ADS1015/ADS1115 12/16-bit 4-input ADC device.

              This driver can also be built as a module.  If so, the module
              will be called ads1015.

The ADS1015 and ADS1115 are I2C devices.

A [device tree overlay][rpi-overlays] is necessary to enable and configure the driver for use. 

There are individual overlays for the two ADC chips

* ads1015-overlay.dts
* ads1115-overlay.dts

The two overlays have a similar syntax and usage. I only have an ADS1115 board so I will use that as the example.

Here is the relevant section from the [overlays README][overlays-readme]

    Name:   ads1115
    Info:   Texas Instruments ADS1115 ADC
    Load:   dtoverlay=ads1115,<param>[=<val>]
    Params: addr                    I2C bus address of device. Set based on how the
                                    addr pin is wired. (default=0x48 assumes addr
                                    is pulled to GND)
            cha_enable              Enable virtual channel a.
            cha_cfg                 Set the configuration for virtual channel a.
                                    (default=4 configures this channel for the
                                    voltage at A0 with respect to GND)
            cha_datarate            Set the datarate (samples/sec) for this channel.
                                    (default=7 sets 860 sps)
            cha_gain                Set the gain of the Programmable Gain
                                    Amplifier for this channel. (Default 1 sets the
                                    full scale of the channel to 4.096 Volts)

            Channel parameters can be set for each enabled channel.
            A maximum of 4 channels can be enabled (letters a thru d).
            For more information refer to the device datasheet at:
            http://www.ti.com/lit/ds/symlink/ads1115.pdf


To use I2C on the RPis you need to enable it which you can do with this line in your `config.txt`

    dtparam=i2c_arm=on

The default I2C speed is 100 kHz. You can increase it to 400 kHz like this

    dtparam=i2c_arm_baudrate=400000

Then to use the ads1115-overlay add the following to `config.txt`

    dtoverlay=ads1115

After that you need to provide parameters to the overlay to configure the driver.

Because the parameter names are rather long, I will be putting the overlay parameters on separate lines. (You can keep the params on a single line as long as you don't exceed 80 characters total.)

To enable all 4 channels of the ADC in single-ended mode, add the following

    dtparam=cha_enable
    dtparam=chb_enable
    dtparam=chc_enable
    dtparam=chd_enable

This will use the default programmable gain setting of 4.096V and data sampling rate of 860 samples per second. (The ads1015 kernel module always drives the ADC in single-shot mode.)

If you boot the system with those changes to `config.txt` you will see the following kernel modules 

    root@rpi3:~# lsmod
    Module                  Size  Used by
    ipv6                  408710  26
    joydev                  9988  0
    evdev                  12359  0
    ads1015                 3728  0
    hwmon                  10616  1 ads1015
    brcmfmac              224862  0
    brcmutil                9220  1 brcmfmac
    cfg80211              551440  1 brcmfmac
    rfkill                 21648  1 cfg80211
    bcm2835_gpiomem         3900  0
    i2c_bcm2835             7145  0
    uio_pdrv_genirq         3923  0
    uio                    10396  1 uio_pdrv_genirq
    fixed                   3285  0

The hwmon sysfs interface will show up here

    root@rpi3:~# ls /sys/class/hwmon/hwmon0/device
    driver  hwmon  in4_input  in5_input  in6_input  in7_input  modalias  name  of_node  power  subsystem  uevent


The devices show up as in4\_input - in7\_input because of the default chX\_cfg settings from the ads1115-overlay.

The defaults are

    cha_cfg = 4
    chb_cfg = 5
    chc_cfg = 6
    chd_cfg = 7

The values come from the Config Register, the 3 **MUX** bits 12-14. See the [datasheet][ads1115]. 

Here are the possible **MUX** (chX\_cfg) settings

    0 : AINp = AIN0, AINn = AIN1
    1 : AINp = AIN0, AINn = AIN3
    2 : AINp = AIN1, AINn = AIN3
    3 : AINp = AIN2, AINn = AIN3
    4 : AINp = AIN0, AINn = GND
    5 : AINp = AIN1, AINn = GND
    6 : AINp = AIN2, AINn = GND
    7 : AINp = AIN3, AINn = GND

So for instance if you wanted to use AIN0 and AIN1 in a differential configuration you could have this in your `config.txt`

    dtoverlay=ads1115
    dtparam=cha_enable,cha_cfg=0

You would then see this in sysfs

    root@rpi3:~# ls /sys/class/hwmon/hwmon0/device 
    driver  hwmon  in0_input  modalias  name  of_node  power  subsystem  uevent

The in0\_input would be the differential reading between AIN0 and AIN1.

To read the ADC values, read the inX_input value.

The following script reads the 4 channels configured in single-ended mode

    #!/bin/sh

    while true; do
        for i in 4 5 6 7; do
            echo -n "ch[$i]: "
            cat /sys/class/hwmon/hwmon0/device/in${i}_input
        done
 
        echo ""
        sleep 1
    done

Here's a sample of the script running while varying the same input 0.3V to 3.3V using a rheostat to all 4 channels

    root@rpi3:~# ./poll_ads1115.sh
    ch[4]: 1663
    ch[5]: 1663
    ch[6]: 1664
    ch[7]: 1664

    ch[4]: 1663
    ch[5]: 1664
    ch[6]: 1663
    ch[7]: 1663

    ch[4]: 1633
    ch[5]: 1555
    ch[6]: 1569
    ch[7]: 1570

    ch[4]: 563
    ch[5]: 554
    ch[6]: 535
    ch[7]: 516

    ch[4]: 308
    ch[5]: 308
    ch[6]: 308
    ch[7]: 308

    ch[4]: 482
    ch[5]: 488
    ch[6]: 515
    ch[7]: 549

    ch[4]: 3299
    ch[5]: 3299
    ch[6]: 3301
    ch[7]: 3300

    ch[4]: 3283
    ch[5]: 3282
    ch[6]: 3282
    ch[7]: 3281

    ^C

[ads1115]: https://cdn-shop.adafruit.com/datasheets/ads1115.pdf
[adafruit-ads1115]: https://www.adafruit.com/products/1085
[rpi-overlays]: https://www.raspberrypi.org/documentation/configuration/device-tree.md
[linux-hwmon]: http://lxr.free-electrons.com/source/Documentation/hwmon/sysfs-interface
[overlays-readme]: https://github.com/raspberrypi/linux/blob/rpi-4.9.y/arch/arm/boot/dts/overlays/README