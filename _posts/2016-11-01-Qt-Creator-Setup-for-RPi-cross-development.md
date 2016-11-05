---
layout: post
title: Using Qt Creator to cross-compile and debug Raspberry Pi Qt5 apps 
description: "Setup of Qt Creator to use the Yocto RPi SDK"
date: 2016-11-05 08:54:00
categories: rpi
tags: [rpi, qt5, qt creator, eglfs, opengl, qml, yocto]
---

The following instructions assume a few things

1) You have built a Linux system for the Raspberry Pi with tools from the Yocto Project using [these instructions][yocto-jumpnow-build] or something similar.

2) You are currently running the [qt5-image][qt5-image] or another image with similar Qt5.7 headers, libs and associated dev tools installed.  

3) You have built a cross-compiler SDK with Yocto and installed it on the workstation you plan to develop on.

For (3) you can refer to [this post][rpi-qt5-qml-dev] for some more details, but here is the short version 

Setup the Yocto environment as normal

    scott@fractal:~$ source poky-krogoth/oe-init-build-env ~/rpi/build

build the SDK

    scott@fractal:~/rpi/build$ bitbake meta-toolchain-qt5

The resulting SDK installation script can be found in `${TMPDIR}/deploy/sdk`. 

Copy the script to the workstation you plan to work from and run it.

I built my SDK on an Ubuntu 16.04 server, but for the RPi Qt cross-development I'm going to use a laptop with Fedora 24 installed.

I ran the SDK install script on the laptop as **root** like this

    scott@t410:~$ sudo poky-glibc-x86_64-meta-toolchain-qt5-cortexa7hf-neon-vfpv4-toolchain-2.1.1.sh

The default installation path is `/opt/poky/2.1.1`.

I chose `/opt/poky/rpi-2.1.1` instead for the install directory on my workstation. Adjust paths for your installation accordingly in the following examples.

### Configuring Qt Creator

Startup Qt Creator, I'm using version 4.0.3, the default with Fedora 24.

Open the `Tools | Options` dialog.
 
#### Add a Qt version

Here is where you setup the path to *qmake* for the version of Qt the RPi is running.

Give the version whatever name you want, the important thing is the path to *qmake*.

* **Version name:** RPi 5.7
* **qmake location:** /opt/poky/rpi-2.1.1/sysroots/x86_64-pokysdk-linux/usr/bin/qt5/qmake

Screenshot - [Qt Creator Version Setup][qtcreator-version-screenshot]

#### Add a compiler

Add a new GCC compiler with the following path, again choose any name you want

* **Name:** GCC for RPi
* **Compiler path:** /opt/poky/rpi-2.1.1/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gcc

Screenshot - [Qt Creator Compiler Setup][qtcreator-compiler-screenshot]

#### Add a debugger

If you want to remotely debug your Qt applications you need to setup the path to *gdb*.

* **Name:** GDB for RPi
* **Path:** /opt/poky/rpi-2.1.1/sysroots/x86_64-pokysdk-linux/usr/bin/arm-poky-linux-gnueabi/arm-poky-linux-gnueabi-gdb
* **Type:** GDB
* **ABIs:** arm-linux-generic-elf-32bit
* **Version:** 7.10.1

Screenshot - [Qt Creator Debugger Setup][qtcreator-debugger-screenshot]

#### Add a kit

Add a Qt Creator *kit* using the version, compiler and debugger setups that were just added and specifying a *sysroots* path in the SDK and a *mkspec* to use.

* **Name:** RPi
* **File system name:**
* **Device type:** Generic Linux Device
* **Device:** RPi (default for Generic Linux)
* **Sysroot:** /opt/poky/rpi-2.1.1/sysroots/cortexa7hf-neon-vfp4-poky-linux-gnueabi
* **Compiler:** GCC for RPi
* **Environment:** No changes to apply.
* **Debugger:** GDB for RPi
* **Qt version:** RPi 5.7
* **Qt mkspec:** linux-oe-g++

Screenshot - [Qt Creator Kit Setup][qtcreator-kit-screenshot]

This *kit* will be remembered by Qt Creator and can be reused for any Qt project.

#### Using the new setup

I'll use a simple QML example with the source available in github.

Clone the project.

    scott@t410:~/projects$ git clone https://github.com/scottellis/qqtest
    Cloning into 'qqtest'...
    remote: Counting objects: 29, done.
    remote: Total 29 (delta 0), reused 0 (delta 0), pack-reused 29
    Unpacking objects: 100% (29/29), done.
    Checking connectivity... done.

Launch Qt Creator the way you normally would, probably from a desktop menu.

Then open the project file `qqtest.pro` using `File | Open File or Project...`

You should see an option to use the new *RPi* kit that you just setup.

Screenshot - [Qt Creator Kit Selection][qtcreator-choose-kit-screenshot]

Check the *RPi* kit and click *Configure Project*.

At this point you should be able to build the project, cross-compiled for the RPi.

For automatic deployment and remote debugging go to the `Tools | Options` dialog again and select `Devices` in the left pane.

You'll need the IP address of the RPi, in this example mine is `192.168.10.110`.

Screenshot - [Qt Creator Devices Setup][qtcreator-devices-screenshot]

It's all defaults except for the IP address. Use *root* with no password unless you added one.

You can leave the *GDB server executable* blank. It will be found automatically.

#### Conclusion

You should now be able to build, run and debug Qt5 applications on the Raspberry Pi from your Linux workstation.


[yocto-jumpnow-build]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[qt5-image]: https://github.com/jumpnow/meta-rpi/blob/krogoth/images/qt5-image.bb
[rpi-qt5-qml-dev]: http://www.jumpnowtek.com/rpi/Qt5-and-QML-Development-with-the-Raspberry-Pi.html
[qtcreator-version-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-version.png
[qtcreator-compiler-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-compiler.png
[qtcreator-debugger-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-debugger.png
[qtcreator-kit-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-kit.png
[qtcreator-choose-kit-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-choose-kit.png
[qtcreator-devices-screenshot]: http://www.jumpnowtek.com/assets/qtcreator-devices.png










