---
layout: post
title: FreeBSD Duovero Common DTS for OMAP4
description: "Where the heck do those device tree numbers come from?"
date: 2015-01-11 10:30:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero, kernel]
---

Some notes from working on a *FreeBSD* [dts][flattened-device-tree-elinux] file for [TI OMAP4][omap4] boards.

This is a working document.

Where convenient, naming conventions and organization are taken from the *Linux* implementation in `omap4.dtsi`.

*FreeBSD* lacks device drivers for many of the *OMAP4* subsystems that *Linux* supports. I am leaving these out for now.

Properties that are specific to *FreeBSD* are noted.

The two boards that I am testing with, the [Gumstix Duovero][duovero] and the [TI PandaBoard][pandaboard], are both *OMAP4430* systems.

*OMAP4460* boards like the *PandaBoard ES* or some boards from [Variscite][variscite-cortexa9] exist, but I don't own any and haven't tested.

Hardware differences between the boards are handled by board specific `dts` files (`duovero.dts`, `pandaboard.dts`) that include this base `omap443x.dtsi`. I'll cover these at the end of this document.

### References

1. [OMAP4430 ES2.x Technical Reference Manual [Public] (Rev. AP)][omap4430-trm]
2. [OMAP4460 ES1.x Technical Reference Manual [Public] (Rev. AB)][omap4460-trm]
3. [Cortex-A9 MPCore Technical Reference Manual (Rev. r4p1)][cortexa9-mpcore-trm]
4. Linux 3.18 [dts files][linux-3.18-dts] particularly [arm/arm/boot/dts/omap4.dtsi][omap4-dtsi]
5. FreeBSD *CURRENT* [dts files][freebsd-current-dts] particularly [sys/boot/fdt/dts/arm/pandaboard.dts][old-pandaboard-dts]


Here is the latest [omap443x.dtsi][omap443x-dtsi] I'm working with.

And here is the breakdown
  
