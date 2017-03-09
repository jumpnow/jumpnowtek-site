---
layout: post
title: Working with the Beaglebone Black PRU using UIO
date: 2017-03-09 09:28:00
categories: beaglebone
tags: [linux, beaglebone, bbb, pru, pruss-uio, buildroot]
---

As I am sure anyone interested in reading this post knows, the BeagleBone Black and associated family of boards come with two [PRU 200 MHz 32-bit microcontrollers][bbb-pru] that can be used to control or access hardware that has 'real-time' requirements.

There are currently two approaches to working with the PRUs

* [UIO][uio-pruss]
* [remoteproc][RPMsg]

This post will be about using the UIO interface.

The system and in particular the kernel I'm working with come from a Buildroot system I built using [these instructions][bbb-buildroot].

You could do the same with a [Yocto system][bbb-yocto], it's just that Buildroot systems are a bit easier to get started with.

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

The application requires the **libprussdrv** library which comes from the [github.com/beagleboard/am335x-pru-package][am335x-pru-package]. This package is included in my Buildroot image.

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

The **am335x-pru-package** also provides the `pasm` compiler for the PRUs. The `pasm` compiler is meant to be run from the host system, not the BBB.

Here's a simple PRU application written in assembler that loops for 20 times, with a 500 ms delay in each loop.

    ; Run a simple delay loop on the PRU

    .setcallreg r29.w0
    .origin 0
    .entrypoint START

    #define PRU0_ARM_INTERRUPT 19

    #define DELAY_COUNT 50000000
    #define LOOP_ITERATIONS 20

    START:
      MOV r1, LOOP_ITERATIONS

    MAIN_LOOP:
      CALL DELAY
      SUB r1, r1, 1
      QBNE MAIN_LOOP, r1, 0

      MOV r31.b0, PRU0_ARM_INTERRUPT + 16 ; notify ARM we are done 

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

So that's the basic development system.

The other essential piece to any useful PRU application is setting up some pins for the PRUs to use.

Customizations to the device tree can handle this.

I have a [PRU Cape][ti-pru-cape] board which has some convenient components for testing the PRU hardware.

In particular, I'm going to work with the 4 LEDs accessible to PRU0 GPIOs 0-3.

These pins are accessible on the P9 header

* P9.31 : pr1_pru0_pru_r30_0
* P9.29 : pr1_pru0_pru_r30_1
* P9.30 : pr1_pru0_pru_r30_2
* P9.31 : pr1_pr10_pru_r30_3 

I'm going to create a new dts file to use these pins based on the `bbb-pru-minimal.dts`.

The changes are the **&am33xx_pinmux** and **&pruss** sections for the pinmux and to tell the pruss driver about the pins.

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

    &am33xx_pinmux {
            pruss_leds: pruss_leds {
                    pinctrl-single,pins = <
                            0x190 (PIN_OUTPUT_PULLDOWN | MUX_MODE5) /* P9.31 pr1_pru0_pru_r30_0 */
                            0x194 (PIN_OUTPUT_PULLDOWN | MUX_MODE5) /* P9.29 pr1_pru0_pru_r30_1 */
                            0x198 (PIN_OUTPUT_PULLDOWN | MUX_MODE5) /* P9.30 pr1_pru0_pru_r30_2 */
                            0x19c (PIN_OUTPUT_PULLDOWN | MUX_MODE5) /* P9.28 pr1_pru0_pru_r30_3 */
                    >;
            };
    };

    &pruss {
            pinctrl-names = "default";
            pinctrl-0 = <&pruss_leds>;
    };

Copy the dts to the kernel source directory, build it and then copy the dtb to the BBB.

    ~/pru-code/cylon$ cp bbb-pru-cylon.dts ~/ti-linux-kernel/arch/arm/boot/dts

    ~/pru-code/cycon$ cd ~/ti-linux-kernel

    ~/ti-linux-kernel$ make ARCH=arm CROSS_COMPILE=arm-linux- bbb-pru-cylon.dtb
    DTC     arch/arm/boot/dts/bbb-pru-cylon.dtb

    ~/ti-linux-kernel$ scp arch/arm/boot/dts/bbb-pru-cylon.dtb root@192.168.10.115:/boot
    bbb-pru-cylon.dtb                

