---
layout: post
title: Qt5 Errors on Exit using QPA 
date: 2016-09-02 13:50:00
categories: yocto
tags: [qt5, eglfs, linuxfb, qml, yocto]
---

When running [Qt5][qt] apps using the [EGLFS][qpa] or [LinuxFB][qpa] platform plugins, I frequently get a memory access error like the following when the app does a normal exit.

A simple QML app - [qqtest][qqtest]

    root@rpi3:~/qqtest# ./qqtest
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Exit clicked
    *** Error in `./qqtest': double free or corruption (fasttop): 0x72700920 ***
    Aborted

A simple Qt Widgets app - [tspress][tspress]

    root@rpi3:~# tspress
    Down: 394 468
    Up  : 393 468
    Segmentation fault

Another Qt Widgets app - [qcolorcheck][qcolorcheck]

    root@rpi3:~# qcolorcheck
    *** Error in `qcolorcheck': free(): invalid pointer: 0x72f00960 ***
    Aborted

Those runs were from an RPi3 running a [Yocto 2.1][yocto] built system with [Qt 5.7][qt-5.7] and the EGLFS plugin. I was getting the same errors with previous versions of Yocto and Qt on platforms like the [Beaglebone Black][bbb].

The apps are exiting normally. With the QML app I am calling *Qt.quit()*. For the Qt Widget apps I am calling *close()* for the **QMainWindow**.

Here's what I've gathered

1. It happens with either [QML][qml] or [Qt Widgets][qtwidgets] applications
2. It happens with even the minimal [Qt Creator][qt-creator] generated skeleton apps
3. The error only occurs when apps are run using the *eglfs* or *linuxfb* [platform plugins][qpa]. The same apps when run under a window manager like *X11*, *Win32* or *MacOS* exit without errors.
4. The error is generated in the destruction of the **QApplication** object, at least in the case of Qt Widgets apps. This is normally a stack variable in *main()*, but to test you can allocate the  **QApplication** instance on the heap and destroy it manually before leaving *main()* and generate the same error.
5. The error does not always occur, but I don't see a pattern.

For example, here is a few more consecutive runs of that *qqtest* app

    root@rpi3:~/qqtest# ./qqtest
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Exit clicked

    root@rpi3:~/qqtest# ./qqtest
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Exit clicked
    *** Error in `./qqtest': double free or corruption (fasttop): 0x72700920 ***
    Aborted

    root@rpi3:~/qqtest# ./qqtest
    qml: Exit clicked

    root@rpi3:~/qqtest# ./qqtest
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Button 1 clicked.
    qml: Button 2 clicked.
    qml: Button 1 clicked.
    qml: Exit clicked

    root@rpi3:~/qqtest# ./qqtest
    qml: Exit clicked
    *** Error in `./qqtest': double free or corruption (fasttop): 0x72700920 ***
    Aborted

It looks like a cleanup error internal to Qt, probably threading related because of the randomness.

**Important**: This problem does not appear to affect the apps when running.

Since the apps I work on for products tend to run from *power-on* until *power-off*, this bug is not a high priority.

The error is a bit annoying when you are playing around with small test apps in development.

At some point I may get around to debugging further, but, of course, I'm always hoping someone fixes it first.

To debug I would probably build a *linuxfb* version of Qt on a workstation, since I really don't want to debug the Qt libs on an embedded board.

[qt]: http://www.qt.io/
[qt-5.7]: http://doc.qt.io/qt-5/index.html
[qml]: http://doc.qt.io/qt-5/qtqml-index.html
[qtwidgets]: http://doc.qt.io/qt-5/qtwidgets-index.html
[yocto]: https://www.yoctoproject.org/
[qpa]: http://doc.qt.io/qt-5/embedded-linux.html
[qqtest]: https://github.com/scottellis/qqtest
[tspress]: https://github.com/scottellis/tspress
[qcolorcheck]: https://github.com/scottellis/qcolorcheck
[bbb]: http://www.beagleboard.org
[qt-creator]: https://en.wikipedia.org/wiki/Qt_Creator