
## Packages

I don't think there is an official prebuilt package repository for the development *FreeBSD 11* branch, so I'm building some ports myself. [Qt][qt-site] and whatever *FreeBSD* uses for access to webcams. I think it's [Webcamd][webcamd], but I'm not sure. The goal is to port a version of [SyntroLCam][syntrolcam] to *FreeBSD*. 


To get started

The systems comes with a *C* compiler and associated development tools

    root@wandboard:~ # which cc
    /usr/bin/cc
    
    root@wandboard:~ # cc --version
    FreeBSD clang version 3.4.1 (tags/RELEASE_34/dot1-final 208032) 20140512
    Target: armv6--freebsd11.0-gnueabi
    Thread model: posix
 
Fetch the ports tree

    root@wandboard:~ # portsnap fetch

First time usage

	root@wandboard:~ # portsnap extract


Since I never plan to connect a display, I'm setting some default flags in `/etc/make.conf` so they apply to all ports

	OPTIONS_UNSET= X11 GUI CUPS DOCS EXAMPLES NLS

    OPTIONS_SET= IPV6 THREADS


Search for a port

    root@wandboard:/usr/ports # make search name=iperf
    Port:   iperf-2.0.5
    Path:   /usr/ports/benchmarks/iperf
    Info:   Tool to measure maximum TCP and UDP bandwidth
    Maint:  sunpoet@FreeBSD.org
    B-deps:
    R-deps:
    WWW:    http://iperf.sourceforge.net/
    
    Port:   iperf3-3.0.8
    Path:   /usr/ports/benchmarks/iperf3
    Info:   Improved tool to measure TCP and UDP bandwidth
    Maint:  bmah@FreeBSD.org
    B-deps:
    R-deps:
    WWW:    https://github.com/esnet/iperf

List dependencies before building

    root@wandboard:/usr/ports/benchmarks/iperf # make all-depends-list

Configure dependencies all at once (so the build can run unattended)

    root@wandboard:/usr/ports/devel/subversion # make config-recursive

Build a port, this will build and install dependencies as well

    root@wandboard:/usr/ports/devel/subversion # make install clean



[freebsd]: http://www.freebsd.org
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/arm/armv6/ISO-IMAGES/11.0/
[freebsd-arm]: https://wiki.freebsd.org/FreeBSD/arm
[wandboard]: http://www.wandboard.org/
[beagleboard]: http://www.beagleboard.org/
[rpi]: http://www.raspberrypi.org/
[pandaboard]: http://www.pandaboard.org/
[overo]: https://store.gumstix.com/index.php/category/33/
[duovero]: https://store.gumstix.com/index.php/category/43/
[openbsd]: http://www.openbsd.org
[freebsd-boot-log]: https://gist.github.com/scottellis/1f9439f8ddd4fb87718e
[qt-site]: http://qt-project.org/
[webcamd]: http://www.selasky.org/hans_petter/video4bsd/
[syntrolcam]: https://github.com/Syntro/SyntroLCam
