---
layout: post
title: Overo NAND Flash
description: "Working with NAND flash on Gumstix Overo systems"
date: 2014-03-17 14:00:00
categories: gumstix overo
tags: [linux, gumstix, overo, nand, flash]
---

The following Yocto packages have the tools for working with NAND
on the Overo.

* mtd-utils
* mtd-utils-jffs2
* mtd-utils-misc
* mtd-utils-ubifs


Use `mtd-info` to get information on available `MTD` devices

    root@overo:/usr/sbin# mtdinfo -a
    Count of MTD devices:           5
    Present MTD devices:            mtd0, mtd1, mtd2, mtd3, mtd4
    Sysfs interface supported:      yes
    
    mtd0
    Name:                           xloader
    Type:                           nand
    Eraseblock size:                131072 bytes, 128.0 KiB
    Amount of eraseblocks:          4 (524288 bytes, 512.0 KiB)
    Minimum input/output unit size: 2048 bytes
    Sub-page size:                  512 bytes
    OOB size:                       64 bytes
    Character device major/minor:   90:0
    Bad blocks are allowed:         true
    Device is writable:             false
    
    mtd1
    Name:                           uboot
    Type:                           nand
    Eraseblock size:                131072 bytes, 128.0 KiB
    Amount of eraseblocks:          14 (1835008 bytes, 1.8 MiB)
    Minimum input/output unit size: 2048 bytes
    Sub-page size:                  512 bytes
    OOB size:                       64 bytes
    Character device major/minor:   90:2
    Bad blocks are allowed:         true
    Device is writable:             true
    
    mtd2
    Name:                           uboot environment
    Type:                           nand
    Eraseblock size:                131072 bytes, 128.0 KiB
    Amount of eraseblocks:          2 (262144 bytes, 256.0 KiB)
    Minimum input/output unit size: 2048 bytes
    Sub-page size:                  512 bytes
    OOB size:                       64 bytes
    Character device major/minor:   90:4
    Bad blocks are allowed:         true
    Device is writable:             true
    
    mtd3
    Name:                           linux
    Type:                           nand
    Eraseblock size:                131072 bytes, 128.0 KiB
    Amount of eraseblocks:          64 (8388608 bytes, 8.0 MiB)
    Minimum input/output unit size: 2048 bytes
    Sub-page size:                  512 bytes
    OOB size:                       64 bytes
    Character device major/minor:   90:6
    Bad blocks are allowed:         true
    Device is writable:             true
    
    mtd4
    Name:                           rootfs
    Type:                           nand
    Eraseblock size:                131072 bytes, 128.0 KiB
    Amount of eraseblocks:          4012 (525860864 bytes, 501.5 MiB)
    Minimum input/output unit size: 2048 bytes
    Sub-page size:                  512 bytes
    OOB size:                       64 bytes
    Character device major/minor:   90:8
    Bad blocks are allowed:         true
    Device is writable:             true


The kernel board file

    ---  from <kernel-src>/arch/arm/mach-omap2/board-overo.c
    ...
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

    ...

    static void __init overo_init(void)
    {
        ...
        omap_nand_flash_init(0, overo_nand_partitions,
                             ARRAY_SIZE(overo_nand_partitions));
        ...
    }
    ...


The Yocto machine configuration file

    --- from meta-gumstix/conf/machine/overo.conf
    ...
    # tar.bz2 for SD card, UBI for nand
    IMAGE_FSTYPES ?= "tar.bz2 ubi"

    # The magic numbers:
    # 512 KiB flash = 4096 PEB (physical erase blocks) (PEB = 128 KiB sector)
    # Logical erase block is PEB minus 2 KiB (NAND page size) for metadata
    # Partitions reserve 4+14+2+64 for xloader/u-boot/env/linux
    # Remainder available for rootfs: 4012 PEBs
    MKUBIFS_ARGS = "-m 2048 -e 126KiB -c 4012"
    UBINIZE_ARGS = "-m 2048 -p 128KiB -s 512"

    UBI_VOLNAME = "rootfs"
    ...


