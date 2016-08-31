---
layout: post
title: Qt5 and the Raspberry Pi
description: "Using Qt5 with hardware acceleration on the RPi"
date: 2016-08-31 07:36:00
categories: rpi
tags: [rpi, qt5, eglfs, opengl, qml, yocto]
---

Developing hardware-accelerated Qt5 GUI applications for the Raspberry Pi.

With the release of [Qt 5.7][qt-5.7] and the new [Qt Quick Controls 2][qt-quickcontrols-2] combined with the [RPi3s][rpi] and *working* OpenGL drivers it seems like a good time to try out [QML][qml].

I have been developing with [Qt][qt] for about 5 years primarily targeting embedded Linux systems running small touchscreen displays. It's always been [Qt Widgets][qtwidgets] though, so QML is new for me.

A collection of notes follow.

#### Hardware

I am primarily using RPi3s for development though I expect the code to work on any RPi since the underlying GPU is the same.

I am testing with both an official [RPi DSI attached 7" touchscreen][pi-display] and an HDMI 1080p display. 

#### System Software

My development systems are built using [Yocto][yocto].

You can find [instructions here][yocto-jumpnow-build] and [download images here][jumpnow-build-download].

I recommend you build your own images though. Mine only contain packages that seem interesting to me.

On these systems Qt5 has been configured to use the use the [EGLFS platform plugin][qpa-eglfs]. This means only one GUI process at a time, but that's typical for products I help develop.

I usually follow the latest stable branch of Yocto for the different *meta-layers* used to build these systems. Currently that is the `[krogoth]` release, Yocto Project 2.1.1.

The `[krogoth]` branch of [meta-qt5][meta-qt5] is using Qt 5.6 and is also missing some patches that correctly build Qt to use the OpenGL drivers provided by the [RPi userland][rpi-userland] package.

The `[master]` branch of [meta-qt5][meta-qt5] is Qt 5.7 and has the build patches for OpenGL so that's what I'm using. The rest of the system is still `[krogoth]` though.


Here's a sample of what's currently installed on my `qt5-images`

    root@rpi3:~# g++ --version
    g++ (GCC) 5.3.0
    Copyright (C) 2015 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    root@rpi3:~# qmake -v
    QMake version 3.0
    Using Qt version 5.7.0 in /usr/lib

    root@rpi3:~# ls /usr/lib/qt5/plugins/platforms
    libqeglfs.so  libqminimal.so  libqminimalegl.so  libqoffscreen.so

    root@rpi3:~# opkg list-installed | grep -e '^qt' | grep -v mkspecs | grep -v dev
    qt3d - 5.7.0+git0+c3fdb888fb-r0
    qt3d-plugins - 5.7.0+git0+c3fdb888fb-r0
    qt3d-qmlplugins - 5.7.0+git0+c3fdb888fb-r0
    qt5-env - 1.0-r1
    qtbase - 5.7.0+git0+69b43e74d7-r0
    qtbase-plugins - 5.7.0+git0+69b43e74d7-r0
    qtbase-tools - 5.7.0+git0+69b43e74d7-r0
    qtconnectivity - 5.7.0+git0+8755a1f246-r0
    qtconnectivity-qmlplugins - 5.7.0+git0+8755a1f246-r0
    qtdeclarative - 5.7.0+git0+d48b397cc7-r0
    qtdeclarative-plugins - 5.7.0+git0+d48b397cc7-r0
    qtdeclarative-qmlplugins - 5.7.0+git0+d48b397cc7-r0
    qtgraphicaleffects - 5.7.0+git0+d3023be0d8-r0
    qtgraphicaleffects-qmlplugins - 5.7.0+git0+d3023be0d8-r0
    qtlocation - 5.7.0+git0+4e1008b4ac-r0
    qtlocation-plugins - 5.7.0+git0+4e1008b4ac-r0
    qtlocation-qmlplugins - 5.7.0+git0+4e1008b4ac-r0
    qtmultimedia - 5.7.0+git0+1be4f74843-r0
    qtmultimedia-plugins - 5.7.0+git0+1be4f74843-r0
    qtmultimedia-qmlplugins - 5.7.0+git0+1be4f74843-r0
    qtquickcontrols - 5.7.0+git0+37f8b753be-r0
    qtquickcontrols-qmldesigner - 5.7.0+git0+37f8b753be-r0
    qtquickcontrols-qmlplugins - 5.7.0+git0+37f8b753be-r0
    qtquickcontrols2 - 5.7.0+git0+cc0ee8e4f3-r0
    qtquickcontrols2-qmldesigner - 5.7.0+git0+cc0ee8e4f3-r0
    qtquickcontrols2-qmlplugins - 5.7.0+git0+cc0ee8e4f3-r0
    qtvirtualkeyboard - 5.7.0+git0+626e78c966-r0
    qtvirtualkeyboard-plugins - 5.7.0+git0+626e78c966-r0
    qtvirtualkeyboard-qmlplugins - 5.7.0+git0+626e78c966-r0

    root@rpi3:~# opkg list-installed | grep libqt | grep -v mkspecs | grep -v dev
    libqt5charts-qmldesigner - 5.7.0+git0+03a6177a32-r0
    libqt5charts-qmlplugins - 5.7.0+git0+03a6177a32-r0
    libqt5charts5 - 5.7.0+git0+03a6177a32-r0
    libqt5sensors-plugins - 5.7.0+git0+e03c37077e-r0
    libqt5sensors-qmlplugins - 5.7.0+git0+e03c37077e-r0
    libqt5sensors5 - 5.7.0+git0+e03c37077e-r0
    libqt5serialbus-plugins - 5.7.0+git0+88554d068d-r0
    libqt5serialbus5 - 5.7.0+git0+88554d068d-r0
    libqt5serialport5 - 5.7.0+git0+7346857f4f-r0
    libqt5svg-plugins - 5.7.0+git0+64ca369c7e-r0
    libqt5svg5 - 5.7.0+git0+64ca369c7e-r0
    libqt5websockets-qmlplugins - 5.7.0+git0+8d17ddfc2f-r0
    libqt5websockets5 - 5.7.0+git0+8d17ddfc2f-r0
    libqt5xmlpatterns5 - 5.7.0+git0+574d92a43e-r0

That's most of the Qt packages in `meta-qt5`, but not all.


#### Running Qt Apps

The Qt runtime needs to be told which platform plugin to use.

You can use the `-platform eglfs` command line argument or you can set an environment variable **QT\_QPA\_PLATFORM**.

That's what I've done for the `qt5-images`.

    root@rpi3:~# env
    TERM=xterm
    SHELL=/bin/sh
    SSH_CLIENT=192.168.10.4 50720 22
    SSH_TTY=/dev/pts/0
    USER=root
    TITLEBAR=\[\033]0;\u@\h: \w\007\]
    MAIL=/var/mail/root
    PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/usr/bin/qt5
    PWD=/home/root
    EDITOR=vi
    QT_QPA_EGLFS_PHYSICAL_WIDTH=155
    QT_QPA_PLATFORM=eglfs
    PS1=\[\033]0;\u@\h: \w\007\]\u@\h:\w\$
    SHLVL=1
    HOME=/home/root
    LOGNAME=root
    QT_QPA_EGLFS_PHYSICAL_HEIGHT=86
    SSH_CONNECTION=192.168.10.4 50720 192.168.10.101 22
    _=/usr/bin/env

