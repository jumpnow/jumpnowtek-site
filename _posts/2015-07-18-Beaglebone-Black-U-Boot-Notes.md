---
layout: post
title: BeagleBone Black U-Boot
description: "Some working notes on U-Boot for the BeagleBone Black"
date: 2015-07-18 14:30:00
categories: beaglebone 
tags: [linux, beaglebone, uboot]
---

Some notes on working with the [U-Boot][uboot] bootloader and [BeagleBone Black][bbb] boards.

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

### Why all the warnings from MLO? 

Here's what the **MLO** output looks like when booting from an SD card

        U-Boot SPL 2015.07 (Jul 19 2015 - 08:22:45)
        MMC: block number 0x100 exceeds max(0x0)
        MMC: block number 0x200 exceeds max(0x0)
        *** Error - No Valid Environment Area found
        *** Warning - bad CRC, using default environment
        
        reading u-boot.img
        reading u-boot.img

The warnings/errors are harmless, but annoying.

Here's why they show up

        MMC: block number 0x100 exceeds max(0x0)
        MMC: block number 0x200 exceeds max(0x0)
        *** Error - No Valid Environment Area found

These errors come from

        spl_start_uboot() from board/ti/am335x_board.c line 196
        |--- env_relocate_spec() from common/env_mmc.c line 209
             |--- read_env from common/env_mmc.c line 190
                  |--- mmc_bread() from drivers/mmc/mmc.c line 247

`mmc_bread()` is called twice.

This warning

        *** Warning - bad CRC, using default environment

comes from 

        env_relocate_spec() from common/env_mmc.c line 293
        |-- set_default_env() from common\env_commmon.c line 98


Here's the `spl_start_uboot()` function

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

which cause these warnings to always show when booting from an SD card...

The warning messages can be avoided entirely if the **CONFIG\_SPL\_OS\_BOOT** definition was removed.

From the `u-boot/README`

                CONFIG_SPL_OS_BOOT
                Enable booting directly to an OS from SPL.
                See also: doc/README.falcon

I'm not interested in **falcon** mode right now.

Instead, I want the **MLO** to load the **u-boot.img**.

Following convention, **CONFIG\_SPL\_OS\_BOOT** can be removed in the board configuration header `u-boot/include/configs/am335x_evm.h`.

Here's a one-liner patch that does it

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


The **CONFIG\_EMMC\_BOOT** section applies to the BBB because of `u-boot/configs/am335x_boneblack_defconfig`.

Make sure to do a `distclean` after this configuration change.

        ~/bbb/u-boot$ make distclean
        ~/bbb/u-boot$ make am335x_boneblack_config
        ~/bbb/u-boot$ make [-j8]


Here's what the **MLO** output looks like now when booting from an SD card

        U-Boot SPL 2015.07-dirty (Jul 19 2015 - 10:59:52)
        reading u-boot.img
        reading u-boot.img


**u-boot.img** really is read twice. 

At first just the header to find the proper load address. Then a second read that loads **u-boot.img** into the proper location. 

        board_init_r() from common/spl/spl.c line 206
        |-- spl_mmc_load_image() from common/spl/spl_mmc.c line 158
            |-- spl_load_image_fat() from common/spl_fat.c
                |-- file_fat_read() from fs/fat/fat.c


### What are those /dev/mmcblk[0|1]/boot[0|1] partitions ?

A couple of strange partitions show up on the *eMMC*.

They look like this booting from an SD card

        root@bbb:~# ls -l /dev/mmc*
        brw-rw---- 1 root disk 179,  0 Jul 20 04:15 /dev/mmcblk0
        brw-rw---- 1 root disk 179,  1 Jul 20 04:15 /dev/mmcblk0p1
        brw-rw---- 1 root disk 179,  2 Jul 20 04:15 /dev/mmcblk0p2
        brw-rw---- 1 root disk 179,  8 Jul 20 04:15 /dev/mmcblk1
        brw-rw---- 1 root disk 179, 16 Jul 20 04:15 /dev/mmcblk1boot0
        brw-rw---- 1 root disk 179, 24 Jul 20 04:15 /dev/mmcblk1boot1
        brw-rw---- 1 root disk 179,  9 Jul 20 04:15 /dev/mmcblk1p1
        brw-rw---- 1 root disk 179, 10 Jul 20 04:15 /dev/mmcblk1p2

