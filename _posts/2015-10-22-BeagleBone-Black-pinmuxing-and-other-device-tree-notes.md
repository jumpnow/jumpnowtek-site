---
layout: post
title: BeagleBone Black pinmuxing and other device tree notes
description: "References for various dts registers and offsets"
date: 2016-01-19 10:00:00
categories: beaglebone
tags: [linux, beaglebone, device tree]
---

Collecting some notes on the source of various register, address and other *magic* numbers in the [BeagleBone Black][bbb] device tree definitions.

## References

1. AM335X Sitara Processors Datasheet [sprs717h.pdf][sprs717]
2. AM335x Sitara Processors Technical Reference Manual [spruh73k.pdf][spruh73]
3. From linux-stable 4.2.3 [arch/arm/boot/dts/am33xx.dtsi][am33xx.dtsi]
4. From linux-stable 4.2.3 [arch/arm/boot/dts/am335x-bone-common.dtsi][am335x-bone-common.dtsi]
5. From linux-stable 4.2.3 [arch/arm/boot/dts/am335x-boneblack.dts][am335x-boneblack.dts]

## PinMux Modes

Most of the AM335x pads can support multiple modes of operation.

The pinmux modes available for each pad come from the `sprs717` datasheet, Section 4.2, Table 4-1.

The BBB chips use the ZCZ package.

##### Example: **GPMC\_CSN1**

From the `sprs717` datasheet Table 4-1

	ZCZ Ball Number: U9
	Pin Name: GPMC_CSN1
	Mode 0: gpmc_csn1
	Mode 1: gpmc_clk
	Mode 2: mmc1_clk
	Mode 3: pr1_edi0_data_in6
	Mode 4: pr1_edio_data_out6
	Mode 5: pr1_pru1_pru_r30_12
	Mode 6: pr1_pru1_pru_r31_12
	Mode 7: gpio1_30

##### Example: **SPI0\_CS0**

From the `sprs717` datasheet Table 4-1

	ZCZ Ball Number: A16
	Pin Name: SPI0_CS0
	Mode 0: spi0_cs0
	Mode 1: mmc2_sdwp
	Mode 2: i2c1_scl
	Mode 3: ehrpwm0_synci
	Mode 4: pr1_uar0_txd
	Mode 5: pr1_edi0_data_in1
	Mode 6: pr1_edio_data_out1
	Mode 7: gpio0_5
	
## Pinmux Register Offsets

The pinmux register offsets come from the `spruh73` TRM, Section 9.3.1, Table 9-7.

Look up the pad with **conf_** prepended to the lower case pin name (mux mode 0).

The device tree pinmux definitions want the offset from the base of the control module.

This **0x800** base needs to be subtracted from the values in Table 9-7.
  
##### Example: UART0\_RXD and UART0\_TXD

From `am335x-bone-common.dtsi`

    uart0_pins: pinmux_uart0_pins {
        pinctrl-single,pins = <
            0x170 (PIN_INPUT_PULLUP | MUX_MODE0)    /* uart0_rxd.uart0_rxd */
            0x174 (PIN_OUTPUT_PULLDOWN | MUX_MODE0) /* uart0_txd.uart0_txd */
        >;
    };

From `spruh73` TRM, Table 9-7

	970h	conf_uart0_rxd
	974h	conf_uart0_txd


##### Example: eMMC clock (GPMC\_CSN1)

From `am335x-boneblack.dts`

    emmc_pins: pinmux_emmc_pins {
        pinctrl-single,pins = <
            0x80 (PIN_INPUT_PULLUP | MUX_MODE2) /* gpmc_csn1.mmc1_clk */
            0x84 (PIN_INPUT_PULLUP | MUX_MODE2) /* gpmc_csn2.mmc1_cmd */
			...
		>;
    };

From `spruh73` TRM, Table 9-7

	880h	conf_gpmc_csn1
 
	
##### Example: LCD\_VSYNC

From `am335x-boneblack.dts`

    nxp_hdmi_bonelt_pins: nxp_hdmi_bonelt_pins {
        pinctrl-single,pins = <
            ...
            0xe0 0x00       /* lcd_vsync.lcd_vsync, OMAP_MUX_MODE0 | AM33XX_PIN_OUTPUT */
		    ...
		>;
	};

From `spruh73` TRM, Table 9-7

	8e0h	conf_lcd_vsync

## DMA Event Channels
	
