---
layout: post
title: Working with pi-blaster on the RPi
date: 2016-08-11 15:40:00
categories: rpi
tags: [linux, rpi, yocto, pwm]
---

The [pi-blaster][pi-blaster] program allows for generating PWM outputs from select GPIO pins of the RPi.

The upstream version defaults to a PWM signal with a period of 10 ms.

For my particular project, I wanted to drive an [SG-5010][sg-5010] servo and the default 10 ms period is just too fast. The servo motor runs continuously.

Unfortunately there is no command line switch to change the period, but the pi-blaster project [README][pi-blaster] does explain how to modify the PWM period in the source.

I changed the pulse period to 50 ms with the following patch

    diff --git a/pi-blaster.c b/pi-blaster.c
    index 7507651..57d33ce 100644
    --- a/pi-blaster.c
    +++ b/pi-blaster.c
    @@ -107,8 +107,8 @@ static uint8_t pin2gpio[MAX_CHANNELS];
     // will use too much memory bandwidth.  10us is a good value, though you
     // might be ok setting it as low as 2us.
    
    -#define CYCLE_TIME_US  10000
    -#define SAMPLE_US              10
    +#define CYCLE_TIME_US          50000
    +#define SAMPLE_US              50
     #define NUM_SAMPLES            (CYCLE_TIME_US/SAMPLE_US)
     #define NUM_CBS                        (NUM_SAMPLES*2)


Confirming the bug described here [Limits on CYCLE\_TIME\_US vs. SAMPLE\_US][limits-post], I needed to keep the **SAMPLE\_US** at a value where **NUM\_SAMPLES** stays at 1000.

If you prefer to keep the default **CYCLE\_TIME\_US = 10 ms** and **SAMPLE\_US = 10 us** you could remove the *0002* patch from the `pi-blaster_git.bbappend` recipe

    scott@fractal:~/rpi/meta-rpi/recipes-devtools/pi-blaster$ cat pi-blaster_git.bbappend
    FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

    LICENSE = "MIT"
    LIC_FILES_CHKSUM = "file://README.md;beginline=223;endline=247;md5=86d10e4bcf4b4014d306dde7c1d2a80d"

    SRCREV = "d2869cee24903998a6e8baf3387b6238064e874b"
    SRC_URI = "git://github.com/sarfata/pi-blaster \
               file://0001-remove-initscript-lsb-dependency.patch \
               file://0002-Set-period-to-50-ms-and-resolution-to-50-us.patch \
               file://0003-Fix-init.d-start-script-so-args-work.patch \
               file://default \
    "

    PR = "r1"

    do_install_append() {
        install -d ${D}${sysconfdir}/default
        install -m 0664 ${WORKDIR}/default ${D}${sysconfdir}/default/pi-blaster
    }

    FILES_${PN} += "${sysconfdir}"


In my builds, the pi-blaster daemon is disabled by default. 

Set **ENABLED=yes** in `/etc/default/pi-blaster` to enable pi-blaster at boot.

    root@rpi3:~# cat /etc/default/pi-blaster
    # See the project README for possible arguments
    #
    #   https://github.com/sarfata/pi-blaster
    #
    ENABLED="yes"
    VERBOSE="yes"
    DAEMON_ARGS="--pcm --gpio 17"

You can also modify the following file at build time to enable pi-blaster

    meta-rpi/recipes-devtools/pi-blaster/files/default

The **DAEMON\_ARGS** are also set for my particular use case.

See the project pi-blaster [README][pi-blaster] about your options and change the value to suit your needs.

If you are modifying the *default* file in `meta-rpi`, make sure to rebuild pi-blaster afterward.

    bitbake -c cleansstate pi-blaster && bitbake pi-blaster && bitbake <your-image>


When pi-blaster starts you should see the following in the boot output

    ...
    Starting Daemon for PWM control of the Raspberry Pi GPIO pins pi-blaster
    MBox Board Revision: 0xa22082
    DMA Channels Info: 0x7f35, using DMA Channel: 14
    Using hardware:                   PCM
    Number of channels:                 1
    PWM frequency:                  20 Hz
    PWM steps:                       1000
    Maximum period (100  %):      50000us
    Minimum period (0.100%):         50us
    DMA Base:                  0x3f007000
    Initialised, Daemonized, Reading /dev/pi-blaster.
    ...

And to make sure your args made it, check the command line

    root@rpi3:~# ps -ef | grep pi-blaster
    root       318     1  0 14:02 ?        00:00:00 /usr/sbin/pi-blaster --pcm --gpio 17

With my configuration and the pi-blaster daemon running, the following will start a ~1.5 ms servo signal on pin 11 of the RPi3 header (gpio 17).

    root@rpi3:~# echo "17=0.030" > /dev/pi-blaster

Use the following formula

    <desired pulse width> / 50 = <value-to-write>

A 2.5 ms pulse width would be

    2.5 / 50 = 0.5

so

    root@rpi3:~# echo "17=0.050" > /dev/pi-blaster


And the scope verifies a 2.5 ms pulse.

I haven't done extensive testing with pi-blaster, but so far it is working well for my project.

[pi-blaster]: https://github.com/sarfata/pi-blaster
[sg-5010]: https://www.adafruit.com/product/155
[limits-post]: https://github.com/sarfata/pi-blaster/issues/5
