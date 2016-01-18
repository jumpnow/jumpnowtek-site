---
layout: post
title: A Raspberry Pi Pandora music player
description: "Using an IQAudio Pi-DigiAMP+ and pianobar for a Pandora music player"
date: 2016-01-18 16:53:00
categories: rpi
tags: [linux, rpi, yocto, iqaudio, pianobar, pandora]
---

Here is a minimal [Pandora][pandora] internet radio player using a [Raspberry Pi 2][rpi] with an [IQaudIO Pi-DigiAMP+][digiamp-plus] combination *DAC/AMP* board and using the console-based [pianobar][pianobar] client.

Rasberry Pi boards (not the RPi 2) probably work as well. I just haven't tested one yet.

Support for the DAC board, the kernel drivers and *dts*, are already included in the Linux kernel I am using. The systems are built using [Yocto][yocto] with instruction from [here][rpi-yocto].

All that was needed was

1. A few lines to the [config.txt][config-txt]
2. Turning **ON** `gpio22` to disable mute
3. A simple `alsa.conf` modification to disable a warning.
4. Small tweaks to the *pianobar* recipe from [github.com/strassek/meta-aura][meta-aura]

The gpio mute and alsa.conf changes are included in the `meta-rpi/images/audio-image.bb`.

I didn't use the [meta-aura][meta-aura] layer, but just added my own customized *pianobar* recipe to `meta-rpi`.

For a quick-start on the `config.txt`, rename or copy the sample `meta-rpi/scripts/config.txt-iqaudio-example` to `meta-rpi/scripts/config.txt` and the `copy_boot.sh` script used for SD card preparation will install it for you.

For speakers I'm using a pair of old *Pioneer* 8-ohm speakers from a broken CD player I had laying around. For a non-audiophile like me they are plenty good enough.

I'm sure the DAC board supports better speakers then these.

Make sure to run [alsamixer][alsamixer] once after start-up to enable the analog and digital outputs as described in the [IQaudIO User Guide][iqaudio-pdf].

You can set your [Pandora][pandora] username and password in `/home/root/.config/pianobar/config` to avoid having to enter them every time.

Make sure there is one space before and after the **=** and there are no spaces at the end of the lines. [pianobar][pianobar] is picky about this.

Run `pianobar` from a console without any arguments.

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