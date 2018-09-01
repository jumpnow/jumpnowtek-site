---
layout: post
title: Raspberry Pi TFT Displays and Qt5
date: 2017-04-16 08:02:00
categories: rpi
tags: [rpi, qt5, eglfs, linuxfb, pitft]
---

Some configuration notes for using the Raspberry Pi TFT displays and Qt5.

I am primarily testing with RPi3s running a Yocto built system ([notes here][rpi-yocto])

    root@pi3:~# uname -a
    Linux pi3 4.4.39 #1 SMP Thu Dec 22 04:12:18 EST 2016 armv7l armv7l armv7l GNU/Linux

    root@pi3:~# qmake --version
    QMake version 3.0
    Using Qt version 5.7.0 in /usr/lib

    root@pi3:~# g++ --version
    g++ (GCC) 6.2.0
    ...

These systems do not have a desktop or window manager installed.

Qt applications are run fullscreen using either the `eglfs` or `linuxfb` [Qt5 platform plugins][embedded-linux-qpa].

The [PiTFT 3.5 inch][pitft35r] and [PiTFT 2.8 inch][pitft28r] resistive touchscreens use a SPI interface for both the display and the touch controller (SPI0 CS0 and CS1).

Device tree overlays for both of these displays are built and installed by default in the `overlays/` directory of the boot partition.

    root@rpi3:~# ls -l /mnt/fat/overlays/pitft*resistive*
    -rwxr-xr-x 1 root root 2802 Jan  1 10:07 /mnt/fat/overlays/pitft28-resistive.dtbo
    -rwxr-xr-x 1 root root 2802 Jan  1 10:07 /mnt/fat/overlays/pitft35-resistive.dtbo

The backlight can be a simple gpio ON/OFF (the default) or controlled using PWM for the PiTFT35. See the notes at the bottom of this post for controlling the backlight.

When the appropriate dtoverlay has been setup in `config.txt`, the TFTs show up like this

    root@pi3:~# ls /dev/fb*
    /dev/fb0  /dev/fb1

where `/dev/fb0` is the standard HDMI display and `/dev/fb1` is the TFT.

The touch controller should show up as `/dev/input/touchscreen0` which will be a link to some `/dev/input/eventN` device. Which `eventN` depends on whether you have other input devices connected like a mouse or keyboard.

With no other input devices, it will be `event0` like this.

    root@pi3:~# ls -l /dev/input
    total 0
    drwxr-xr-x 2 root root      60 Dec 31  1969 by-path
    crw-rw---- 1 root input 13, 64 Dec 31  1969 event0
    crw-rw---- 1 root input 13, 63 Dec 31  1969 mice
    crw-rw---- 1 root input 13, 32 Dec 31  1969 mouse0
    lrwxrwxrwx 1 root root       6 Dec 31  1969 touchscreen0 -> event0


If you are running a qt5 image from [meta-rpi][meta-rpi], there are some test programs installed.

You can use `tspress` to test a qt widgets app (linuxfb or eglfs).

You can use `qqtest` to test QML (eglfs only).

## Mounting /dev/mmcblk0p1

For these examples, editing the RPi `config.txt` file is required. My systems don't normally mount the RPi boot partition by default, but you can manually configure it to mount automatically like this

Create a mount point

    root@rpi3:~# mkdir /mnt/fat

Uncomment this line in `/etc/fstab`

    /dev/mmcblk0p1       /mnt/fat             auto       defaults              0  0

You can use `vi` or `nano` to edit.

Then reboot or manually mount the boot partition like this

    root@rpi3:~# mount /dev/mmcblk0p1 /mnt/fat

The `config.txt` file is here

    /mnt/fat/config.txt

The device tree overlays directory is here

    /mnt/fat/overlays/


## Using linuxfb as the Qt QPA Platform Driver

The `linuxfb` platform plugin does not require OpenGL and can directly target the TFTs at `/dev/fb1`. If you are programming using Qt Widgets, this is probably the easiest solution.

##### config.txt

Set the rotation parameter to what you want. Values of 90 or 270 orient the display in landscape mode.

**PiTFT 2.8**

    root@rpi3:~# cat /mnt/fat/config.txt
    disable_overscan=1
    dtparam=spi=on
    dtoverlay=pitft28-resistive,rotate=270,speed=32000000,fps=60

**PiTFT 3.5**

    root@pi3:~# cat /mnt/fat/config.txt
    disable_overscan=1
    dtparam=spi=on
    dtoverlay=pitft35-resistive,rotate=90,speed=32000000,fps=60

You can have more in your `config.txt`. This is just the minimal required for the PiTFTs.

##### qt5-env.sh