### Top level
    / {
        \#address-cells = <1>;
        \#size-cells = <1>;

        compatible = "ti,omap4430", "ti,omap4";
        interrupt-parent = <&gic>;

**Description**

These two properties come from a [skeleton.dtsi][linux-skeleton-dtsi] in *Linux*. *FreeBSD* does not have an equivalent.

The default is one *address* cell and one *size* cell for each device (*reg* property).

    #address-cells = <1>
    #size-cells = <1>


Used in `sys/arm/ti/ti_machdep.c`
 
    compatible = "ti,omap4430", "ti,omap4"


The *gic* is the only interrupt controller defined so it is the *interrupt-parent* for all children. Added here so it doesn't need to be repeated at lower levels.

    interrupt-parent = <&gic>


### General Interrupt Controller

    gic: interrupt-controller@48241000 {
        compatible = "arm,cortex-a9-gic";
        interrupt-controller;
        #interrupt-cells = <1>;
        reg = <0x48241000 0x1000>,
              <0x48240100 0x0100>;
        };

**Description**

Used in `sys/arm/arm/gic.c`

    compatible = "arm,cortex-a9-gic"


Unsure. Is this just declaring the device as capable of being an *interrupt-controller* ?
Gpio controllers also have this property.

Used in `sys/dev/ofw/ofw_bus_subr.c`

    interrupt-controller

*interrupt-cells* is the number of values the *interrupts* properties will have in child nodes. 

*FreeBSD* is still using **<1>**, just the irq number from a flat IRQ address space. The result is *SPI* irqs are +32 and *PPI* irqs are +16 from their *Linux* equivalents. 

Support exists in `sys/arm/arm/gic.c` for the the expanded *controller, irq, irq-type* definition for *interrupts* that *Linux* uses. This value will change to **<3>** if/when conversion to the expanded *interrupts* definition happens.

Used in `sys/arm/arm/gic.c` 

    interrupt-cells = <1>


Memory offsets and sizes come from  (1) page 1093, table 4-14.

Additional information can be found in (3). 

*0x48241000* is the interrupt distributor interface, (3) table 1-3 and section 3.1.2. This is the region used for both **PPI** (private, per core) and **SPI** (shared peripheral) interrupt processing.

*0x48240100* is the interrupt controller interface, (3) table 1-3 and section 3.1
 
Used in `sys/arm/arm/gic.c`

    reg = <0x48241000 0x1000>,
          <0x48240100 0x0100>


### L2 PL310 Cache Controller

    L2: l2-cache-controller@48242000 {
        compatible = "arm,pl310-cache";
        reg = <0x48242000 0x1000>;
        interrupts = <32>;
        cache-level = <2>;
    };

**Description**

Used in `sys/arm/arm/pl310.c`

    compatible = "arm,pl310-cache"

The memory address and size come from (1) page 1093, Table 4-14

Used in `sys/arm/arm/pl310.c`

    reg = <0x48242000 0x1000>

From (1), Section 17.3.2, Table 17-2

* MA_IRQ_0 : L2_CACHE_IRQ


The interrupt is for cache debugging on *FreeBSD*. This interrupt is not declared in the *Linux* cache controller node.

Used in `sys/arm/arm/pl310.c`

    interrupts = <32>

The *PL310* controller is an *L2 cache*, but I couldn't find where this property is actually used.

    cache-level = <2>


### SOC

    soc: omap4430 {
        #address-cells = <1>;
        #size-cells = <1>;
        compatible = "simple-bus";
        ranges;
        bus-frequency = <0>;

**Description**

I thought these might be inherited from the top-level, but they are not. The board won't boot without these 2 properties defined again at this level.

    #address-cells = <1>
    #size-cells = <1>

This is a [simplebus(4)][simplebus] device. Children should be iterated over to find their individual resources.

    compatible = "simple-bus"

An empty *ranges* property means parent and child address spaces are mapped *1:1*

    ranges;

I'm not sure how the *bus-frequency* property is used by *FreeBSD* for the OMAP4. 

There is reference to it in `sys/boot/fdt/fdt_loader_cmd.c` in the *sounds relevant* `fdt_fixup_cpubusfreqs()` function. 

Maybe it is only for dtb's loaded at runtime by u-boot?

At least for *dts* files built into the kernel, you can remove the *bus-frequency* property from the *dtsi* and there is no change to behavior.

    bus-frequency = <0>


The remaining nodes are all children of the *soc*.

### PRCM

The power, reset and clock management module.

    omap4_prcm@4a306000 {
        compatible = "ti,omap4_prcm";
        reg = <0x4a306000 0x2000
               0x4a004000 0x1000
               0x4a008000 0x2000
               0x4a30a000 0x0520>;
    };

**Description**

Used in `sys/arm/ti/omap4/omap4_prcm_clks.c`

    compatible = "ti,omap4_prcm"

The register definitions are for

* prm@4a306000  - device-level power and reset management 
* cm1@4a004000  - device-level clock management 1
* cm2@4a008000  - device-level clock management 2
* scrm@4a30a000 - system-level clock and reset distribution and management

Addresses and sizes come from

* prm@4a306000  - (1) page 563, Table 3-360,   0x4a30 6000 - 7fff (0x2000)
* cm1@4a004000  - (1) page 795, Table 3-932,   0x4a00 4000 - 4fff (0x1000)
* cm2@4a008000  - (1) page 882, Table 3-1130,  0x4a00 8000 - 9fff (0x2000)
* scrm@4a30a000 - (1) page 1043, Table 3-1489, 0x4a30 a000 - a51f (0x0520)

The *Linux* [omap4.dtsi][omap4-dtsi] declares the **CM2** size to be **0x3000**, but the *FreeBSD*
[pandaboard.dts][old-pandaboard-dts] declares the **CM2** size to be **0x8000**.

From the [TRM][omap4430-trm], I think they are both wrong and that the correct size is **0x2000**.

The [omap4.dtsi][omap4-dtsi] also declares the **SCRM** size to be **0x2000**.

I added a register definition for the **SCRM** to *FreeBSD* and some code in `omap4_prcm_clks.c` to use it. But the size I get from (1) is **0x0520**, so that's what I used.

The register regions for the **PRCM** are not changed in [OMAP4460 TRM][omap4460-trm].

It's always possible the *Linux* sources are correct since the TI developers have access to non-public documentation. I haven't seen usage of any undocumented **PRCM** regs in *FreeBSD*, so I'm going with the documented numbers.

Used in `sys/arm/ti/omap4/omap4_prcm_clks.c`

    reg = <0x4a306000 0x2000
           0x4a004000 0x1000
           0x4a008000 0x2000
           0x4a30a000 0x0520>

### Timers

Definitions for the core Global and Local timers. 

These are **NOT** the *General Purpose* or *32-kHZ Synchronized* timers from Section 22 of (1).
 
    mp_tmr@48240200 {
        compatible = "arm,mpcore-timers";
        reg = <0x48240200 0x100>,
              <0x48240600 0x100>;
        interrupts = <27 29>;
    };

**Description**

Used in `sys/arm/mpcore_timer.c`

    compatible = "arm,mpcore-timers"

-- There must be an easier way to find these values --

From (3) Table 1-3

* **PERIPHBASE[31:13]** + 0x0200-0x02ff is the *Global Timer*

* **PERIPHBASE[31:13]** + 0x0600-0x06ff is the for *Private timers* and *watchdog*

So **PERIPHBASE[31:13]** must be **0x48240000**. Table A-6 from (3) has a description on where to read it.

    reg = <0x48240200 0x100>,
          <0x48240600 0x100>
    

From (3) Section 3.1.2

Global timer, PPI(0) - The global timer uses **ID27**.

Private timer, PPI(2) - Each Cortex-A9 processor has its own private timers that can generate interrupts, using **ID29**.

    interrupts = <27 29>

Since these are **PPI** (private, peripheral interrupts), *Linux* uses **GIC\_PPI + 13** for the Private timers. 

The Global timer is not configured in [omap4.dtsi][omap4-dtsi]. Not sure if *Linux* uses the Global timer.

### SDMA

    sdma: dma-controller@x4a056000 {
        compatible = "ti,omap4430-sdma", "ti,sdma";
        reg = <0x4A056000 0x1000>;
        interrupts = <44 45 46 47>;
    };


**Description**

Only "ti,sdma" is used in `sys/arm/ti/ti_sdma.c`. A *compat* list could be added so that the *Linux* name "ti,omap4430-sdma" could be used.

I listed both for now. 

    compatible = "ti,omap4430-sdma", "ti,sdma"

From (1), Section 16.6.1, Table 16-22

    reg = <0x4A056000 0x1000>
 
From (1), Section 17.3.2, Table 17-2

* MA\_IRQ\_12 : SDMA\_IRQ\_0
* MA\_IRQ\_13 : SDMA\_IRQ\_1
* MA\_IRQ\_14 : SDMA\_IRQ\_2
* MA\_IRQ\_15 : SDMA\_IRQ\_3

The *FreeBSD* values using a flat IRQ address space are

    interrupts = <44 45 46 47>

### GPIO

    GPIO: gpio {
        compatible = "ti,omap4-gpio";
        reg = <0x4a310000 0x1000
               0x48055000 0x1000
               0x48057000 0x1000
               0x48059000 0x1000
               0x4805b000 0x1000
               0x4805d000 0x1000>;
        interrupts = <61 62 63 64 65 66>;
        gpio-controller;
        #gpio-cells = <3>;
    };

**Description**

There are 6 GPIO *banks* with 32 pins per bank for a total of 192 GPIO. Each *bank* has a controller with 2 interrupt lines, one for the *DSP* and one shared between the *MPU* and *Cortex-M3* subsystems.

Because of pin multiplexing, only a small subset of pins are usable as GPIO on any particular board.

Used in `sys/arm/ti/omap4/omap4_gpio.c`

    compatible = "ti,omap4-gpio";

From (1), Section 25.6.1, Table 25-17

The *Linux* `omap4.dtsi` uses a size of **0x200** for each bank which is sufficient if you look at the last register for each bank controller. For consistency, I'm sticking with the TRM (1) declared size for the gpio register memory region.

    reg = <0x4a310000 0x1000
           0x48055000 0x1000
           0x48057000 0x1000
           0x48059000 0x1000
           0x4805b000 0x1000
           0x4805d000 0x1000>;

From (1), Section 17.3.2, Table 17-2

* MA_IRQ_29 : GPIO1_MPU_IRQ
* MA_IRQ_30 : GPIO2_MPU_IRQ
* MA_IRQ_31 : GPIO3_MPU_IRQ
* MA_IRQ_32 : GPIO4_MPU_IRQ
* MA_IRQ_33 : GPIO5_MPU_IRQ
* MA_IRQ_34 : GPIO6_MPU_IRQ
 
which results in

    interrupts = <61 62 63 64 65 66>;


Note: *Linux* breaks the 6 banks out into individual devices gpio0 - gpio5, much like the *uart*, *i2c* and *mmc* controllers are done below. The *FreeBSD* code needs some work to support this.

### UART

There are 4 UART devices defined in `omap443x.dtsi`.

I'm only showing *uart3*. The others are similar.

*uart3* is also the console for *Duovero* and *PandaBoard* boards.

Because I'm listing the uarts in the order [3, 1, 2, 4] in the *dts*, they show up this way in the O/S

* uart3 - `/dev/ttyu0` or `/dev/cuau0`
* uart1 - `/dev/ttyu1` or `/dev/cuau1`
* uart2 - `/dev/ttyu2` or `/dev/cuau2`
* uart4 - `/dev/ttyu3` or `/dev/cuau3`

I'm listing *uart3* first because I haven't figured out how to change the *console* to something other then the first *UART* listed in the *dts*.

    uart3: serial@48020000 {
        compatible = "ti,omap4-uart", "ti,ns16550";
        reg = <0x48020000 0x400>;
        reg-shift = <2>;
        interrupts = <106>;
        clock-frequency = <48000000>;
        uart-device-id = <2>;
    };

**Properties**

Declared in `sys/dev/uart/uart_bus_fdt.c`

*Linux* uses **ti,omap4-uart**.

    compatible = "ti,omap4-uart", "ti,ns16550"

From (1), Section 23.3.6.1, Table 23-165

    reg = <0x48020000 0x400>

From (1), Section 23.3.1.1

    clock-frequency = <48000000>

Used in `sys/dev/uart/uart_bus_fdt.c`

    reg-shift = <2>


From (1), Section 17.3.2, Table 17-2

* MA_IRQ_74 : UART3_IRQ
 
which results in

    interrupts = <106>

Used in `sys/dev/uart/uart_dev_ti8250.c`

This is an offset to **UART0_CLK** (`sys/arm/ti/ti_prcm.h`) for enabling the correct clock in `sys/arm/ti/omap4/omap4_prcm_clks.c`

The clock register for *UART3* is from (1), Section 3.11.39.1, Table 3-1342
  
    uart-device-id = <3>


### I2C

There are 5 I2C controllers on the *OMAP4*, 4 of which are available for general purpose use. The fifth I2C controller is dedicated for use with the 
[TWL6030][twl6030] power management unit.

I'm only showing *i2c1*. The others are similar.

    i2c1: i2c@48070000 {
        compatible = "ti,omap4-i2c", "ti,i2c";
        reg = <0x48070000 0x100>;
        interrupts = <88>;
        i2c-device-id = <1>;
        clock-frequency = <100000>;
    };


**Description**

Used in `sys/arm/ti/ti_i2c.c`.

Linux uses *ti,omap4-i2c*.

    compatible = "ti,omap4-i2c", "ti,i2c"

From (1) Section 23.1.6.1, Table 23-30

    reg = <48070000 0x100>

From (1), Section 17.3.2, Table 17-2

    interrupts = <88>

Used in `sys/arm/ti/ti_i2c.c` to enable the clock for this device as an offset from *I2C0_CLK*.

    i2c-device-id = <1>

*FreeBSD* only. Allows setting a default I2C bus speed in the dts. You can also change the bus speed through [sysctl(8)][sysctl].

    clock-frequency = <100000>
 

### MMC

    mmc1: mmc@x4809C000 {
        compatible = "ti,omap4-hsmmc";
        reg = <0x4809C000 0x1000>;
        interrupts = <115>;
        mmchs-device-id = <1>;
        non-removable;
    };

**Description**

There are 5 MMC controllers.

I'm only declaring the first one, which has dedicated hardware for an SD card on both the *Duovero* and *PandaBoard*.
   
Used in `sys/arm/ti/ti_sdhci.c`

    compatible = "ti,omap4-hsmmc"

From (1), Table 24-56

Used in `sys/arm/ti/ti_sdhci.c`

    reg = <0x4809C000 0x1000>

From (1), Table 17-2

* MA_IRQ_83 : MMC1_IRQ

which results in

    interrupts = <115>

*FreeBSD* only property. Can be omitted if the MMC devices are listed in the dts file in proper order.

Used in `sys/arm/ti/ti_sdhci.c`

    mmchs-device-id = <1>

*FreeBSD* only.

Used in `sys/arm/ti/ti_sdhci.c`

    non-removable


[flattened-device-tree-elinux]: http://elinux.org/Device_Tree
[omap4]: http://www.ti.com/general/docs/wtbu/wtbuproductcontent.tsp?contentId=53243&navigationId=12843&templateId=6123
[freebsd]: http://www.freebsd.org
[duovero]: https://store.gumstix.com/index.php/category/43/
[pandaboard]: https://en.wikipedia.org/wiki/PandaBoard
[variscite-cortexa9]: http://www.variscite.com/products/system-on-module-som/cortex-a9
[omap4430-trm]: http://www.ti.com/lit/pdf/swpu231
[omap4460-trm]: http://www.ti.com/lit/pdf/swpu235
[cortexa9-mpcore-trm]: http://infocenter.arm.com/help/topic/com.arm.doc.ddi0407i/DDI0407I_cortex_a9_mpcore_r4p1_trm.pdf
[linux-3.18-dts]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts?id=refs/tags/v3.18.3
[omap4-dtsi]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts/omap4.dtsi?id=refs/tags/v3.18.3
[freebsd-current-dts]: https://svnweb.freebsd.org/base/head/sys/boot/fdt/dts/arm/
[old-pandaboard-dts]: https://svnweb.freebsd.org/base/head/sys/boot/fdt/dts/arm/pandaboard.dts?revision=264096&view=markup
[omap443x-dtsi]: https://gist.github.com/scottellis/43a18509af1b05ce3565
[linux-skeleton-dtsi]: https://git.kernel.org/cgit/linux/kernel/git/stable/linux-stable.git/tree/arch/arm/boot/dts/skeleton.dtsi?id=refs/tags/v3.18.3
[simplebus]: https://www.freebsd.org/cgi/man.cgi?query=simplebus&apropos=0&sektion=4&manpath=FreeBSD+11-current&arch=default&format=html
[sysctl]: https://www.freebsd.org/cgi/man.cgi?query=sysctl&apropos=0&sektion=8&manpath=FreeBSD+11-current&arch=default&format=html
[twl6030]: http://www.ti.com/product/twl6030