Over on the BBB, modify `uEnv.txt` to use the new dtb.

    # ls /boot
    am335x-boneblack.dtb  bbb-pru-cylon.dtb     zImage
    am335x-bonegreen.dtb  bbb-pru-minimal.dtb

    # vi /mnt/uEnv.txt
    ...
    fdtfile=bbb-pru-cylon.dtb
    ...

And reboot.

And here is the PRU code to run the LEDs

    ; Blink some of the PRU cape LEDs in a cylon fashion

    .setcallreg r29.w0
    .origin 0
    .entrypoint START

    #define PRU0_ARM_INTERRUPT 19

    ; 25 * 10ns (2 instr) = 250 ms
    #define LED_DELAY 25000000

    #define CYLON_LOOPS 10

    START:
      MOV r1, CYLON_LOOPS ; total repeats

    CYLON:
      SET r30.t0  ; set GPIO output 0
      CALL LED_PAUSE
      CLR r30.t0
      SET r30.t1
      CALL LED_PAUSE
      CLR r30.t1
      SET r30.t2
      CALL LED_PAUSE
      CLR r30.t2
      SET r30.t3
      CALL LED_PAUSE
      CLR r30.t3
      SET r30.t2
      CALL LED_PAUSE
      CLR r30.t2
      SET r30.t1
      CALL LED_PAUSE
      CLR r30.t1

      SUB r1, r1, 1
      QBNE CYLON, r1, 0 ; loop until r1 = 0

      MOV r31.b0, PRU0_ARM_INTERRUPT + 16 ; notify ARM we are done

      HALT

    ; function to pause for LED_DELAY cycles
    LED_PAUSE:
      MOV r0, LED_DELAY
    DELAY:
      SUB r0, r0, 1
      QBNE DELAY, r0, 0
      RET

The `Makefile` to build `cylon.p`

    TARGET = cylon.bin

    $(TARGET) : cylon.p
            pasm -b cylon.p

    clean:
            rm -f cylon.bin


Build and copy it to the BBB

    ~/pru-code/cylon$ make
    pasm -b cylon.p


    PRU Assembler Version 0.86
    Copyright (C) 2005-2013 by Texas Instruments Inc.


    Pass 2 : 0 Error(s), 0 Warning(s)

    Writing Code Image of 28 word(s)

    ~/pru-code/cylon$ scp cylon.bin root@192.168.10.115:/root
    cylon.bin                                             


Over on the BBB

    # ls -l
    total 10
    -rw-------    1 root     root           112 Dec 31 19:08 cylon.bin
    -rwx------    1 root     root          7988 Dec 31  1999 loader
    -rw-------    1 root     root            44 Dec 31  1999 loop.bin

The same `loader` application can be used to run the cylon app.

    # ./loader cylon.bin
    Executing program and waiting for termination
    Done

And the D1-D4 LEDs on the PRU Cape board exhibit a little cylon scrolling behavior.


Buildroot provides a package for the Texas Instruments CGT PRU compiler.
  
    config BR2_PACKAGE_HOST_TI_CGT_PRU
            bool "host ti-cgt-pru"
            depends on BR2_PACKAGE_HOST_TI_CGT_PRU_ARCH_SUPPORTS
            help
              This package provides the Code Generation Tools for the PRU
              unit found on some TI processors e.g. AM3358.

              Note: this is a binary cross toolchain that runs on x86 hosts
              targeting PRU cores found alongside some ARM processors.

This provides the **clpru** C compiler for the PRUs. I have it included in the builds but have not tried it yet. Update your **PATH** to use it.

    export PATH=/br5/bbb/host/usr/share/ti-cgt-pru/bin:${PATH}


[bbb-buildroot]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Buildroot.html
[bbb-yocto]: http://www.jumpnowtek.com/beaglebone/BeagleBone-Systems-with-Yocto.html
[bbb-pru]: http://elinux.org/Ti_AM33XX_PRUSSv2
[uio-pruss]: http://arago-project.org/git/projects/?p=linux-am33x.git;a=commit;h=f1a304e7941cc76353363a139cbb6a4b1ca7c737
[RPMsg]: http://omappedia.org/wiki/Category:RPMsg
[pru-code-generation-tools]: http://software-dl.ti.com/codegen/non-esd/downloads/download.htm#PRU
[am335x-pru-package]: https://github.com/beagleboard/am335x_pru_package
[ti-pru-cape]: http://processors.wiki.ti.com/index.php/PRU_Cape_Getting_Started_Guide