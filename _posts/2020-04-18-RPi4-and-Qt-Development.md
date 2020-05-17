---
layout: post
title: RPi4 and Qt Development
date: 2020-05-17 11:42:00
categories: rpi
tags: [rpi4, qt5, eglfs, opengl, qml, yocto]
---

Some notes on developing Qt GUI applications with 64-bit Raspberry Pi4 systems.

#### Hardware

I am testing with the following displays

* RPi 7" [touchscreen displays][pi-display]
* Standard HDMI displays

I have not tried any of the small TFT displays with the RPi4.

#### System Software

I am using a generic development/test system built with [Yocto][yocto].

You can find [instructions here][yocto-rpi64-build] or [download an image here][jumpnow-build-download].

On these systems Qt defaults to using the [linuxfb platform plugin][qt-embedded].

A glance at the system

    root@rpi4:~# uname -a
    Linux rpi4 5.4.40-v8 #1 SMP PREEMPT Fri May 15 16:20:21 UTC 2020 aarch64 aarch64 aarch64 GNU/Linux

    root@rpi4:~# g++ --version
    g++ (GCC) 9.3.0
    Copyright (C) 2019 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    root@rpi4:~# qmake -v
    QMake version 3.1
    Using Qt version 5.14.1 in /usr/lib

    root@rpi4:~# ls /usr/lib/plugins/platforms
    libqeglfs.so  libqlinuxfb.so  libqminimal.so  libqminimalegl.so  libqoffscreen.so  libqvnc.so

    root@rpi4:~# ls /usr/lib/libQt5*.5.14.1
    /usr/lib/libQt53DAnimation.so.5.14.1
    /usr/lib/libQt53DCore.so.5.14.1
    /usr/lib/libQt53DExtras.so.5.14.1
    /usr/lib/libQt53DInput.so.5.14.1
    /usr/lib/libQt53DLogic.so.5.14.1
    /usr/lib/libQt53DQuick.so.5.14.1
    /usr/lib/libQt53DQuickAnimation.so.5.14.1
    /usr/lib/libQt53DQuickExtras.so.5.14.1
    /usr/lib/libQt53DQuickInput.so.5.14.1
    /usr/lib/libQt53DQuickRender.so.5.14.1
    /usr/lib/libQt53DQuickScene2D.so.5.14.1
    /usr/lib/libQt53DRender.so.5.14.1
    /usr/lib/libQt5Bluetooth.so.5.14.1
    /usr/lib/libQt5Charts.so.5.14.1
    /usr/lib/libQt5Concurrent.so.5.14.1
    /usr/lib/libQt5Core.so.5.14.1
    /usr/lib/libQt5DBus.so.5.14.1
    /usr/lib/libQt5EglFSDeviceIntegration.so.5.14.1
    /usr/lib/libQt5EglFsKmsSupport.so.5.14.1
    /usr/lib/libQt5Gui.so.5.14.1
    /usr/lib/libQt5Location.so.5.14.1
    /usr/lib/libQt5Multimedia.so.5.14.1
    /usr/lib/libQt5MultimediaQuick.so.5.14.1
    /usr/lib/libQt5MultimediaWidgets.so.5.14.1
    /usr/lib/libQt5Network.so.5.14.1
    /usr/lib/libQt5Nfc.so.5.14.1
    /usr/lib/libQt5OpenGL.so.5.14.1
    /usr/lib/libQt5Positioning.so.5.14.1
    /usr/lib/libQt5PositioningQuick.so.5.14.1
    /usr/lib/libQt5PrintSupport.so.5.14.1
    /usr/lib/libQt5Qml.so.5.14.1
    /usr/lib/libQt5QmlModels.so.5.14.1
    /usr/lib/libQt5QmlWorkerScript.so.5.14.1
    /usr/lib/libQt5Quick.so.5.14.1
    /usr/lib/libQt5QuickControls2.so.5.14.1
    /usr/lib/libQt5QuickParticles.so.5.14.1
    /usr/lib/libQt5QuickShapes.so.5.14.1
    /usr/lib/libQt5QuickTemplates2.so.5.14.1
    /usr/lib/libQt5QuickTest.so.5.14.1
    /usr/lib/libQt5QuickWidgets.so.5.14.1
    /usr/lib/libQt5Sensors.so.5.14.1
    /usr/lib/libQt5SerialBus.so.5.14.1
    /usr/lib/libQt5SerialPort.so.5.14.1
    /usr/lib/libQt5Sql.so.5.14.1
    /usr/lib/libQt5Svg.so.5.14.1
    /usr/lib/libQt5Test.so.5.14.1
    /usr/lib/libQt5VirtualKeyboard.so.5.14.1
    /usr/lib/libQt5WebSockets.so.5.14.1
    /usr/lib/libQt5Widgets.so.5.14.1
    /usr/lib/libQt5Xml.so.5.14.1
    /usr/lib/libQt5XmlPatterns.so.5.14.1

