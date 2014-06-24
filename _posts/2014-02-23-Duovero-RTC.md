---
layout: post
title: Duovero Real-time Clock
description: "Working with the Duovero battery backed RTC"
date: 2014-02-23 08:49:00
categories: gumstix duovero
tags: [linux, gumstix, duovero, rtc]
---

The Gumxstix [Duovero][duovero] COMs have a power management unit (PMIC) that
supports a battery backed real-time clock. The [Parlor][parlor] expansion boards
come with a battery holder, but the default Gumstix 3.6 kernel does not support:

1. Communication with the RTC
2. Trickle charging the RTC battery from the PMIC

Here are some notes to get it working.

### Enabling communication with the RTC

First off, you should make sure you have **/sbin/hwclock** installed. It comes
from the **busybox** package for my systems.

You can check whether or not the hwclock communication is working this way

    root@duovero:~# hwclock -r
    Sun Feb 23 15:33:36 2014  0.000000 seconds

This is from a fixed system with the patches referenced below. A broken system
will return zeros for the date and time.
 
The following summary comes from a variety of web postings mainly from upstream
android and ti-omap kernel developers.

It's difficult to get information about the Duovero PMIC, the [TWL6030][twl6030].
The full programming reference manual is not publicly available the way it is
for the TWL4030.

This [manual][swcs045c] has some information about the RTC. The
**REAL-TIME CLOCK** section starting on page 32 has some information about the
actual time registers. 

The important information for this problem is under the 
**CONTROL INTERFACE (I2C, MSECURE, INTERRUPTS)** section and in particular the 
**Secure Registers** subsection starting on page 85.

The **MSECURE** control signal determines whether the RTC can be set or cleared.
 
Gumstix doesn't provide a schematic of the signals between the OMAP4 and the
TWL6030, but assuming they copied the [pandaboard design][pandaboard-schematic]
(or that they both copied some other reference design), pin N2 **MSECURE** of 
the TWL6030 goes directly to pin AD2, the **FREF\_CLK0\_OUT** pad of the OMAP4. 

Mode 3 of this pad is **SYS\_DRM\_MSECURE** which is what is required.

The default u-boot muxes this pad in mode 7, safe mode.

    {PAD0_FREF_CLK0_OUT, (M7)},          /* safe mode */

The change needed to fix the pad muxing can be done in u-boot or in the kernel.

This backported [patch][msecure-mux-patch] to the Gumstix 3.6 kernel does the
job.


### Enabling trickle charging the RTC battery from the PMIC

I found this [TWL6030 Register Manual][twl6030-register-manual] on a non-TI site.

From section 2.9, the **BBSPOR\_CFG** register is used to enable the RTC backup
battery trickle charge. By default the **BB\_CHG\_EN** bit is off. 

I'm using [Panasonic ML-621S/ZTN][duovero-battery] 3.0V batteries in my
Duoveros, so I wanted the trickle charge cutoff to be at 3.0V.

- BB\_CHG\_EN = 1
- BB\_SEL_1 = 0
- BB\_SEL_0 = 0

Given that, this kernel [patch][trickle-charge-patch] enables trickle charging
the Duovero RTC backup battery.

It's loosely based on a similar [patch][overo-trickle-charge-patch] to the 
TWL4030 for the Overo kernels.

### Init scripts

You need some additional userland software to ensure that

- system time gets restored from the RTC value on startup
- the RTC gets set to system time on shutdown

With Yocto built systems the **busybox-hwclock** package adds an init.d script
to do this. 

The script is called **/etc/init.d/hwclock.sh**.


[duovero]: https://store.gumstix.com/index.php/category/43/
[parlor]: https://store.gumstix.com/index.php/products/287/
[twl6030]: http://www.ti.com/product/twl6030
[swcs045c]: http://www.farnell.com/datasheets/1481246.pdf
[pandaboard-schematic]: http://pandaboard.org/sites/default/files/board_reference/pandaboard-ea1/panda-ea1-schematic.pdf
[msecure-mux-patch]: https://github.com/jumpnow/meta-duovero/blob/master/recipes-kernel/linux/linux-stable-3.6/0013-ARM-OMAP4-TWL-mux-sys_drm_msecure-as-output-for-PMIC.patch
[twl6030-register-manual]: http://www.cjemicros.f2s.com/public/datasheets/TWL6030_Register_Map.pdf
[duovero-battery]: http://www.digikey.com/product-detail/en/ML-621S%2FZTN/P007-ND/965124
[trickle-charge-patch]: https://github.com/jumpnow/meta-duovero/blob/master/recipes-kernel/linux/linux-stable-3.6/0014-Enable-RTC-backup-battery-charging.patch
[overo-trickle-charge-patch]: https://github.com/gumstix/meta-gumstix/blob/dora/recipes-kernel/linux/linux-gumstix-3.5/0007-rtc-twl-add-support-for-backup-battery-recharge.patch