Or like this booting from the **eMMC**

        root@beaglebone:~# ls -l /dev/mmc*
        brw-rw---- 1 root disk 179,  0 Dec 31  1999 /dev/mmcblk0
        brw-rw---- 1 root disk 179,  8 Dec 31  1999 /dev/mmcblk0boot0
        brw-rw---- 1 root disk 179, 16 Dec 31  1999 /dev/mmcblk0boot1
        brw-rw---- 1 root disk 179,  1 Dec 31  1999 /dev/mmcblk0p1
        brw-rw---- 1 root disk 179,  2 Dec 31  1999 /dev/mmcblk0p2


Here's what `fdisk` says about them

        root@bbb:~# fdisk -l /dev/mmcblk1boot0

        Disk /dev/mmcblk1boot0: 2 MiB, 2097152 bytes, 4096 sectors
        Units: sectors of 1 * 512 = 512 bytes
        Sector size (logical/physical): 512 bytes / 512 bytes
        I/O size (minimum/optimal): 512 bytes / 512 bytes


The `mmcblkboot` partitions may or may not have data in them when you initially receive a BBB.

I've cleared mine already.
 
        root@bbb:~# hexdump -C /dev/mmcblk0boot0
        00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
        *
        00200000

        root@bbb:~# hexdump -C /dev/mmcblk0boot1
        00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
        *
        00200000

Normally these partitions are read-only in Linux

        root@beaglebone:~# whoami
        root

        root@beaglebone:~# dd if=/dev/zero of=/dev/mmcblk0boot0 bs=512 count=8
        dd: error writing '/dev/mmcblk0boot0': Operation not permitted
        1+0 records in
        0+0 records out
        0 bytes (0 B) copied, 0.00966661 s, 0.0 kB/s

        root@beaglebone:~# dd if=/dev/zero of=/dev/mmcblk0boot1 bs=512 count=8
        dd: error writing '/dev/mmcblk0boot1': Operation not permitted
        1+0 records in
        0+0 records out
        0 bytes (0 B) copied, 0.00962403 s, 0.0 kB/s


A small patch to a `4.1.2` Linux kernel makes them writable so I can clear them with `dd` for the following tests.

        diff --git a/drivers/mmc/core/mmc.c b/drivers/mmc/core/mmc.c
        index f36c76f..f212eec 100644
        --- a/drivers/mmc/core/mmc.c
        +++ b/drivers/mmc/core/mmc.c
        @@ -417,7 +417,7 @@ static int mmc_decode_ext_csd(struct mmc_card *card, u8 *ext_csd)
                                        part_size = ext_csd[EXT_CSD_BOOT_MULT] << 17;
                                        mmc_part_add(card, part_size,
                                        EXT_CSD_PART_CONFIG_ACC_BOOT0 + idx,
        -                                       "boot%d", idx, true,
        +                                       "boot%d", idx, false,
                                                MMC_BLK_DATA_AREA_BOOT);
                                }
                        }


And here I've booted a kernel from an SD card with the above patch so `dd` now works.

        root@bbb:~# dd if=/dev/zero of=/dev/mmcblk1boot0 bs=512 count=8
        8+0 records in
        8+0 records out
        4096 bytes (4.1 kB) copied, 0.112604 s, 36.4 kB/s

        root@bbb:~# dd if=/dev/zero of=/dev/mmcblk1boot1 bs=512 count=8
        8+0 records in
        8+0 records out
        4096 bytes (4.1 kB) copied, 0.110132 s, 37.2 kB/s


So what are these partitions for and how are they normally populated?

TO BE CONTINUED...
    

[uboot]: http://www.denx.de/wiki/U-Boot/
[bbb]: http://www.beagleboard.org/
[meta-bbb]: https://github.com/jumpnow/meta-bbb
[bbb-yocto]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Yocto.html
[bbb-kernel-work]: http://www.jumpnowtek.com/beaglebone/Working-on-the-BeagleBone-kernel.html