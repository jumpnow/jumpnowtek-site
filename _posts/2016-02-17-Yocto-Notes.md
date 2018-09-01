---
layout: post
title: Miscellaneous Yocto Notes
description: ""
date: 2016-02-17 09:30:00
categories: yocto
tags: [yocto, linux]
---

### oe-pkgdata-util

    scott@fractal:~/elvaria/build$ oe-pkgdata-util -h
    usage: oe-pkgdata-util [-h] [-d] [-p PKGDATA_DIR] <subcommand> ...

    OpenEmbedded pkgdata tool - queries the pkgdata files written out during
    do_package

    optional arguments:
      -h, --help            show this help message and exit
      -d, --debug           Enable debug output
      -p PKGDATA_DIR, --pkgdata-dir PKGDATA_DIR
                            Path to pkgdata directory (determined automatically if
                            not specified)

    subcommands:
      <subcommand>
        lookup-pkg          Translate between recipe-space package names and
                            runtime package names
        list-pkgs           List packages
        list-pkg-files      List files within a package
        lookup-recipe       Find recipe producing one or more packages
        find-path           Find package providing a target path
        read-value          Read any pkgdata value for one or more packages
        glob                Expand package name glob expression

    Use oe-pkgdata-util <subcommand> --help to get help on a specific command


Example: List the individual packages the *linux-firmware* recipe provides

    scott@fractal:~/elvaria/build$ oe-pkgdata-util list-pkgs -p linux-firmware
    linux-firmware-ralink-license
    linux-firmware-ralink
    linux-firmware-radeon-license
    linux-firmware-radeon
    linux-firmware-marvell-license
    linux-firmware-sd8686
    linux-firmware-sd8787
    linux-firmware-sd8797
    linux-firmware-ti-connectivity-license
    linux-firmware-wl12xx
    linux-firmware-wl18xx
    linux-firmware-vt6656-license
    linux-firmware-vt6656
    linux-firmware-rtl-license
    linux-firmware-rtl8192cu
    linux-firmware-rtl8192ce
    linux-firmware-rtl8192su
    linux-firmware-broadcom-license
    linux-firmware-bcm4329
    linux-firmware-bcm4330
    linux-firmware-bcm4334
    linux-firmware-bcm4354
    linux-firmware-atheros-license
    linux-firmware-ar9170
    linux-firmware-ar3k
    linux-firmware-ath6k
    linux-firmware-ath9k
    linux-firmware-iwlwifi-license
    linux-firmware-iwlwifi-135-6
    linux-firmware-iwlwifi-3160-7
    linux-firmware-iwlwifi-3160-8
    linux-firmware-iwlwifi-3160-9
    linux-firmware-iwlwifi-6000-4
    linux-firmware-iwlwifi-6000g2a-5
    linux-firmware-iwlwifi-6000g2a-6
    linux-firmware-iwlwifi-6000g2b-5
    linux-firmware-iwlwifi-6000g2b-6
    linux-firmware-iwlwifi-6050-4
    linux-firmware-iwlwifi-6050-5
    linux-firmware-iwlwifi-7260-7
    linux-firmware-iwlwifi-7260-8
    linux-firmware-iwlwifi-7260-9
    linux-firmware-iwlwifi-7265-8
    linux-firmware-iwlwifi-7265-9
    linux-firmware-license
    linux-firmware-dbg
    linux-firmware-dev
    linux-firmware