You can use the same Qt environment for either.

    root@pi3:~# cat /etc/profile.d/qt5-env.sh
    #!/bin/sh

    export PATH=${PATH}:/usr/bin/qt5

    export QT_QPA_PLATFORM=linuxfb:fb=/dev/fb1
    export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/touchscreen0:rotate=90
    export QT_QPA_FB_TSLIB=1
    export TSLIB_FBDEVICE=/dev/fb1
    export TSLIB_TSDEVICE=/dev/input/touchscreen0

**Note for PiTFT35:** The rotation for the driver overlay in `config.txt` and the QT\_QPA\_EVDEV\_TOUCHSCREEN\_PARAMETERS environment should differ by 180 degrees. I haven't investigated why.

##### ts_calibrate

Generate a calibration file with `ts_calibrate`

    root@pi3:~# ts_calibrate

Follow the onscreen instructions.

The calibration file is saved as `/etc/pointercal`.

Use of `tslib` is optional, but results in better touch accuracy for me.

**Note:** If you change the rotation you will have to rerun `ts_calibrate`.

## Using eglfs as the Qt QPA Platform Driver

To use `QML` you must use the `eglfs` platform plugin.

Using the `eglfs` plugin you cannot directly work with the TFT displays from Qt.

The Qt 5.7 `eglfs` plugin uses the RPi opengl libraries from the [RPi userland][rpi-userland] package which are in turned backed up by hardware in the RPi VideoCore GPU.

    root@pi3:~# ldd /usr/lib/qt5/plugins/platforms/libqeglfs.so | grep -E 'EGL|GLE'
            libEGL.so.1 => /usr/lib/libEGL.so.1 (0x760d2000)
            libGLESv2.so.2 => /usr/lib/libGLESv2.so.2 (0x760ae000)

    root@pi3:~# ldd /usr/lib/libEGL.so.1 | grep vc
            libvchostif.so => /usr/lib/libvchostif.so (0x76e2d000)
            libvchiq_arm.so => /usr/lib/libvchiq_arm.so (0x76e18000)
            libvcos.so => /usr/lib/libvcos.so (0x76dff000)

    root@pi3:~# ldd /usr/lib/libGLESv2.so.2 | grep vc
            libvchostif.so => /usr/lib/libvchostif.so (0x76ea5000)
            libvchiq_arm.so => /usr/lib/libvchiq_arm.so (0x76e90000)
            libvcos.so => /usr/lib/libvcos.so (0x76e77000)

Unfortunately the RPi GPU does not know how to output to a SPI attached display at `/dev/fb1`. The RPi GPU only knows about the HDMI (`/dev/fb0`).

Because the TFT displays are so small (not many pixels) and because the RPi are fairly powerful SOCs, it's possible to copy the output of `/dev/fb0` to `/dev/fb1` in a user program and still have it work pretty well.

Several people have already written such *copy* applications for public use. The one I've been using is called [raspi2fb][raspi2fb]. The program is installed, but not enabled in my qt5 images (see below).

##### config.txt

To facilitate the copy of the framebuffers, setup a custom hdmi display for the GPU with the same dimensions as the TFT.

**PiTFT 2.8**

    root@pi3:~# cat /mnt/fat/config.txt
    hdmi_force_hotplug=1
    hdmi_cvt=320 240 60
    hdmi_group=2
    hdmi_mode=87

    disable_overscan=1
    dtparam=spi=on
    dtoverlay=pitft35-resistive,rotate=90,speed=32000000,fps=60


**PiTFT 3.5**

    root@pi3:~# cat /mnt/fat/config.txt
    hdmi_force_hotplug=1
    hdmi_cvt=480 320 60
    hdmi_group=2
    hdmi_mode=87

    disable_overscan=1
    dtparam=spi=on
    dtoverlay=pitft35-resistive,rotate=270,speed=32000000,fps=60

Again you can have more in your `config.txt` as necessary.

##### qt5-env.sh

The same Qt environment works for either display

    root@rpi3:~# cat /etc/profile.d/qt5-env.sh
    #!/bin/sh

    export PATH=${PATH}:/usr/bin/qt5

    export QT_QPA_PLATFORM=eglfs
    export QT_QPA_EVDEV_TOUCHSCREEN_PARAMETERS=/dev/input/touchscreen0:rotate=90
    export QT_QPA_FB_TSLIB=1
    export TSLIB_FBDEVICE=/dev/fb1
    export TSLIB_TSDEVICE=/dev/input/touchscreen0

##### raspi2fb

Enable the `raspi2fb` daemon by creating a startup link

     root@rpi3:~# cd /etc/rc5.d
     root@rpi3:/etc/rc5.d# ln -sf ../init.d/raspi2fb S90raspi2fb

Reboot or start the `raspi2fb` daemon manually

     root@rpi3:~# /etc/init.d/raspi2fb start

