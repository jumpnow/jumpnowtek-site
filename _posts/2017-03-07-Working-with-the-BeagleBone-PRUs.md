---
layout: post
title: Working with the Beaglebone Black PRU using UIO
date: 2017-03-07 14:30:00
categories: beaglebone
tags: [linux, beaglebone, bbb, pru, pruss-uio, buildroot]
---

As I am sure anyone interested in reading this post knows, the BeagleBone Black and associated family of boards come with two [PRU 200 MHz 32-bit microcontrollers][bbb-pru] that can be used to control or access hardware that has 'real-time' requirements.

There are currently two approaches to working with the PRUs

* [UIO][uio-pruss]
* [remoteproc][RPMsg]

This post will be about using the UIO interface.

The system and in particular the kernel I'm working with come from a Buildroot system I built using [these instructions][bbb-buildroot].

You could do the same with a [Yocto system][bbb-yocto], it's just that Buildroot systems are a bit easier to get started with and to explain.

The kernel has a patch and config that enables the **uio\_pruss** driver.

The kernel also has the configuration of **P9.19** and **P9.20** as I2C cape manager pins removed, so those pins are also available for PRU use.

There is an `am33xx-pruss-uio.dtsi` included that can be used to enable the **uio\_pruss** driver.

To get started, included in the image is a device tree file that I will use as the basis for the following PRU examples. The dts includes the `am33xx-pruss-uio.dtsi`.
 
    /dts-v1/;

    #include "am33xx.dtsi"
    #include "am335x-bone-common.dtsi"
    #include "am33xx-pruss-uio.dtsi"

    / {
            compatible = "ti,am335x-bone-green", "ti,am335x-bone-black", "ti,am335x-bone", "ti,am33xx";
    };

    &ldo3_reg {
            regulator-min-microvolt = <1800000>;
            regulator-max-microvolt = <1800000>;
            regulator-always-on;
    };

    &mmc1 {
            vmmc-supply = <&vmmcsd_fixed>;
    };

    &rtc {
            system-power-controller;
    };


I called it `bbb-pru-minimal.dts` and you can find the source for it in the kernel tree

    ti-linux-kernel/arch/arm/boot/dts/bbb-pru-minimal.dts

This simple dts frees up most of the PRU pins available from the BeagleBone headers including all the display and eMMC pins. It can be used with any BBB or BBG board.

On the Buildroot system, you'll find dtb's under `/boot`

    # ls /boot
    am335x-boneblack.dtb  bbb-pru-minimal.dtb
    am335x-bonegreen.dtb  zImage

To use the `bbb-pru-minimal.dtb` edit `/mnt/uEnv.txt` and set the **fdtfile** variable

    # vi /mnt/uEnv.txt
	...
    fdtfile=bbb-pru-minimal.dtb
	...

	
After a reboot you should see these kernel drivers loaded
	
	# lsmod
    Module                  Size  Used by    Not tainted
    uio_pruss               4356  0
    uio                     9528  1 uio_pruss

And these new devices

	# ls /dev/uio*
    /dev/uio0  /dev/uio2  /dev/uio4  /dev/uio6
    /dev/uio1  /dev/uio3  /dev/uio5  /dev/uio7


The next step is to write a program for the PRU cpu and start it from the ARM cpu running Linux.

When using the PRU UIO interface we need a user program to load and start the PRU application and we need a PRU executable binary.

I'm using a basic PRU **loader** application (source taken from numerous examples on the web).

    /*
     * Loads a PRU executable binary, runs it, and waits for completion.
     */

    #include <stdio.h>
    #include <stdlib.h>
    #include <prussdrv.h>
    #include <pruss_intc_mapping.h>

    int main(int argc, char **argv)
    {
        if (argc != 2) {
            printf("Usage: %s loader <pruprog>.bin\n", argv[0]);
            return 1;
        }

        prussdrv_init();

        if (prussdrv_open(PRU_EVTOUT_0) == -1) {
            printf("prussdrv_open() failed\n");
            return 1;
        }

        tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;

        prussdrv_pruintc_init(&pruss_intc_initdata);

        printf("Executing program and waiting for termination\n");

        if (prussdrv_exec_program(PRU0, argv[1]) < 0) {
            fprintf(stderr, "Error loading %s\n", argv[1]);
            exit(-1);
        }

        // Wait for the PRU to let us know it's done
        prussdrv_pru_wait_event(PRU_EVTOUT_0);
        printf("Done\n");

        prussdrv_pru_disable(PRU0);
        prussdrv_exit();

        return 0;
    }

