---
layout: post
title: Using the Raspberry Pi hardware PWM timers
date: 2016-09-23 11:58:00
categories: rpi
tags: [linux, rpi, yocto, pwm]
---

The Raspberry Pis have two hardware timers capable of generating a PWM signal.

The [README][overlays-readme] in the RPi kernel overlays directory shows pins where the PWM timers are accessible

    ...
    Name:   pwm
    Info:   Configures a single PWM channel
            Legal pin,function combinations for each channel:
              PWM0: 12,4(Alt0) 18,2(Alt5) 40,4(Alt0)            52,5(Alt1)
              PWM1: 13,4(Alt0) 19,2(Alt5) 41,4(Alt0) 45,4(Alt0) 53,5(Alt1)
            N.B.:
              1) Pin 18 is the only one available on all platforms, and
                 it is the one used by the I2S audio interface.
                 Pins 12 and 13 might be better choices on an A+, B+ or Pi2.
              2) The onboard analogue audio output uses both PWM channels.
              3) So be careful mixing audio and PWM.
              4) Currently the clock must have been enabled and configured
                 by other means.
    ...


You can also find this information in the [BCM2835 ARM Peripherals][bcm2835-arm-peripherals-datasheet] datasheet, *Section 9.5 Quick Reference*. 

At the end of *Section 9.5* is this note

* PWM clock source and frequency is controlled in CPRMAN

**CPRMAN** is the *Clock Power Reset MANager*.


There are two PWM overlays in the default 4.4 RPi kernels

* pwm.dtbo
* pwm-2chan.dtbo


The PWM source clock is not normally enabled in **CPRMAN** and as a result those overlays are not immediately useful. PWM devices will show up, but you won't be able to get an output.

There are workarounds, such as playing an audio file before using PWM since audio also uses the PWM clocks and will enable the source clock. But that's not very convenient.

This [mailing list thread][enabling-the-pwm-clock-at-boot] describes a device tree solution to enabling the **BCM2835\_CLOCK\_PWM** in a dts.

Since it's easy enough to do, I added two additional PWM overlays in the `meta-rpi` repository that implement the solution described in that thread.

* pwm-with-clk.dtbo
* pwm-2chan-with-clk.dtbo 

You can find the source for them [here][pwm-dts-src].

Use them the same way you would the standard pwm overlays.

For example to get a hardware timer on GPIO_18 (pin 12) on any RPi, add this to `config.txt`

    dtoverlay=pwm-with-clk

On RPi boards with 40 pin headers, you can get two channels with this overlay

    dtoverlay=pwm-2chan-with-clk

Without arguments, GPIO\_18 is the default pin for PWM0 and GPIO\_19 is the default for PWM1.

Suppose you wanted to use GPIO\_12 for PWM0 and GPIO\_13 for PWM1, then you could provide arguments to the overlay like this

    dtoverlay=pwm-2chan-with-clk,pin=12,func=4,pin2=13,func2=4

When you boot with the pwm overlay loaded, you should see the kernel *pwm\_bcm2835* driver loaded

    root@rpi3:~# lsmod | grep pwm
    pwm_bcm2835             2711  0

It's a standard Linux kernel PWM driver. 

Instructions for using the PWM sysfs interface can be found in the Linux documentation [pwm.txt][pwm-txt].

Here is a quick example with the *pwm-2chan-with-clk* overlay loaded.

    root@rpi3:~# ls /sys/class/pwm
    pwmchip0

    root@rpi3:~# ls /sys/class/pwm/pwmchip0
    device  export  npwm  power  subsystem  uevent  unexport

    root@rpi3:~# cd /sys/class/pwm/pwmchip0

There are two PWM channels available

    root@rpi3:/sys/class/pwm/pwmchip0# cat npwm
    2

Channel 0 is PWM0 and channel 1 is PWM1.

Prior to using a channel you must export it first

    root@rpi3:/sys/class/pwm/pwmchip0# echo 0 > export

That creates a new `pwm0` subdirectory

    root@rpi3:/sys/class/pwm/pwmchip0# ls
    device  export  npwm  power  pwm0  subsystem  uevent  unexport    

    root@rpi3:/sys/class/pwm/pwmchip0# ls pwm0
    duty_cycle  enable  period  polarity  power  uevent

The *period* and *duty_cycle* units are nanoseconds.

Here is a 100 Hz pulse with an 80% duty cycle.

    root@rpi3:/sys/class/pwm/pwmchip0# echo 10000000 > pwm0/period
    root@rpi3:/sys/class/pwm/pwmchip0# echo 8000000 > pwm0/duty_cycle
    root@rpi3:/sys/class/pwm/pwmchip0# echo 1 > pwm0/enable

Here is a servo type signal on PWM1, 20 Hz, 2ms pulse

    root@rpi3:/sys/class/pwm/pwmchip0# echo 1 > export
    root@rpi3:/sys/class/pwm/pwmchip0# echo 50000000 > pwm1/period
    root@rpi3:/sys/class/pwm/pwmchip0# echo 2000000 > pwm1/duty_cycle
    root@rpi3:/sys/class/pwm/pwmchip0# echo 1 > pwm1/enable

You can change the values while the timer is running

    root@rpi3:/sys/class/pwm/pwmchip0# echo 2500000 > pwm1/duty_cycle

The *duty_cycle* should obviously not exceed the *period*.


[overlays-readme]: https://github.com/raspberrypi/linux/blob/rpi-4.4.y/arch/arm/boot/dts/overlays/README
[bcm2835-arm-peripherals-datasheet]: https://www.raspberrypi.org/wp-content/uploads/2012/02/BCM2835-ARM-Peripherals.pdf
[enabling-the-pwm-clock-at-boot]: https://github.com/raspberrypi/linux/issues/1533
[pwm-dts-src]: https://github.com/jumpnow/meta-rpi/tree/krogoth/recipes-kernel/linux/linux-raspberrypi-4.4/dts
[pwm-txt]: https://www.kernel.org/doc/Documentation/pwm.txt