That is most but not all of the Qt packages in `meta-qt5`.

A notable exception is `qtwebkit`.

Because of the size and time to build I only include it when needed.

#### Running Qt Apps

The systems I am building do not include a display manager like Xorg or Wayland.

They are designed to run a single GUI process for applications such as an instrument or digital signage. 

The Qt runtime does need to be told which platform plugin to use.

You can provide a `-platform some-plugin` command line argument when starting applications.

Or you can use an environment variable `QT_QPA_PLATFORM` which is what I have done.

    root@rpi4:~# env | grep -i qt
    QT_QPA_PLATFORM=linuxfb


The environment comes from `/etc/profile.d/qt5-env.sh` which in turn comes from this recipe in the Yocto build

    meta-rpi64/recipes-qt/qt5-env/qt5-env.bb

in case you want to change the defaults.

#### Building Qt Apps on the RPi

The RPi4 is powerful enough that native building is convenient.

There are two examples applications already installed

* tspress - a QWidget application 
* qmlswipe - a QML application

You can recompile them directly on the device to verify the tools.

For this example I will build the `qmlswipe` app.

    root@rpi4:~# git clone https://github.com/scottellis/qmlswipe.git
    Cloning into 'qmlswipe'...
    remote: Enumerating objects: 27, done.
    remote: Counting objects: 100% (27/27), done.
    remote: Compressing objects: 100% (17/17), done.
    remote: Total 27 (delta 11), reused 25 (delta 9), pack-reused 0
    Unpacking objects: 100% (27/27), done.

    root@rpi4:~# cd qmlswipe/

    root@rpi4:~/qmlswipe# qmake
    Info: creating stash file /home/root/qmlswipe/.qmake.stash

    root@rpi4:~/qmlswipe# make
    g++ -c -pipe --sysroot= -O2 -std=gnu++11 -Wall -Wextra -D_REENTRANT -fPIC -DQT_DEPRECATED_WARNINGS -DQT_NO_DEBUG -DQT_QUICKCONTROLS2_LIB -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QMLMODELS_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -I/usr/include/QtQuickControls2 -I/usr/include/QtQuick -I/usr/include/QtGui -I/usr/include/QtQmlModels -I/usr/include/QtQml -I/usr/include/QtNetwork -I/usr/include/QtCore -I. -I/usr/lib/mkspecs/linux-g++ -o main.o main.cpp
    /usr/bin/rcc -name qml qml.qrc -o qrc_qml.cpp
    g++ -c -pipe --sysroot= -O2 -std=gnu++11 -Wall -Wextra -D_REENTRANT -fPIC -DQT_DEPRECATED_WARNINGS -DQT_NO_DEBUG -DQT_QUICKCONTROLS2_LIB -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QMLMODELS_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -I/usr/include/QtQuickControls2 -I/usr/include/QtQuick -I/usr/include/QtGui -I/usr/include/QtQmlModels -I/usr/include/QtQml -I/usr/include/QtNetwork -I/usr/include/QtCore -I. -I/usr/lib/mkspecs/linux-g++ -o qrc_qml.o qrc_qml.cpp
    g++ --sysroot= -Wl,-O1 -Wl,-rpath-link,/usr/lib -o qmlswipe main.o qrc_qml.o   /usr/lib/libQt5QuickControls2.so /usr/lib/libQt5Quick.so /usr/lib/libQt5Gui.so /usr/lib/libQt5QmlModels.so /usr/lib/libQt5Qml.so /usr/lib/libQt5Network.so /usr/lib/libQt5Core.so -lGLESv2 -lpthread   

    root@rpi4:~/qmlswipe# ./qmlswipe
    qml: Button 1 clicked
    qml: Button 2 clicked
    qml: Button 1 clicked
    qml: Button 2 clicked
    qml: Exit clicked