Using the Buildroot cross-compiler

    ~/pru-code/loader$ export PATH=/br5/bbb/host/user/bin:${PATH}

the following `Makefile` builds the loader application

    TARGET = loader

    LIBS = -lprussdrv

    CC = arm-linux-gcc

    $(TARGET) : loader.c
            $(CC) loader.c $(LIBS) -o $(TARGET)

    clean:
            rm -f $(TARGET)

Build and copy the `loader` to the BBB (substitute your BBB's IP)

    ~/pru-code/loader$ export PATH=/br5/bbb/host/usr/bin:${PATH}

    ~/pru-code/loader$ make
    arm-linux-gcc loader.c -lprussdrv -o loader

    ~/pru-code/loader$ scp loader root@192.168.10.115:/root
    loader                                       100% 7988


Buildroot provides a package for the Texas Instruments CGT PRU compiler.
  
    config BR2_PACKAGE_HOST_TI_CGT_PRU
            bool "host ti-cgt-pru"
            depends on BR2_PACKAGE_HOST_TI_CGT_PRU_ARCH_SUPPORTS
            help
              This package provides the Code Generation Tools for the PRU
              unit found on some TI processors e.g. AM3358.

              Note: this is a binary cross toolchain that runs on x86 hosts
              targeting PRU cores found alongside some ARM processors.

I have it included in the image.

This provides the `pasm` compiler for the PRUs. The `pasm` compiler is meant to be run from the host system, not the BBB.

Here's a simple PRU application that just loops for 20 times, with a 500 ms delay in each loop.

    ; Run a simple delay loop on the PRU

    .setcallreg r29.w0
    .origin 0
    .entrypoint START

    #define DELAY_COUNT 50000000
    #define LOOP_ITERATIONS 20

    START:
      MOV r1, LOOP_ITERATIONS

    MAIN_LOOP:
      CALL DELAY
      SUB r1, r1, 1
      QBNE MAIN_LOOP, r1, 0

      MOV r31.b0, 32 + 3

      HALT


    DELAY:
      MOV r0, DELAY_COUNT

    DELAY_LOOP:
      SUB r0, r0, 1
      QBNE DELAY_LOOP, r0, 0
      RET

Using the same Buildroot environment, the assembly file can be compiled with this `Makefile`

    TARGET = loop.bin

    $(TARGET) : loop.p
            pasm -b loop.p

    clean:
            rm -f loop.bin

Build and copy it to the BBB

    ~/pru-code/loop$ make
    pasm -b loop.p


    PRU Assembler Version 0.86
    Copyright (C) 2005-2013 by Texas Instruments Inc.


    Pass 2 : 0 Error(s), 0 Warning(s)

    Writing Code Image of 11 word(s)

    ~/pru-code/loop$ scp loop.bin root@192.168.10.115:/root
    loop.bin                                                                   

Over on the BBB

    # ls -l
    total 9
    -rwx------    1 root     root          7988 Dec 31 19:25 loader
    -rw-------    1 root     root            44 Dec 31 19:50 loop.bin

Load and run the PRU app like this

    # ./loader loop.bin
    Executing program and waiting for termination
    Done

To doublecheck that we got the timing of the delay loop correct, 2 instructions @ 5ns each

    20 * ((2 x 0.000000005 sec) * 50,000,000) = 10 sec  

time the run
    
    # time ./loader loop.bin
    Executing program and waiting for termination
    Done
    real    0m 10.00s
    user    0m 0.00s
    sys     0m 0.00s



[bbb-buildroot]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Buildroot.html
[bbb-yocto]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Yocto.html
[bbb-pru]: http://elinux.org/Ti_AM33XX_PRUSSv2
[uio-pruss]: http://arago-project.org/git/projects/?p=linux-am33x.git;a=commit;h=f1a304e7941cc76353363a139cbb6a4b1ca7c737
[RPMsg]: http://omappedia.org/wiki/Category:RPMsg
[pru-code-generation-tools]: http://software-dl.ti.com/codegen/non-esd/downloads/download.htm#PRU