---
layout: post
title: BeagleBone Black U-Boot
description: "Some working notes on U-Boot for the BeagleBone Black"
date: 2015-07-18 14:30:00
categories: beaglebone 
tags: [linux, beaglebone, uboot]
---

A collection of notes on working with the [U-Boot][uboot] bootloader and [BeagleBone Black][bbb] boards.

The default configuration of u-boot for the BBB works fine without modifications. What follows is out of curiosity, not necessity.

The Yocto meta-layer I'm working with is [meta-bbb][meta-bbb] with instructions for use described [here][bbb-yocto].

The u-boot version described is `2015-07`.

### Building with Yocto

The u-boot configuration is specified here `meta-bbb/conf/machine/beaglebone.conf`

        ...
        PREFERRED_PROVIDER_virtual/bootloader = "u-boot"
        PREFERRED_PROVIDER_u-boot = "u-boot"
        
        UBOOT_ENTRYPOINT = "0x80008000"
        UBOOT_LOADADDRESS = "0x80008000"
        UBOOT_MACHINE = "am335x_boneblack_config"
        
        EXTRA_IMAGEDEPENDS += "u-boot"
        ...

The `EXTRA_IMAGEDEPENDS` setting results in u-boot getting built for all images automatically.

The upstream git source repository and commit to retrieve the `2015.07` version is specified in the bitbake recipe `meta-bbb/recipes-bsp/u-boot/u-boot_2015.07.bb`

        ...
        # v2015.07
        SRCREV = "33711bdd4a4dce942fb5ae85a68899a8357bdd94"
        SRC_URI = " \
            git://git.denx.de/u-boot.git;branch=master;protocol=git \
        ...
        
Use the *virtual/bootloader* target to build u-boot for the BBB.

        ~/bbb/build:~$ bitbake virtual/bootloader

If you want to clean the build first

        ~/bbb/build:~$ bitbake -c cleansstate virtual/bootloader

The binaries can be found under `<TMPDIR>/deploy/images/beaglebone`.

And example from a system with a TMPDIR of `/oe7/bbb/tmp-poky-fido-build`

        scott@octo:~/bbb/build$ ls -lt /oe7/bbb/tmp-poky-fido-build/deploy/images/beaglebone/
        total 116964
        lrwxrwxrwx 1 scott scott       25 Jul 17 11:17 MLO -> MLO-beaglebone-2015.07-r3
        lrwxrwxrwx 1 scott scott       25 Jul 17 11:17 MLO-beaglebone -> MLO-beaglebone-2015.07-r3
        lrwxrwxrwx 1 scott scott       32 Jul 17 11:17 u-boot-beaglebone.img -> u-boot-beaglebone-2015.07-r3.img
        lrwxrwxrwx 1 scott scott       32 Jul 17 11:17 u-boot.img -> u-boot-beaglebone-2015.07-r3.img
        -rwxr-xr-x 2 scott scott    63436 Jul 17 11:17 MLO-beaglebone-2015.07-r3
        -rwxr-xr-x 2 scott scott   408276 Jul 17 11:17 u-boot-beaglebone-2015.07-r3.img
        ...

### Building outside of Yocto

1. Get a cross-compiler. Some [notes are here][bbb-kernel-work] in the **Cross-compiler** section on how to build your own with Yocto.

2. Clone u-boot.

        ~$ cd bbb
        ~/bbb$ git clone git://git.denx.de/u-boot.git

3. Checkout the 2015.07 commit in a working branch

        ~/bbb$ cd u-boot
        ~/bbb/u-boot$ git checkout -b 2015.07 33711bdd4a4d

4. Source the cross-build environment

        ~/bbb/u-boot$ source /opt/poky/1.8/environment-setup-cortexa8hf-vfp-neon-poky-linux-gnueabi

