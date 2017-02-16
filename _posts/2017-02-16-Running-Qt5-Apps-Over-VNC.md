---
layout: post
title: Running Qt5 Apps Over VNC Works Again 
date: 2017-02-16 15:16:00
categories: rpi
tags: [rpi, qt5, vnc, buildroot]
---

The [Buildroot][buildroot] project recently upgraded to [Qt 5.8][qt5.8-release] and with it a new **VNC** [platform plugin][qpa] showed up

    # ls /usr/lib/qt/plugins/platforms/
    libqeglfs.so       libqminimal.so     libqoffscreen.so
    libqlinuxfb.so     libqminimalegl.so  libqvnc.so


For embedded developers not running X11 systems, VNC was something Qt has been missing since the Qt4 days.

To use the VNC plugin either run your app with a `-platform vnc` argument or you can set the **QT\_QPA\_PLATFORM** environment variable like this

    export QT_QPA_PLATFORM=vnc

I haven't found any official Qt documentation on usage.

I did find this github repo [github.com/pigshell/qtbase][pigshell] and at least the size arguments you can pass to the plugin described in that [README][pigshell-readme] work. I didn't try any others.

To test I'm using a small Qt Widgets app [tspress][tspress] that I use for troubleshooting touchscreens.

I ran it like this from the RPi

    # tspress -platform vnc:size=800x480
    QVncServer created on port 5900

On a Fedora 25 workstation, I was using the *TigerVNC Viewer*.
 
On a Windows machine I was using [TightVNC][tightvnc] (only need the client pieces).

I spoke with another developer who told me Ubuntu 16.04's *Remote Desktop Client* is working for him.

The response is a bit sluggish, but this should still be useful especially during development when the real display isn't available or working yet.

[buildroot]: https://buildroot.org/
[qt5.8-release]: http://blog.qt.io/blog/2017/01/23/qt-5-8-released/
[qpa]: http://doc.qt.io/qt-5/embedded-linux.html
[tspress]: https://github.com/scottellis/tspress
[tightvnc]: http://www.tightvnc.com/
[pigshell]: https://github.com/pigshell/qtbase
[pigshell-readme]: https://github.com/pigshell/qtbase/blob/vnc-websocket/README.md