<br>

#### Cross-compiling Qt apps from the command line

Yocto can also build a toolchain capable of cross-compiling applications on a more powerful workstation.
 
The Yocto SDK is self-contained and easily installed, but over 1.5GB so I am not hosting it for download.

To build the toolchain, first setup the Yocto environment as normal

    ~$ source poky-dunfell/oe-init-build-env ~/rpi64/build

In `local.conf` specify the host machine architecture where the cross-tools will be used.

The choices are `i686` or `x86_64`.

I am using `SDKMACHINE = "x86_64"`.

Build the SDK like this

    ~/rpi64/build$ bitbake meta-toolchain-qt5

The resulting installation script can be found in `${TMPDIR}/deploy/sdk`.

In my `local.conf` I have `TMPDIR=/oe10/rpi64/tmp-dunfell`, so the SDK installer can be found here

    scott@fractal:~/dunfell-rpi64/build$ ls -l /oe10/rpi64/tmp-dunfell/deploy/sdk
    total 943452
    -rw-r--r-- 1 scott scott     52107 May 17 13:47 poky-glibc-x86_64-meta-toolchain-qt5-aarch64-raspberrypi4-64-toolchain-3.1.host.manifest
    -rwxr-xr-x 1 scott scott 965711652 May 17 13:56 poky-glibc-x86_64-meta-toolchain-qt5-aarch64-raspberrypi4-64-toolchain-3.1.sh
    -rw-r--r-- 1 scott scott     22781 May 17 13:46 poky-glibc-x86_64-meta-toolchain-qt5-aarch64-raspberrypi4-64-toolchain-3.1.target.manifest
    -rw-r--r-- 1 scott scott    297772 May 17 13:46 poky-glibc-x86_64-meta-toolchain-qt5-aarch64-raspberrypi4-64-toolchain-3.1.testdata.json

Run the installer as root (I have not tried a non-root install)

Here I copied the *.sh installer to another machine and ran the script. 

    ~$ sudo ./poky-glibc-x86_64-meta-toolchain-qt5-aarch64-raspberrypi4-64-toolchain-3.1.sh

The default install location is `/opt/poky/<version>`, but the script will ask.

I chose to install it in `/opt/poky/rpi64-3.1`.

To use the SDK, *source* the SDK environment using the provided script

    ~$ source /opt/poky/rpi64-3.1/environment-setup-aarch64-poky-linux