You can see that the PATH has `/usr/bin/qt5` added as well.

The environment customization comes from `/etc/profile.d/qt5-env.sh` which in turn comes from this recipe in the Yocto build

    meta-rpi/recipes-qt/qt5-env/qt5-env.bb

Useful to know if you want to modify it.

I also have **QT\_QPA\_EGLFS\_PHYSICAL\_WIDTH** and **QT\_QPA\_EGLFS\_PHYSICAL\_HEIGHT** set for the RPi 
Touchscreen.

#### Building Qt Apps on the RPi

Native building is the quickest way to get started.

*Git* is installed, so you can pull source from a *Github* repo.

The *qqtest* project is just the default *Qt Quick Controls 2* skeleton app that *Qt Creator 4.0.2* generates 

    root@rpi3:~# git clone https://github.com/scottellis/qqtest.git
    Cloning into 'qqtest'...
    remote: Counting objects: 10, done.
    remote: Compressing objects: 100% (10/10), done.
    remote: Total 10 (delta 0), reused 10 (delta 0), pack-reused 0
    Unpacking objects: 100% (10/10), done.
    Checking connectivity... done.

    root@rpi3:~# cd qqtest/

    root@rpi3:~/qqtest# qmake && make -j4
    Info: creating stash file /home/root/qqtest/.qmake.stash
    g++ -c -pipe -O2 -std=gnu++11 -Wall -W -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -isystem /usr/include/qt5 -isystem /usr/include/qt5/QtQuick -isystem /usr/include/qt5/QtGui -isystem /usr/include/qt5/QtQml -isystem /usr/include/qt5/QtNetwork -isystem /usr/include/qt5/QtCore -I. -I/usr/lib/qt5/mkspecs/linux-g++ -o main.o main.cpp
    /usr/bin/qt5/rcc -name qml qml.qrc -o qrc_qml.cpp
    g++ -c -pipe -O2 -std=gnu++11 -Wall -W -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -isystem /usr/include/qt5 -isystem /usr/include/qt5/QtQuick -isystem /usr/include/qt5/QtGui -isystem /usr/include/qt5/QtQml -isystem /usr/include/qt5/QtNetwork -isystem /usr/include/qt5/QtCore -I. -I/usr/lib/qt5/mkspecs/linux-g++ -o qrc_qml.o qrc_qml.cpp
    g++ -Wl,-O1 -o qqtest main.o qrc_qml.o   -lQt5Quick -L/oe4/rpi/tmp-krogoth/sysroots/raspberrypi2/usr/lib -lQt5Gui -lQt5Qml -lQt5Network -lQt5Core -lGLESv2 -lpthread

    root@rpi3:~/qqtest# ./qqtest
    qml: Button 1 clicked.
    qml: Button 2 clicked.

    ^Croot@rpi3:~/qqtest#


[rpi]: https://www.raspberrypi.org/
[qt]: http://www.qt.io/
[qt-5.7]: http://doc.qt.io/qt-5/index.html
[qt-quickcontrols-2]: http://doc.qt.io/qt-5/qtquickcontrols2-index.html
[qml]: http://doc.qt.io/qt-5/qtqml-index.html
[qtwidgets]: http://doc.qt.io/qt-5/qtwidgets-index.html
[yocto]: https://www.yoctoproject.org/
[yocto-jumpnow-build]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[jumpnow-build-download]: http://www.jumpnowtek.com/downloads/rpi/
[qpa-eglfs]: http://doc.qt.io/qt-5/embedded-linux.html
[meta-qt5]: https://github.com/meta-qt5/meta-qt5
[rpi-userland]: https://github.com/raspberrypi/userland
[pi-display]: https://www.raspberrypi.org/blog/the-eagerly-awaited-raspberry-pi-display/