You can kill it using **stop** as the argument.

##### ts_calibrate

Generate a calibration file with `ts_calibrate`

    root@pi3:~# ts_calibrate

Follow the onscreen instructions.

The calibration file is saved as `/etc/pointercal`.

You probably want to run `ts_calibrate` to improve the touch calibration.

Unfortunately I am not able to get a very accurate calibration of the TFT screen using the *eglfs* plugin, particularly near the display borders.

Using the *linuxfb* plugin, the screen can be calibrated very accurately.

This is not a huge problem if your GUI controls are decent size. For example, the controls in the demo apps `tspress` and `qqtest` work okay.

If your application requires fine touch accuracy, then I recommend you stay with the *linuxfb* plugin and restrict yourself to Qt widgets.


## Backlight Control

There are two ways to control the PiTFT backlight.

* gpio-backlight driver
* pwm driver (pitft35 only)

The default behavior is to use the Linux gpio-backlight driver.

#### gpio-backlight

The interface for the gpio-backlight driver is through sysfs

    root@rpi3:~# ls /sys/class/backlight
    soc:backlight

    root@rpi3:~# ls /sys/class/backlight/soc\:backlight
    actual_brightness  bl_power  brightness  device  max_brightness  power  subsystem  type  uevent

Because of the setup in the dts overlays, the gpio starts in the ON state

    root@rpi3:~# cat /sys/class/backlight/soc\:backlight/brightness
    1

You can turn off the display backlight like this

    root@rpi3:~# echo 0 > /sys/class/backlight/soc\:backlight/brightness

And back on again like this

    root@rpi3:~# echo 1 > /sys/class/backlight/soc\:backlight/brightness

Any programming language that can do file I/O can control the backlight this way.

#### pwm control for the PiTFT 3.5

You'll need to enable a pwm driver on GPIO_18.

This post on [Using the RPi hardware PWM timers][rpi-pwm] has more details, but the short version is add this line to `config.txt`

For **4.9** kernels

    dtoverlay=pwm

For **4.4** kernels

    dtoverlay=pwm-with-clk

After a reboot you should have the pwm kernel driver loaded

    root@rpi3:~# lsmod | grep pwm
    pwm_bcm2835             2711  0

and a pwm driver interface showing up in `sysfs`.

    root@rpi3:~# ls /sys/class/pwm/pwmchip0
    device  export  npwm  power  subsystem  uevent  unexport

The GPIO pin used for the gpio-backlight does not come from the RPi, but rather from the touch controller (see schematic).

So an important step for this to work is to first disable the touch controller gpio so it is not fighting the RPi PWM pin.

    root@rpi3:~# echo 0 > /sys/class/backlight/soc\:backlight/brightness

Now export and use the RPi GPIO_18 as a standard Linux PWM pin.

Here is a 50% duty cycle PWM signal for the backlight (times are nanoseconds)

    root@pi3:~# echo 0 > /sys/class/pwm/pwmchip0/export
    root@pi3:~# echo 1000000 > /sys/class/pwm/pwmchip0/pwm0/period
    root@pi3:~# echo 500000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
    root@pi3:~# echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

And here is 80% backlight

    root@pi3:~# echo 800000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

And this turns it off

    root@pi3:~# echo 0 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle

As would

    root@pi3:~# echo 0 > /sys/class/pwm/pwmchip0/pwm0/enable

These commands to disable the gpio-backlight driver and export and configure the initial state of the pwm driver could be done in an init script like this (no error handling).

    #!/bin/sh

    echo 0 > /sys/class/backlight/soc\:backlight/brightness

    echo 0 > /sys/class/pwm/pwmchip0/export
    echo 1000000 > /sys/class/pwm/pwmchip0/pwm0/period
    echo 900000 > /sys/class/pwm/pwmchip0/pwm0/duty_cycle
    echo 1 > /sys/class/pwm/pwmchip0/pwm0/enable

And then further control could be done with whatever programming language you choose.


[rpi-yocto]: https://jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[rpi-qt5-qml-dev]: https://jumpnowtek.com/rpi/Qt5-and-QML-Development-with-the-Raspberry-Pi.html
[embedded-linux-qpa]: http://doc.qt.io/qt-5/embedded-linux.html
[pitft35r]: https://www.adafruit.com/products/2441
[pitft28r]: https://www.adafruit.com/products/1601
[raspi2fb]: https://github.com/AndrewFromMelbourne/raspi2fb
[rpi-pwm]: https://jumpnowtek.com/rpi/Using-the-Raspberry-Pi-Hardware-PWM-timers.html
[rpi-userland]: https://github.com/raspberrypi/userland
[meta-rpi]: https://github.com/jumpnow/meta-rpi