The bootloader configuration file

    --- from <uboot-src>/include/configs/omap3_overo.h
    ...
    #define CONFIG_CMD_NAND         /* NAND support                 */
    ...
    
    #ifdef CONFIG_CMD_NAND
    
    #define CONFIG_CMD_MTDPARTS     /* MTD partition support */
    #define CONFIG_CMD_UBI          /* UBI-formated MTD partition support */
    #define CONFIG_CMD_UBIFS        /* Read-only UBI volume operations */
    
    #define CONFIG_RBTREE           /* required by CONFIG_CMD_UBI */
    #define CONFIG_LZO              /* required by CONFIG_CMD_UBIFS */
    
    #define CONFIG_MTD_DEVICE       /* required by CONFIG_CMD_MTDPARTS   */
    #define CONFIG_MTD_PARTITIONS   /* required for UBI partition support */
    
    /* NAND block size is 128 KiB.  Synchronize these values with
     * overo_nand_partitions in mach-omap2/board-overo.c in Linux:
     *  xloader              4 * NAND_BLOCK_SIZE = 512 KiB
     *  uboot               14 * NAND_BLOCK_SIZE = 1792 KiB
     *  uboot environtment   2 * NAND_BLOCK_SIZE = 256 KiB
     *  linux               64 * NAND_BLOCK_SIZE = 8 MiB
     *  rootfs              remainder
     */
    #define MTDIDS_DEFAULT "nand0=omap2-nand.0"
    #define MTDPARTS_DEFAULT "mtdparts=omap2-nand.0:"       \
            "512k(xloader),"                                \
            "1792k(u-boot),"                                \
            "256k(environ),"                                \
            "8m(linux),"                                    \
           "-(rootfs)"
    #else /* CONFIG_CMD_NAND */
    #define MTDPARTS_DEFAULT
    #endif /* CONFIG_CMD_NAND */
    ...
    
    /*
     * Board NAND Info.
     */
    #define CONFIG_SYS_NAND_QUIET_TEST
    #define CONFIG_NAND_OMAP_GPMC
    #define CONFIG_SYS_NAND_ADDR            NAND_BASE       /* physical address */
                                                            /* to access nand */
    #define CONFIG_SYS_NAND_BASE            NAND_BASE       /* physical address */
                                                            /* to access nand */
                                                            /* at CS0 */
    #define GPMC_NAND_ECC_LP_x16_LAYOUT
    
    #define CONFIG_SYS_MAX_NAND_DEVICE      1       /* Max number of NAND */
                                                    /* devices */
    ...
    
    /*-----------------------------------------------------------------------
     * FLASH and environment organization
     */
    
    /* **** PISMO SUPPORT *** */
    
    /* Configure the PISMO */
    #define PISMO1_NAND_SIZE                GPMC_SIZE_128M
    #define PISMO1_ONEN_SIZE                GPMC_SIZE_128M
    
    #define CONFIG_SYS_MONITOR_LEN          (256 << 10)     /* Reserve 2 sectors */
    
    #if defined(CONFIG_CMD_NAND)
    #define CONFIG_SYS_FLASH_BASE           PISMO1_NAND_BASE
    #endif
    
    /* Monitor at start of flash */
    #define CONFIG_SYS_MONITOR_BASE         CONFIG_SYS_FLASH_BASE
    #define CONFIG_SYS_ONENAND_BASE         ONENAND_MAP
    
    #define CONFIG_ENV_IS_IN_NAND
    #define ONENAND_ENV_OFFSET              0x240000 /* environment starts here */
    #define SMNAND_ENV_OFFSET               0x240000 /* environment starts here */
    
    #define CONFIG_SYS_ENV_SECT_SIZE        (128 << 10)     /* 128 KiB */
    #define CONFIG_ENV_OFFSET               SMNAND_ENV_OFFSET
    #define CONFIG_ENV_ADDR                 SMNAND_ENV_OFFSET
    ...
    
    /* NAND boot config */
    #define CONFIG_SYS_NAND_5_ADDR_CYCLE
    #define CONFIG_SYS_NAND_PAGE_COUNT      64
    #define CONFIG_SYS_NAND_PAGE_SIZE       2048
    #define CONFIG_SYS_NAND_OOBSIZE         64
    #define CONFIG_SYS_NAND_BLOCK_SIZE      (128*1024)
    #define CONFIG_SYS_NAND_BAD_BLOCK_POS   NAND_LARGE_BADBLOCK_POS
    #define CONFIG_SYS_NAND_ECCPOS          {2, 3, 4, 5, 6, 7, 8, 9,\
                                                    10, 11, 12, 13}
    #define CONFIG_SYS_NAND_ECCSIZE         512
    #define CONFIG_SYS_NAND_ECCBYTES        3
    #define CONFIG_NAND_OMAP_ECCSCHEME      OMAP_ECC_HAM1_CODE_HW
    #define CONFIG_SYS_NAND_U_BOOT_START    CONFIG_SYS_TEXT_BASE
    #define CONFIG_SYS_NAND_U_BOOT_OFFS     0x80000
    ...