5. Optionally apply any patches the bitbake recipe is using

        ~/bbb/u-boot$ git am ../meta-bbb/recipes-bsp/u-boot/u-boot-2015.07/*.patch
 
5. Configure u-boot

        ~/bbb/u-boot$ make am335x_boneblack_config

6. Build u-boot (the `-jN` parameter is optional)

        ~/bbb/u-boot$ make -j8


When it's done, `u-boot.img` and `MLO` are the binaries you want

        ~/bbb/u-boot$ ls -lrt
        ...
        -rw-rw-r--   1 scott scott  438635 Jul 18 13:32 u-boot.map
        -rwxrwxr-x   1 scott scott 2521751 Jul 18 13:32 u-boot
        -rw-rw-r--   1 scott scott  410780 Jul 18 13:32 u-boot.bin
        -rw-rw-r--   1 scott scott 1232426 Jul 18 13:32 u-boot.srec
        -rw-rw-r--   1 scott scott   56208 Jul 18 13:32 System.map
        -rw-rw-r--   1 scott scott  410844 Jul 18 13:32 u-boot.img
        drwxrwxr-x  10 scott scott    4096 Jul 18 13:32 spl
        -rw-rw-r--   1 scott scott   72812 Jul 18 13:32 MLO


If later you want to clean everything including the configuration

        ~/bbb/u-boot$ make distclean

 
To install and test the new bootloader

1. Over on a running BBB system, mount the FAT boot partition if it's not already mounted

        root@beaglebone:~# mount /dev/mmcblk0p1 /mnt

2. Assuming the network is up, use scp to copy the binaries

        ~/u-boot$ scp MLO u-boot.img root@<bbb-ip-address>/mnt

Reboot the BBB.

### U-Boot source files

The configuration file for the BBB is `u-boot/configs/am335x_boneblack_defconfig`

It is a small file
 
        CONFIG_ARM=y
        CONFIG_TARGET_AM335X_EVM=y
        CONFIG_SPL=y
        CONFIG_SPL_STACK_R=y
        CONFIG_SPL_STACK_R_ADDR=0x82000000
        CONFIG_SYS_EXTRA_OPTIONS="EMMC_BOOT"
        # CONFIG_CMD_IMLS is not set
        # CONFIG_CMD_FLASH is not set
        # CONFIG_CMD_SETEXPR is not set
        CONFIG_SPI_FLASH=y

The `CONFIG_TARGET_AM335x_EVM=y` setting means the BBB build will use the **AM335X_EVM** board code.

Specific AM335X_EVM source can be found under `u-boot/board/ti/am335x/`.

Definitions and board specific options can be found in `u-boot/include/configs/am335x_evm.h`.

### Watching the MLO log 

Here's what the **MLO** output looks like when booting from an SD card

        U-Boot SPL 2015.07 (Jul 19 2015 - 08:22:45)
        MMC: block number 0x100 exceeds max(0x0)
        MMC: block number 0x200 exceeds max(0x0)
        *** Error - No Valid Environment Area found
        *** Warning - bad CRC, using default environment
        
        reading u-boot.img
        reading u-boot.img

The warnings/errors are harmless, but here's why they show up

        MMC: block number 0x100 exceeds max(0x0)
        MMC: block number 0x200 exceeds max(0x0)
        *** Error - No Valid Environment Area found

These errors come from `drivers/mmc/mmc.c` line 247 in the `mmc_bread()` function.

`mmc_bread()` is being invoked from `read_env()` line 190 of `u-boot/common/env_mmc.c`

Which was called twice by `env_relocate_spec()` line 209 of `u-boot/common/env_mmc.c`

Which was called by `spl_start_uboot()` line 196 of `u-boot/board/ti/am335x/board.c`

Here's the relevant chunk from `am335x/board.c`

        #ifdef CONFIG_SPL_OS_BOOT
        int spl_start_uboot(void)
        {
                /* break into full u-boot on 'c' */
                if (serial_tstc() && serial_getc() == 'c')
                        return 1;

        #ifdef CONFIG_SPL_ENV_SUPPORT
                env_init();
                env_relocate_spec();
                if (getenv_yesno("boot_os") != 1)
                        return 1;
        #endif

                return 0;
        }
        #endif

So disregarding these lines in `env_relocate_spec()`

        224 #ifdef CONFIG_SPL_BUILD
        225         dev = 0;
        226 #endif

Or these lines in `read_env()`

        196 #ifdef CONFIG_SPL_BUILD
        197         dev = 0;
        198 #endif

which mean these warnings will always show when booting from an SD card.

The warning messages can be avoided entirely if the **CONFIG_SPL_OS_BOOT** definition was removed.

From the `u-boot/README`

                CONFIG_SPL_OS_BOOT
                Enable booting directly to an OS from SPL.
                See also: doc/README.falcon

I'm not interested in **falcon** mode right now (a **TODO** that requires some additional setup).

Instead, I want the **MLO** to load the **u-boot.img**.

Following convention, **CONFIG_SPL_OS_BOOT** can be removed in the board configuration header `u-boot/include/configs/am335x_evm.h`.

Here's a patch that does it

        ~/bbb/u-boot$ git diff
        diff --git a/include/configs/am335x_evm.h b/include/configs/am335x_evm.h
        index 035c156..076b403 100644
        --- a/include/configs/am335x_evm.h
        +++ b/include/configs/am335x_evm.h
        @@ -417,6 +417,7 @@
                                        "128k(u-boot-env2),3464k(kernel)," \
                                        "-(rootfs)"
         #elif defined(CONFIG_EMMC_BOOT)
        +#undef CONFIG_SPL_OS_BOOT
         #undef CONFIG_ENV_IS_NOWHERE
         #define CONFIG_ENV_IS_IN_MMC
         #define CONFIG_SPL_ENV_SUPPORT


The **CONFIG_EMMC_BOOT** section applies to the BBB because of `u-boot/configs/am335x_boneblack_defconfig`.

Make sure to do a `distclean` after this configuration change.

        ~/bbb/u-boot$ make distclean
        ~/bbb/u-boot$ make am335x_boneblack_config
        ~/bbb/u-boot$ make [-j8]


Here's what the **MLO** output looks like now when booting from an SD card

        U-Boot SPL 2015.07-dirty (Jul 19 2015 - 10:59:52)
        reading u-boot.img
        reading u-boot.img

The multiple reads of u-boot.img happens because at first only the header is read and parsed to find the load address before a second read of the entire u-boot.img into the proper location. See the `spl_load_image_fat()` function in `u-boot/common/spl_fat.c`.

This warning

        *** Warning - bad CRC, using default environment

was also removed because `env_relocate_spec()` is no longer being called with the above patch which had an error handler at the bottom calling `u-boot\common\env_commmon.c:set_default_env()` with an argument of "bad CRC". 

The built-in default environment is sufficient for the **MLO**.

### Watching u-boot.img log

       U-Boot 2015.07 (Jul 19 2015 - 08:22:45 -0400)

               Watchdog enabled
       I2C:   ready
       DRAM:  512 MiB
       MMC:   OMAP SD/MMC: 0, OMAP SD/MMC: 1
       *** Warning - bad CRC, using default environment
       
       Net:   <ethaddr> not set. Validating first E-fuse MAC
       cpsw, usb_ether
       Hit any key to stop autoboot:  0
       U-Boot#



### What are those /dev/mmcblk[0|1]/boot[0|1] partitions ?


TO BE CONTINUED...
    

[uboot]: http://www.denx.de/wiki/U-Boot/
[bbb]: http://www.beagleboard.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[bbb-yocto]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Yocto.html
[bbb-kernel-work]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html