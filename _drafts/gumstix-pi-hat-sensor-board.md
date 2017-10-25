---
layout: post
title: Working with the Gumstix Pi Hat Sensor Board
date: 2017-04-25 15:28:00
categories: rpi
tags: [linux, gumstix, rpi, sensor board]
---

I recently received a [Gumstix Pi Hat Sensor Board][gumsense-board] for the Raspberry Pi.

The board has the following sensors

* [DS1340][ds1340] RTC with trickle charger, coin-battery holder
* [TMP102][tmp102] temperature sensor
* [MS5611-01BA03][ms5611] barometic pressure sensor
* [LSM303D][lsm303d] 3-axis accelerometer/3-axis compass
* [L3GD20H][l3gd20h] 3-axis gyroscope
* 5-pin UART header for a GPS module
* 4 GPIO push buttons
* 8 GPIO LEDs


## RTC

    device: DS1340
    bus: I2C1 0x68
    driver: rtc-ds1307
    config.txt:
      dtparams=i2c_arm=on 
      dtoverlay=i2c-rtc:ds1307  (trickle not tested)

The device shows up as `/dev/rtc0`.

The standard hwclock scripts work.

## Temperature

    device: TMP102
    bus: I2C1 0x48
    driver: hwmon, tmp102
    config.txt:
      dtparams=i2c_arm=on
      dtoverlay=i2c-sensor:tmp102

The device shows up as `/sys/class/hwmon/hwmon0`

Read from `/sys/class/hwmon/hwmon0/temp1_input` to get Celsius * 1000

A short python test program

    #!/usr/bin/env python3

    def celsius_to_fahrenheit(c):
        return (c * 1.8) + 32.0

    def read_temp(path):
        with open(path + '/temp1_input') as f:
            val = f.readline().strip()

        return int(val)

    if __name__ == '__main__':
 
        raw = read_temp('/sys/class/hwmon/hwmon0')
        c = raw / 1000.0
        f = celsius_to_fahrenheit(c)
        print('%0.2f F' % (f))

## Barometer

    device: MS5611
    bus: SPI0 CS2 (gpio_4)
    driver: iio, ms5611_core, ms5611_spi
    config.txt:
      dtparam=spi=on
      dtoverlay=gumsense-spi (custom for now)

The device shows up under `/sys/bus/iio/devices`

Read from `in_pressure_input` to get pressure. 

## LEDs

There are 8 leds attached to gpio pins.

* gpio_6  - red
* gpio_16 - red
* gpio_18 - yellow
* gpio_20 - yellow
* gpio_21 - green
* gpio_22 - green
* gpio_23 - blue
* gpio_24 - blue

A test script

    #!/bin/sh

    GPIOS='6 16 18 20 21 22 23 24'

    for i in ${GPIOS}; do
        if [ ! -d /sys/class/gpio/gpio${i} ]; then
            echo $i > /sys/class/gpio/export

            if [ ! -d /sys/class/gpio/gpio${i} ]; then
                echo "Error exporting gpio ${i}"
                exit 1
            fi

            echo out > /sys/class/gpio/gpio${i}/direction
            echo 0 > /sys/class/gpio/gpio${i}/value
        fi
    done

    sleep 1

    while true; do
        for i in ${GPIOS}; do
            echo 1 > /sys/class/gpio/gpio${i}/value
            sleep 0.1
        done

        for i in ${GPIOS}; do
            echo 0 > /sys/class/gpio/gpio${i}/value
            sleep 0.1
        done
    done


[gumsense-board]: https://store.gumstix.com/expansion/pi-hat-sensor-board.html
[tmp102]: http://www.ti.com/product/TMP102
[ms5611]: http://www.amsys.info/products/ms5611.htm
[lsm303d]: http://www.st.com/en/mems-and-sensors/lsm303d.html
[l3gd20h]: http://www.st.com/en/mems-and-sensors/l3gd20h.html
[ds1340]: https://www.maximintegrated.com/en/products/digital/real-time-clocks/DS1340.html