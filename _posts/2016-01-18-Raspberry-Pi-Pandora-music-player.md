---
layout: post
title: A Raspberry Pi Pandora music player
description: "Using an IQAudio Pi-DigiAMP+ and pianobar for a Pandora music player"
date: 2016-01-21 09:00:00
categories: rpi
tags: [linux, rpi, yocto, iqaudio, pianobar, pandora]
---

Here is a minimal [Pandora][pandora] internet radio player using a [Raspberry Pi 2][rpi] with an [IQaudIO Pi-DigiAMP+][digiamp-plus] combination *DAC/AMP* board and using the console-based [pianobar][pianobar] client.

Single core Rasberry Pi boards probably work as well, but I don't have any RPi A+ or B+ boards and the DAC board doesn't fit the old header layout.

Support for the DAC board, the kernel drivers and *dts*, are already included in the Linux kernel I am using. The systems are built using [Yocto][yocto] with instruction from [here][rpi-yocto].

All that was needed was

1. A few lines to the [config.txt][config-txt]
2. Turning **ON** `gpio22` to disable mute
3. A simple `alsa.conf` modification to disable a warning.
4. Small tweaks to the *pianobar* recipe from [github.com/strassek/meta-aura][meta-aura]

The gpio mute and alsa.conf changes are included in the `meta-rpi/images/audio-image.bb`.

I didn't use the [meta-aura][meta-aura] layer, but just added my own customized *pianobar* recipe to `meta-rpi`.

For a quick-start on the `config.txt`, rename or copy the sample `meta-rpi/scripts/config.txt-iqaudio-example` to `meta-rpi/scripts/config.txt`.

The `copy_boot.sh` script used for SD card preparation will install the `config.txt` if it finds one in the directory where it is run.

For speakers I'm using a pair of old *Pioneer* 8-ohm speakers from a broken CD player I had laying around. For a non-audiophile like me they are plenty good enough.

I'm sure the DAC board supports better speakers then these.

After boot, you should see this list of kernel modules loaded

    root@rpi2:~# lsmod
    Module                  Size  Used by
    nfc                    56961  0
    bluetooth             317426  2
    rfkill                 16877  2 nfc,bluetooth
    ipv6                  340552  30
    snd_soc_pcm512x_i2c     2091  1
    evdev                  10250  0
    snd_soc_pcm512x        15525  1 snd_soc_pcm512x_i2c
    regmap_i2c              2668  1 snd_soc_pcm512x_i2c
    snd_soc_iqaudio_dac     2453  0
    snd_soc_bcm2708_i2s     6584  2
    regmap_mmio             3270  1 snd_soc_bcm2708_i2s
    i2c_bcm2708             4928  0
    snd_soc_core          127441  3 snd_soc_pcm512x,snd_soc_iqaudio_dac,snd_soc_bcm2708_i2s
    snd_compress            7547  1 snd_soc_core
    bcm2835_gpiomem         2852  0
    snd_pcm_dmaengine       3227  1 snd_soc_core
    snd_pcm                73316  4 snd_soc_pcm512x,snd_soc_core,snd_soc_iqaudio_dac,snd_pcm_dmaengine
    snd_timer              18168  1 snd_pcm
    snd                    50967  4 snd_soc_core,snd_timer,snd_pcm,snd_compress
    uio_pdrv_genirq         2944  0
    uio                     8032  1 uio_pdrv_genirq

And you should see `gpio22` exported as an output with the value high to disable mute.

    root@rpi2:~# ls /sys/class/gpio
    export  gpio22  gpiochip0  unexport

    root@rpi2:~# cat /sys/class/gpio/gpio22/direction
    out

    root@rpi2:~# cat /sys/class/gpio/gpio22/value
    1

Here are the devices `alsa` sees

    root@rpi2:~# aplay -l
    **** List of PLAYBACK Hardware Devices ****
    card 0: IQaudIODAC [IQaudIODAC], device 0: IQaudIO DAC HiFi pcm512x-hifi-0 []
      Subdevices: 1/1
      Subdevice #0: subdevice #0


    root@rpi2:~# aplay -L
    null
        Discard all samples (playback) or generate zero samples (capture)
    default:CARD=IQaudIODAC
        IQaudIODAC,
        Default Audio Device
    sysdefault:CARD=IQaudIODAC
        IQaudIODAC,
        Default Audio Device
    front:CARD=IQaudIODAC
        IQaudIODAC,
        Default Audio Device

Make sure to run [alsamixer][alsamixer] once after start-up to enable the analog and digital outputs as described in the [IQaudIO User Guide][iqaudio-pdf]. If you don't the digital output will default to the the maximum level which is too much for my speakers.

    root@rpi2:~# alsamixer 

You can set your [Pandora][pandora] username and password in `/home/root/.config/pianobar/config` to avoid having to enter them every time.

Make sure there is one space before and after the **=** and there are no spaces at the end of the lines. [pianobar][pianobar] is picky about this.

Run `pianobar` from a console without any arguments.

    root@rpi2:# pianobar

It should just work.
 
[digiamp-plus]: http://www.iqaudio.co.uk/home/9-pi-digiamp-0712411999650.html
[pianobar]: https://6xq.net/pianobar/
[rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[config-txt]: https://github.com/jumpnow/meta-rpi/blob/jethro/scripts/config.txt-iqaudio-example
[audio-image]: https://github.com/jumpnow/meta-rpi/blob/jethro/images/audio-image.bb
[meta-rpi]: https://github.com/jumpnow/meta-rpi
[pandora]: http://www.pandora.com
[rpi]: https://www.raspberrypi.org/
[iqaudio-pdf]: http://www.iqaudio.com/downloads/IQaudIO.pdf
[alsamixer]: https://en.wikipedia.org/wiki/Alsamixer
[yocto]: https://www.yoctoproject.org
[meta-aura]: https://github.com/strassek/meta-aura