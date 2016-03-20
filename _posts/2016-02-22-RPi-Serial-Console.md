---
layout: post
title: Raspberry Pi Serial Console
date: 2016-03-20 12:40:00
categories: rpi
tags: [linux, rpi, serial, console]
---

I'm using [SparkFun FTDI Basic Breakout - 3.3V][sparkfun-ftdi-basic] boards to convert the RPi TTL serial lines to a USB serial connection for the PC.

For an [RPi2 Model B][rpi2-b], the pin connections are

    FTDI Breakout    RPi2 Header
    GND              06 GND
    RXI              08 TXD0
    TXO              10 RXD0

Using an [RPi Compute Module][rpi-compute], the pin connections are

	FTDI Breakout    RPi Compute Module Dev Kit Header
	GND              GND (any)
    RXI              14 TXD0
    TXO              15 RXD0

    
The serial parameters are `1152008N1` with no flow control.

For the [RPi3 Model B][rpi3-b] **UART0** is normally used for the onboard *BlueTooth* radio.

If you would rather use the **UART0** pins on the header for a serial console, you can disable the *BlueTooth* usage with a device tree overlay.

Append this to your `config.txt`

    dtoverlay=pi3-disable-bt-overlay.dtb



[sparkfun-ftdi-basic]: https://www.sparkfun.com/products/9873
[rpi-compute]: https://www.raspberrypi.org/products/compute-module/
[rpi2-b]: https://www.raspberrypi.org/products/raspberry-pi-2-model-b/
[rpi3-b]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/