u-boot environment

    Overo # print
    baudrate=115200
    bootcmd=mmc dev ${mmcdev}; if mmc rescan; then if run loadbootscript; then run bootscript; else if run loadbootenv; then run importbootenv; if test -n ${uenvcmd}; then echo Running uenvcmd ...;run uenvcmd;fi;fi;if run loaduimage; then run mmcboot; else run nandboot; fi; fi; else run nandboot; fi
    bootdelay=5
    bootscript=echo Running bootscript from mmc ...; source ${loadaddr}
    console=ttyO2,115200n8
    defaultdisplay=dvi
    dieid#=006400029ff80000016849a90103701e
    dvimode=1024x768MR-16@60
    ethact=smc911x-0
    ethaddr=00:15:c9:29:08:dc
    importbootenv=echo Importing environment from mmc${mmcdev} ...; env import -t ${loadaddr} ${filesize}
    loadaddr=0x82000000
    loadbootenv=fatload mmc ${mmcdev} ${loadaddr} uEnv.txt
    loadbootscript=fatload mmc ${mmcdev} ${loadaddr} boot.scr
    loaduimage=fatload mmc ${mmcdev} ${loadaddr} uImage
    mmcargs=setenv bootargs console=${console} ${optargs} mpurate=${mpurate} vram=${vram} omapfb.mode=dvi:${dvimode} omapdss.def_disp=${defaultdisplay} root=${mmcroot} rootfstype=${mmcrootfstype}
    mmcboot=echo Booting from mmc ...; run mmcargs; bootm ${loadaddr}
    mmcdev=0
    mmcroot=/dev/mmcblk0p2 rw
    mmcrootfstype=ext3 rootwait
    mpurate=500
    mtdparts=mtdparts=omap2-nand.0:512k(xloader),1792k(u-boot),256k(environ),8m(linux),-(rootfs)
    nandargs=setenv bootargs console=${console} ${optargs} mpurate=${mpurate} vram=${vram} omapfb.mode=dvi:${dvimode} omapdss.def_disp=${defaultdisplay} root=${nandroot} rootfstype=${nandrootfstype}
    nandboot=echo Booting from nand ...; run nandargs; nand read ${loadaddr} linux; bootm ${loadaddr}
    nandroot=ubi0:rootfs ubi.mtd=4
    nandrootfstype=ubifs
    stderr=serial
    stdin=serial
    stdout=serial
    vram=12M

    
Reformatting things a bit

##### bootcmd

    mmc dev ${mmcdev};
 
    if mmc rescan; then 
        if run loadbootscript; then 
            run bootscript; 
        else 
            if run loadbootenv; then 
                run importbootenv; 

                if test -n ${uenvcmd}; then 
                    echo Running uenvcmd ...;
                    run uenvcmd;
                fi;
            fi;

            if run loaduimage; then 
                run mmcboot; 
            else 
                run nandboot; 
            fi; 
        fi; 
    else 
        run nandboot; 
    fi

##### loadbootscript

    fatload mmc ${mmcdev} ${loadaddr} boot.scr

##### bootscript

    echo Running bootscript from mmc ...;
    source ${loadaddr}

##### loadbootenv

    fatload mmc ${mmcdev} ${loadaddr} uEnv.txt

##### importbootenv

    echo Importing environment from mmc${mmcdev} ...;
    env import -t ${loadaddr} ${filesize}

##### loaduimage

    fatload mmc ${mmcdev} ${loadaddr} uImage

##### mmcboot

    echo Booting from mmc ...;
    run mmcargs;
    bootm ${loadaddr}

##### nandboot

    echo Booting from nand ...;
    run nandargs;
    nand read ${loadaddr} linux;
    bootm ${loadaddr}


##### nand-flash.script

    echo Erasing NAND flash
    nand erase.chip

    echo Writing MLO
    fatload mmc 0 ${loadaddr} MLO
    nandecc hw
    nand write ${loadaddr} 0 20000
    nand write ${loadaddr} 20000 20000
    nand write ${loadaddr} 40000 20000
    nand write ${loadaddr} 60000 20000

    echo Writing u-boot.img
    fatload mmc 0 ${loadaddr} u-boot.img
    nandecc hw
    nand write ${loadaddr} 80000 ${filesize}

    echo Erasing u-boot environment
    nand erase 240000 20000

    echo Writing uImage
    fatload mmc 0 ${loadaddr} uImage
    nand write ${loadaddr} 280000 ${filesize}

    echo Finish mmc boot
    run loaduimage
    run mmcboot


Compiling the `nand-flash.script`

    mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n $1 -d $1 boot.scr