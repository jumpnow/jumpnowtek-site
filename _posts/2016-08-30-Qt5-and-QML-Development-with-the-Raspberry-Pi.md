---
layout: post
title: Qt5 and QML Development with the Raspberry Pi
description: "Using Qt5 with hardware acceleration on the RPi"
date: 2016-09-22 11:41:00
categories: rpi
tags: [rpi, qt5, eglfs, opengl, qml, yocto]
---

Developing hardware-accelerated Qt5 GUI applications for the Raspberry Pi.

With the release of [Qt 5.7][qt-5.7] and the new [Qt Quick Controls 2][qt-quickcontrols-2] combined with the [RPi3s][rpi] and *working* OpenGL drivers it seems like a good time to try out [QML][qml].

I have been developing with [Qt][qt] for about 5 years primarily targeting embedded Linux systems running small touchscreen displays. It's always been [Qt Widgets][qtwidgets] though, so QML is new for me.

A collection of semi-ordered notes follow.

#### Hardware

I am primarily testing with RPi3s, but I expect the code to work on any RPi since the underlying GPU is the same.

I am testing with the following

* The official [RPi 7" touchscreen][pi-display]
* Standard HDMI 1080p displays
* Adafruit [3.5 inch][pitft35r] and [2.8 inch][pitft28r] resistive touchscreen displays

For the PiTFTs I'm using a nice little utility from Andrew Duncan called [raspi2fb][raspi2fb] to get the hardware accelerated graphics (i.e. QML) to show up on the SPI connected touchscreens. The *raspi2fb* utility is installed on all my *meta-rpi* images as are the DTS overlays for using the touchscreens.

TODO: A more detailed write up on the RPi TFTs and *raspi2fb*.

#### System Software

My development systems are built using [Yocto][yocto].

You can find [instructions here][yocto-jumpnow-build] and [download an image here][jumpnow-build-download].

I recommend you build your own images though. The *meta-rpi* images contain only the packages that are interesting to me.

On these systems Qt5 has been configured to use the use the [EGLFS platform plugin][qpa-eglfs]. This means only one full-screen GUI process at a time, but that's fairly typical for the embedded products I work on.

The majority of the system is from the latest stable branch of Yocto, currently 2.1.1, the `[krogoth]` branch.

I am using the `[master]` branch of [meta-qt5][meta-qt5] because it uses Qt 5.7 and has the build patches for OpenGL from the [RPi userland][rpi-userland] package.

Here's a sample of the Qt stuff currently installed on my `qt5-images`

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

You can see that the **PATH** has `/usr/bin/qt5` added as well.

The environment customization comes from `/etc/profile.d/qt5-env.sh` which in turn comes from this recipe in the Yocto build

    meta-rpi/recipes-qt/qt5-env/qt5-env.bb

Useful to know if you want to modify it.

I also have **QT\_QPA\_EGLFS\_PHYSICAL\_WIDTH** and **QT\_QPA\_EGLFS\_PHYSICAL\_HEIGHT** set for the RPi Touchscreen.

Details on the **QPA\_EGLFS** environment variables can be found [here][qpa-eglfs].

#### Building Qt Apps on the RPi

Native building is the quickest way to get started.

*Git* is installed, so you can pull source from a *Github* repo.

The *qqtest* project is just the default *Qt Quick Controls 2* skeleton app that *Qt Creator 4.0.2* generates with an *Exit* button added

    root@rpi3:~# git clone https://github.com/scottellis/qqtest.git
    Cloning into 'qqtest'...
    remote: Counting objects: 17, done.
    remote: Compressing objects: 100% (12/12), done.
    remote: Total 17 (delta 5), reused 17 (delta 5), pack-reused 0
    Unpacking objects: 100% (17/17), done.
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
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Exit clicked

Another run

    root@rpi3:~/qqtest# ./qqtest
    qml: Exit clicked
    *** Error in `./qqtest': double free or corruption (fasttop): 0x72700920 ***
    Aborted

Hmm, an ugly error on exit. See this [post][qpa-exit-errors] for some analysis.

#### Manually Cross-compiling Qt Apps

This is not something I typically do, but the setup is not difficult. It does assume you have already built [your system][yocto-jumpnow-build] with Yocto.

*Source* your bitbake environment as normal and then build the `meta-toolchain-qt5` recipe.

Make sure you have **SDKMACHINE** in `local.conf` set appropriately for the target workstation you plan on using the SDK. The SDK is self-contained and can be transferred to other machines.

    scott@fractal:~$ source poky-krogoth/oe-init-build-env ~/rpi/build
    
    scott@fractal:~/rpi/build$ bitbake meta-toolchain-qt5

When that completes, install the SDK by running the installation script.

Yocto leaves the SDK in `${TMPDIR}/deploy/sdk`.

In my `local.conf` I have **TMPDIR=/oe4/rpi/tmp-krogoth**, so the SDK installer can be found here

    scott@fractal:~/rpi/build$ cd /oe4/rpi/tmp-krogoth/deploy/sdk
    
    scott@fractal:/oe4/rpi/tmp-krogoth/deploy/sdk$ ls -l
    total 601760
    -rw-r--r-- 1 scott scott     10154 Sep  1 13:54 poky-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-vfpv4-toolchain-2.1.1.host.manifest
    -rwxr-xr-x 1 scott scott 616157351 Sep  1 13:57 poky-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-vfpv4-toolchain-2.1.1.sh
    -rw-r--r-- 1 scott scott     24508 Sep  1 13:54 poky-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-vfpv4-toolchain-2.1.1.target.manifest
    
Run the installer as root (I haven't tried a non-root install)

    scott@fractal:/oe4/rpi/tmp-krogoth/deploy/sdk$ sudo ./poky-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-vfpv4-toolchain-2.1.1.sh

The default install location is `/opt/poky/2.1.1`, but you can change it.

To use the SDK, *source* the SDK environment using a provided script

    /opt/poky/2.1.1/environment-setup-cortexa7hf-neon-vfpv4-poky-linux-gnueabi

Here is a complete cross-build example run from a headless 64-bit Linux server that does not have any native Qt software installed. 

The meta-qt5 SDK was installed to `/opt/poky/rpi-meta-qt5-2.2.1`.

    scott@fractal:~$ cd projects/

    scott@fractal:~/projects$ git clone https://github.com/scottellis/qqtest
    Cloning into 'qqtest'...
    remote: Counting objects: 20, done.
    remote: Compressing objects: 100% (17/17), done.
    remote: Total 20 (delta 7), reused 16 (delta 3), pack-reused 0
    Unpacking objects: 100% (20/20), done.
    Checking connectivity... done.

    scott@fractal:~/projects$ cd qqtest/

    scott@fractal:~/projects/qqtest$ source /opt/poky/rpi-meta-qt5-2.1.1/environment-setup-cortexa7hf-neon-vfpv4-poky-linux-gnueabi

    scott@fractal:~/projects/qqtest$ qmake && make -j8
    Cannot read /opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/lib/qt5/mkspecs/oe-device-extra.pri: No such file or directory
    sh: OE_QMAKE_CXX: command not found
    sh: OE_QMAKE_CXXFLAGS: command not found
    Info: creating stash file /home/scott/projects/qqtest/.qmake.stash
    arm-poky-linux-gnueabi-g++  -march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi -c -pipe  -O2 -pipe -g -feliminate-unused-debug-types -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/work/x86_64-nativesdk-pokysdk-linux/meta-environment-raspberrypi2/1.0-r8=/usr/src/debug/meta-environment-raspberrypi2/1.0-r8 -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/sysroots/x86_64-linux= -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/sysroots/x86_64-nativesdk-pokysdk-linux=  -O2 -std=gnu++11 -Wall -W -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5 -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtQuick -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtGui -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtQml -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtNetwork -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtCore -I. -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/lib/qt5/mkspecs/linux-oe-g++ -o main.o main.cpp
    /opt/poky/rpi-meta-qt5-2.1.1/sysroots/x86_64-pokysdk-linux/usr/bin/qt5/rcc -name qml qml.qrc -o qrc_qml.cpp
    arm-poky-linux-gnueabi-g++  -march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi -c -pipe  -O2 -pipe -g -feliminate-unused-debug-types -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/work/x86_64-nativesdk-pokysdk-linux/meta-environment-raspberrypi2/1.0-r8=/usr/src/debug/meta-environment-raspberrypi2/1.0-r8 -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/sysroots/x86_64-linux= -fdebug-prefix-map=/oe4/rpi/tmp-krogoth/sysroots/x86_64-nativesdk-pokysdk-linux=  -O2 -std=gnu++11 -Wall -W -D_REENTRANT -fPIC -DQT_NO_DEBUG -DQT_QUICK_LIB -DQT_GUI_LIB -DQT_QML_LIB -DQT_NETWORK_LIB -DQT_CORE_LIB -I. -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5 -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtQuick -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtGui -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtQml -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtNetwork -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/include/qt5/QtCore -I. -I/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/lib/qt5/mkspecs/linux-oe-g++ -o qrc_qml.o qrc_qml.cpp
    arm-poky-linux-gnueabi-g++  -march=armv7ve -marm -mfpu=neon-vfpv4  -mfloat-abi=hard -mcpu=cortex-a7 --sysroot=/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi -Wl,-O1 -Wl,--hash-style=gnu -Wl,--as-needed -Wl,-O1 -o qqtest main.o qrc_qml.o   -L/opt/poky/rpi-meta-qt5-2.1.1/sysroots/cortexa7hf-neon-vfpv4-poky-linux-gnueabi/usr/lib -lQt5Quick -L/oe4/rpi/tmp-krogoth/sysroots/raspberrypi2/usr/lib -lQt5Gui -lQt5Qml -lQt5Network -lQt5Core -lGLESv2 -lpthread

    scott@fractal:~/projects/qqtest$ ls -l qqtest
    -rwxrwxr-x 1 scott scott 399172 Sep  1 14:29 qqtest

You can verify the executable is for an ARM board

    scott@fractal:~/projects/qqtest$ file qqtest
    qqtest: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 2.6.32, BuildID[sha1]=c15301ddc862ea976d8928fad21e45e9615846e3, not stripped

Copy it to the RPi

    scott@fractal:~/projects/qqtest$ scp qqtest root@192.168.10.114:/home/root
    Warning: Permanently added '192.168.10.114' (ECDSA) to the list of known hosts.
    qqtest                                                                                                    

Then over on the RPi, the *qqtest* app should run fine.

#### Creating Bitbake recipes for your Qt apps

Eventually you will want Yocto to build and install your app automatically in the image rootfs.

The [Yocto documentation][yocto-docs] is the official resource for recipes, but I've found the easiest way to learn is looking at existing examples. The [meta-qt5][meta-qt5] repository has a number of Qt5 examples.
 
The [meta-qt5][meta-qt5] layer provides some extra tools that handle Qt5 specifics. The *require qt5.inc* line brings them in.

Here is an example recipe for the *qqtest* application. 

The source is pulled from the Github repository.

    SUMMARY = "Qt5 QML test app"
    HOMEPAGE = "http://www.jumpnowtek.com"
    LICENSE = "MIT"
    LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

    DEPENDS += "qtdeclarative"

    PR = "r0"

    SRCREV = "${AUTOREV}"
    SRC_URI = "git://github.com/scottellis/qqtest.git"

    S = "${WORKDIR}/git"

    require recipes-qt/qt5/qt5.inc

    do_install() {
        install -d ${D}${bindir}
        install -m 0755 ${B}/${PN} ${D}${bindir}
    }

    FILES_${PN} = "${bindir}"

    RDEPENDS_${PN} = "qtdeclarative-qmlplugins"

You can find the recipe here [meta-rpi/recipes-qt/qqtest/qqtest_git.bb][qqtest-recipe]

And the *qqtest* package was added to the rootfs here [meta-rpi/images/qt5-image.bb][qt5-image-recipe] 


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
[qpa-exit-errors]: http://www.jumpnowtek.com/yocto/Qt5-Errors-On-Exit-with-QPA.html
[qqtest-recipe]: https://github.com/jumpnow/meta-rpi/blob/krogoth/recipes-qt/qqtest/qqtest_git.bb
[qt5-image-recipe]: https://github.com/jumpnow/meta-rpi/blob/krogoth/images/qt5-image.bb
[yocto-docs]: http://www.yoctoproject.org/docs/2.1/mega-manual/mega-manual.html
[pitft35r]: https://www.adafruit.com/products/2441
[pitft28r]: https://www.adafruit.com/products/1601
[raspi2fb]: https://github.com/AndrewFromMelbourne/raspi2fb