EDMA event definitions come from the `spruh73` TRM, Section 11.3.20, Table 11-23 Direct Mapped and Table 11-24 Crossbar Mapped.

Section 9.2.3, EDMA Event Multiplexing explains the purpose of the Crossbar Mapped table.

##### Example: mmc0 (mmc1 in dts)

From `am33xx.dtsi`
	
    mmc1: mmc@48060000 {
        compatible = "ti,omap4-hsmmc";
        ti,hwmods = "mmc1";
        ti,dual-volt;
        ti,needs-special-reset;
        ti,needs-special-hs-handling;
        dmas = <&edma 24
                &edma 25>;
        dma-names = "tx", "rx";
        interrupts = <64>;
        interrupt-parent = <&intc>;
        reg = <0x48060000 0x1000>;
        status = "disabled";
    };

From `spruh73` TRM, Table 11-23 Direct Mapped

	24	SDTXEVT0	MMCHS0
	25	SDRXEVT0	MMCHS0


##### Example: spi0
	
From `am33xx.dtsi`
	
    spi0: spi@48030000 {
        compatible = "ti,omap4-mcspi";
        #address-cells = <1>;
        #size-cells = <0>;
        reg = <0x48030000 0x400>;
        interrupts = <65>;
        ti,spi-num-cs = <2>;
        ti,hwmods = "spi0";
        dmas = <&edma 16
                &edma 17
                &edma 18
                &edma 19>;
        dma-names = "tx0", "rx0", "tx1", "rx1";
        status = "disabled";
    };

From `spruh73` TRM, Table 11-23 Direct Mapped

	16	SPIXEVT0	MCSPI0
	17	SPIREVT0	MCSPI0
	18	SPIXEVT1	MCSPI0
	19	SPIREVT1	MCSPI0
	
##### Example using crossbar: mmc2 (mmc3 in dts)

    &edma {
        ti,edma-xbar-event-map = /bits/ 16 <1 12
                                            2 13>;
    }

    &mmc3 {
        ...
        dmas = <&edma 12
                &edma 13>;
        dma-names = "tx", "rx";
        ...
    };

From `spruh73` TRM, Table 11-24 Crossbar Mapped

    1	SDTXEVT2	MMCHS2
	2	SDRXEVT2	MMCHS2

and from `spruh73` TRM, Table 11-23 Direct Mapped

    12	Open	Open
    13	Open	Open


## Interrupts
	
Interrupt numbers come from the `spruh73k` TRM, Section 6.3, Table 6-1

##### Example: gpio bank 0

From `am33xx.dtsi`

    gpio0: gpio@44e07000 {
        compatible = "ti,omap4-gpio";
        ti,hwmods = "gpio1";
        gpio-controller;
        #gpio-cells = <2>;
        interrupt-controller;
        #interrupt-cells = <2>;
        reg = <0x44e07000 0x1000>;
        interrupts = <96>;
    };

From `spruh73k` TRM, Table 6-1

	96		GPIOINT0A	GPI0		POINTRPEND1


##### Example: timer4

From `am33xx.dtsi`

    timer4: timer@48044000 {
        compatible = "ti,am335x-timer";
        reg = <0x48044000 0x400>;
        interrupts = <92>;
        ti,hwmods = "timer4";
        ti,timer-pwm;
    };

From `spruh73k` TRM, Table 6-1

	92		TINT4		DMTIMER4	POINTR_PEND

	
##### Example: i2c2

From `am33xx.dtsi`

    i2c2: i2c@4819c000 {
        compatible = "ti,omap4-i2c";
        #address-cells = <1>;
        #size-cells = <0>;
        ti,hwmods = "i2c3";
        reg = <0x4819c000 0x1000>;
        interrupts = <30>;
        status = "disabled";
    };


From `spruh73k` TRM, Table 6-1	

	30		I2C2INT		I2C2INT		POINTRPEND1


[bbb]: http://www.beagleboard.org/	
[sprs717]: http://www.ti.com/lit/sprs717
[spruh73]: http://www.ti.com/lit/spruh73
[am33xx.dtsi]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts/am33xx.dtsi?id=refs/tags/v4.2.3
[am335x-bone-common.dtsi]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts/am335x-bone-common.dtsi?id=refs/tags/v4.2.3
[am335x-boneblack.dts]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts/am335x-boneblack.dts?id=refs/tags/v4.2.3
