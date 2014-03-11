---
layout: post
title: Optimizing GStreamer ffmpegcolorspace for Gumstix webcams
date: 2014-01-14 20:44:00
categories: gumstix overo
tags: [gumstix, overo, gstreamerl webcams, ffmpegcolorspace]
---

If you’ve ever tried piping video from a USB webcam into the Overo DSP for h.264 encoding you know you need a colorspace element between the camera and the TI
encoder due to incompatible formats.

The **ffmpegcolorspace** element is expensive, more so then it seems it ought
to be for the simple transformation required.

- Webcam output: YUY2 (PIX\_FMT\_YUV422)
- TI encoder input: UYVY (PIX\_FMT\_UYVY422)

Here’s what the formats look like

    PIX_FMT_YUV422
    Y0 U0 Y1 V0 | Y2 U1 Y3 V1 | Y4 U2 Y5 V2 | ...
 
    PIX_FMT_UYVY422
    U0 Y0 V0 Y1 | U1 Y2 V1 Y3 | U2 Y4 V2 Y5 | ...

It should be pretty easy.

The inefficiency comes from the ffmpegcolorspace imgconvert.c not having an
explicit custom handler for this particular conversion. So the conversion ends
up going through an intermediate step.


    PIX_FMT_YUV422 -> PIX_FMT_YUV422P -> PIX_FMT_UYVY422

PIX\_FMT\_YUV422P is a planar format that looks like this

    PIX_FMT_YUV422P
    Y0 Y1 Y2 Y3 ...
    U0 U1 ... V0 V1 ...


Adding a [new handler][new-handler] for this specific conversion is pretty easy.

Here are some results, the only difference is the new ffmpegcolorspace handler

The original

    top - 10:12:12 up 17 min, 2 users, load average: 0.42, 0.51, 0.38
    Tasks: 64 total, 1 running, 63 sleeping, 0 stopped, 0 zombie
    Cpu(s): 49.2%us, 9.2%sy, 0.0%ni, 41.5%id, 0.0%wa, 0.0%hi, 0.0%si, 0.0%st
    Mem: 478060k total, 60836k used, 417224k free, 2244k buffers
    Swap: 0k total, 0k used, 0k free, 39172k cached
    ...

The new colorspace handler

    top - 09:51:38 up 25 min, 2 users, load average: 0.31, 0.36, 0.31
    Tasks: 64 total, 1 running, 63 sleeping, 0 stopped, 0 zombie
    Cpu(s): 32.2%us, 11.2%sy, 0.0%ni, 56.7%id, 0.0%wa, 0.0%hi, 0.0%si, 0.0%st
    Mem: 478060k total, 43104k used, 434956k free, 1868k buffers
    Swap: 0k total, 0k used, 0k free, 21840k cached
    ...

The load is still pretty high, but it is better then before.

Here is the GStreamer pipeline that is running.

    gst-launch -e v4l2src device=/dev/video7 \
      ! video/x-raw-yuv, width=640, height=480 \
      ! ffmpegcolorspace \
      ! TIVidenc1 codecName=h264enc engineName=codecServer \
      ! rtph264pay pt=96 \
      ! udpsink host=192.168.10.3 port=4000


The patch for gstreamer-0.10 can be found [here][colorspace-repo] as well as
the Yocto recipe append.


[new-handler]: https://github.com/scottellis/colorspace/blob/master/gst/add-yuv422-to-uyvy422-conversion.patch
[colorspace-repo]: https://github.com/scottellis/colorspace/tree/master/gst
