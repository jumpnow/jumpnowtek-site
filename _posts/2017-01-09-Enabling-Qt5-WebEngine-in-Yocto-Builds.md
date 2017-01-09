---
layout: post
title: Enabling Qt5 WebEngine in a Yocto Builds 
date: 2017-01-09 05:30:00
categories: rpi
tags: [rpi, qt5, webengine, yocto]
---

The [Qt5 WebEngine][qt5-webengine] components add significantly to the size of the images built by Yocto, so I don't include them normally.  

You can enable them as follows.

For runtime and native development use on the target, add the following *qtwebengine* packages to your image recipe 

    QT5_WEBENGINE_PKGS = " \
        qtwebengine-dev \
        qtwebengine-mkspecs \
        qtwebengine \
    "

    IMAGE_INSTALL += " \
        ${QT5_WEBENGINE_PKGS} \
    "

For cross-compiling using the *meta-qt5-toolchain* SDK add a **packagegroup-qt5-toolchain-target.bbappend** file like this to your *meta-layer*

    scott@fractal:~/rpi$ ls meta-rpi/recipes-qt/packagegroups/
    packagegroup-qt5-toolchain-target.bbappend

    scott@fractal:~/rpi/meta-rpi/recipes-qt/packagegroups$ cat packagegroup-qt5-toolchain-target.bbappend

    USE_WEBENGINE = " \
        qtwebengine-dev \
        qtwebengine-mkspecs \
        qtwebengine \
    "

    RDEPENDS_${PN} += " \
        ${USE_WEBENGINE} \
    " 


[qt5-webengine]: http://doc.qt.io/qt-5/qtwebengine-index.html
