---
layout: post
title: A Raspberry Pi Pandora music player
description: "Using an IQAudio Pi-DigiAMP+ and pianobar for a Pandora music player"
date: 2016-01-18 16:35:00
categories: rpi
tags: [linux, rpi, yocto, iqaudio, pianobar, pandora]
---

A minimal [Pandora][pandora] internet radio player using a [Raspberry Pi 2][rpi] with an [IQaudIO Pi-DigiAMP+][digiamp-plus] combination *DAC/AMP* board and using the console-based [pianobar][pianobar] client.

Support for this board, kernel drivers and *dts*, are already included in the Linux kernel I am using in the systems built from [Yocto built Raspberry Pi systems][rpi-yocto].

All that was needed was a few new lines to the [config.txt][config-txt], turning **ON** `gpio22` to disable mute and a simple `alsa.conf` modification to disable a warning.

The gpio mute and alsa.conf changes are included in the `meta-rpi/images/audio-image.bb`.

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