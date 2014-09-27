---
layout: post
title: Erasing the Overo U-Boot Environment
description: "Erasing the Overo U-Boot environment from NAND"
date: 2014-02-25 09:30:00
categories: gumstix overo
tags: [linux, gumstix, overo, u-boot]
---

If you upgrade the [bootloader][uboot] on your [Gumstix Overo][overo], it is a good idea to also erase the old [U-Boot environment][uboot-env] in NAND flash when you first boot the new system.

A common problem is errors when the old environment tries to reference functions that have been renamed or no longer exist in the new bootloader.

This only applies to Gumstix COMs that have NAND flash.

To erase the NAND, setup a console connection, boot the board and stop the boot during the U-Boot countdown.

At the u-boot command prompt, run the following

    Overo # nand erase 240000 20000

    NAND erase: device 0 offset 0x240000, size 0x20000
    Erasing at 0x240000 -- 100% complete.
    OK

Then reset the board and stop in u-boot again

    Overo # reset

At this point, the environment in u-boot is coming from the one built into u-boot when it was compiled. You should have gotten a scary error like this telling you so

    *** Warning - bad CRC, using default environment

To avoid this message you can save the current *in-memory* environment to NAND this way

    Overo # saveenv

Then either reset again like this

    Overo # reset

or just finish booting

    Overo # boot


Those magic numbers **240000** and **20000** come from a config file in the U-Boot source

    --- excerpt from include/configs/omap3_overo.h ---
    #define CONFIG_ENV_IS_IN_NAND
    #define ONENAND_ENV_OFFSET              0x240000 /* environment starts here */
    #define SMNAND_ENV_OFFSET               0x240000 /* environment starts here */
    
    #define CONFIG_SYS_ENV_SECT_SIZE        (128 << 10)     /* 128 KiB */
    #define CONFIG_ENV_OFFSET               SMNAND_ENV_OFFSET
    #define CONFIG_ENV_ADDR                 SMNAND_ENV_OFFSET


(128 << 10) = 131072 = 0x20000

The full view of the Overo NAND layout is seen here from the Linux kernel source

    --- excerpt from arch/arm/mach-omap2/board-overo.c

    static struct mtd_partition overo_nand_partitions[] = {
        {
            .name           = "xloader",
            .offset         = 0,                    /* Offset = 0x00000 */
            .size           = 4 * NAND_BLOCK_SIZE,
            .mask_flags     = MTD_WRITEABLE
        },
        {
            .name           = "uboot",
            .offset         = MTDPART_OFS_APPEND,   /* Offset = 0x80000 */
            .size           = 14 * NAND_BLOCK_SIZE,
        },
        {
            .name           = "uboot environment",
            .offset         = MTDPART_OFS_APPEND,   /* Offset = 0x240000 */
            .size           = 2 * NAND_BLOCK_SIZE,
        },
        {
            .name           = "linux",
            .offset         = MTDPART_OFS_APPEND,   /* Offset = 0x280000 */
            .size           = 64 * NAND_BLOCK_SIZE,
        },
        {
            .name           = "rootfs",
            .offset         = MTDPART_OFS_APPEND,   /* Offset = 0xa80000 */
            .size           = MTDPART_SIZ_FULL,
        },
    };

And from `arch/arm/mach-omap2/common-board-devices.h`

    #define NAND_BLOCK_SIZE  SZ_128K

SZ_128K = 131072 = 0x20000


If you are booting from an SD card, you are usually only using the *uboot environment* section of the NAND. 

The other pieces *MLO (xloader)*, *u-boot*, *kernel* and *rootfs* typically all come from the SD card when you are using one.


[overo]: https://store.gumstix.com/index.php/category/33/
[uboot]: http://en.wikipedia.org/wiki/Das_U-Boot
[uboot-env]: http://www.denx.de/wiki/view/DULG/UBootEnvVariables