Here I will cross-compile the `tspress` app.
 
    ~$ git clone https://github.com/scottellis/tspress.git
    Cloning into 'tspress'...
    remote: Enumerating objects: 90, done.
    remote: Total 90 (delta 0), reused 0 (delta 0), pack-reused 90
    Unpacking objects: 100% (90/90), done.

    ~$ cd tspress

    ~/tspress$ qmake
    Info: creating stash file /home/scott/tspress/.qmake.stash

    ~/tspress$ make
    aarch64-poky-linux-g++  -mcpu=cortex-a72+crc+crypto -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -c -pipe  -O2 -pipe -g -feliminate-unused-debug-types  --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -O2 -Wall -Wextra -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -I. -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtWidgets -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtGui -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtCore -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/mkspecs/linux-oe-g++ -o Objects/main.o main.cpp
    aarch64-poky-linux-g++  -mcpu=cortex-a72+crc+crypto -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -c -pipe  -O2 -pipe -g -feliminate-unused-debug-types  --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -O2 -Wall -Wextra -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -I. -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtWidgets -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtGui -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtCore -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/mkspecs/linux-oe-g++ -o Objects/tspress.o tspress.cpp
    aarch64-poky-linux-g++  -mcpu=cortex-a72+crc+crypto -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -pipe  -O2 -pipe -g -feliminate-unused-debug-types  --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -O2 -Wall -Wextra -dM -E -o GeneratedFiles/moc_predefs.h /opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/mkspecs/features/data/dummy.cpp
    /opt/poky/rpi64-3.1/sysroots/x86_64-pokysdk-linux/usr/bin/moc -DQT_NO_DEBUG -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB --include /home/scott/qt/tspress/GeneratedFiles/moc_predefs.h -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/mkspecs/linux-oe-g++ -I/home/scott/qt/tspress -I/home/scott/qt/tspress/GeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtWidgets -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtGui -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtCore -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/c++/9.3.0 -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/c++/9.3.0/aarch64-poky-linux -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/c++/9.3.0/backward -I/opt/poky/rpi64-3.1/sysroots/x86_64-pokysdk-linux/usr/lib/aarch64-poky-linux/gcc/aarch64-poky-linux/9.3.0/include -I/opt/poky/rpi64-3.1/sysroots/x86_64-pokysdk-linux/usr/lib/aarch64-poky-linux/gcc/aarch64-poky-linux/9.3.0/include-fixed -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include tspress.h -o GeneratedFiles/moc_tspress.cpp
    aarch64-poky-linux-g++  -mcpu=cortex-a72+crc+crypto -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -c -pipe  -O2 -pipe -g -feliminate-unused-debug-types  --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -O2 -Wall -Wextra -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_WIDGETS_LIB -DQT_GUI_LIB -DQT_CORE_LIB -I. -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtWidgets -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtGui -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/include/QtCore -IGeneratedFiles -I/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/mkspecs/linux-oe-g++ -o Objects/moc_tspress.o GeneratedFiles/moc_tspress.cpp
    aarch64-poky-linux-g++  -mcpu=cortex-a72+crc+crypto -fstack-protector-strong  -D_FORTIFY_SOURCE=2 -Wformat -Wformat-security -Werror=format-security --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -fstack-protector-strong -Wl,-z,relro,-z,now --sysroot=/opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux -Wl,-O1 -o tspress Objects/main.o Objects/tspress.o Objects/moc_tspress.o   /opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/libQt5Widgets.so /opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/libQt5Gui.so /opt/poky/rpi64-3.1/sysroots/aarch64-poky-linux/usr/lib/libQt5Core.so -lGLESv2 -lpthread   


You can check that the resulting executable is for an ARM 64-bit architecture
 
    ~/tspress$ file tspress
    tspress: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, BuildID[sha1]=e848dd21cab0ef2746042fee07bcd63b501b72ee, for GNU/Linux 3.14.0, with debug_info, not stripped

Copy it to the RPi4

    ~/tspress$ scp tspress root@192.168.10.205:/tmp
    Warning: Permanently added '192.168.10.205' (ECDSA) to the list of known hosts.
    tspress              

Then over on the RPi4, the `tspress` app should run fine.


#### Creating Bitbake recipes for your Qt apps

When you have completed development you will want Yocto to build and install your app as part of the system build.

Under the `meta-rpi64/recipes-qt` directory are the recipes for the example applications `qmlswipe` and `tspress`.

You can use either as templates for your own application.

Check the `poky-dunfell/meta-qt5` layer for additional examples.


[rpi]: https://www.raspberrypi.org/
[qt]: http://www.qt.io/
[qt-quickcontrols-2]: http://doc.qt.io/qt-5/qtquickcontrols2-index.html
[qml]: http://doc.qt.io/qt-5/qtqml-index.html
[qtwidgets]: http://doc.qt.io/qt-5/qtwidgets-index.html
[yocto]: https://www.yoctoproject.org/
[yocto-rpi64-build]: https://jumpnowtek.com/rpi/Raspberry-Pi-4-64bit-Systems-with-Yocto.html
[jumpnow-build-download]: https://jumpnowtek.com/downloads/rpi64
[qt-embedded]: http://doc.qt.io/qt-5/embedded-linux.html
[pi-display]: https://www.raspberrypi.org/products/raspberry-pi-touch-display/ 
[yocto-docs]: http://www.yoctoproject.org/docs/2.1/mega-manual/mega-manual.html
