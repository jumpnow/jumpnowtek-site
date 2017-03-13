---
layout: post
title: Duovero Real-time Clock
description: "Working with the Duovero battery backed RTC"
date: 2017-03-13 13:47:00
categories: gumstix-linux
tags: [linux, gumstix, duovero, rtc]
---

The Gumxstix [Duovero][duovero] COMs have a power management unit (PMIC) that supports a battery backed real-time clock.

The [Parlor][parlor] expansion boards come with a battery holder, but the default Gumstix kernels do not support trickle charging the RTC battery through the PMIC.

A small kernel patch can get it working.

Some background.

### Enabling communication with the RTC

First off, you should make sure you have **/sbin/hwclock** installed. It comes from the **busybox** package for my systems.

You can check whether or not the hwclock communication is working this way

    root@duo:~# hwclock -r
    Sun Mar 12 13:49:26 2017  0.000000 seconds

This is from a fixed system with the patches referenced below. A broken system will return zeros for the date and time.
 
The following summary comes from a variety of web postings mainly from upstream android and ti-omap kernel developers.

It's difficult to get information about the Duovero PMIC, the [TWL6030][twl6030]. The full programming reference manual is not publicly available the way it is for the TWL4030.

This [manual][swcs045c] has some information about the RTC. The **REAL-TIME CLOCK** section starting on page 32 has some information about the actual time registers. 

The important information for this problem is under the **CONTROL INTERFACE (I2C, MSECURE, INTERRUPTS)** section and in particular the **Secure Registers** subsection starting on page 85.

The **MSECURE** control signal determines whether the RTC can be set or cleared.
 
Gumstix doesn't provide a schematic of the signals between the OMAP4 and the TWL6030, but assuming they copied the [pandaboard design][pandaboard-schematic] (or that they both copied some other reference design), pin N2 **MSECURE** of the TWL6030 goes directly to pin AD2, the **FREF\_CLK0\_OUT** pad of the OMAP4. 

Mode 2 of this pad is **SYS\_DRM\_MSECURE** which is what is required.

With older kernels (3.x days) a patch to the bootloader or board-file was required.

For at least the linux-stable 4.4 kernels onward, including `arch/arm/boot/dts/twl6030_omap4.dtsi` handles the pinmux for this. Including this dtsi is the default for OMAP4 kernels.

### Enabling trickle charging the RTC battery from the PMIC

I found this [TWL6030 Register Manual][twl6030-register-manual] on a non-TI site.

From section 2.9, the **BBSPOR\_CFG** register is used to enable the RTC backup battery trickle charge. By default the **BB\_CHG\_EN** bit is off. 

I'm using [Panasonic ML-621S/ZTN][panasonic-battery] batteries in the Duoveros, so I wanted the trickle charge cutoff to be at 3.15V. These batteries accept up to 3.2V. Charging info is [here][battery-charging].

- BB\_CHG\_EN = 1
- BB\_SEL_1 = 1
- BB\_SEL_0 = 0

Given that, this [patch][trickle-charge-patch] to the **linux-stable-4.4** kernel enables trickle charging the Duovero RTC backup battery.

    diff --git a/drivers/rtc/rtc-twl.c b/drivers/rtc/rtc-twl.c
    index 2dc787d..7f522b3 100644
    --- a/drivers/rtc/rtc-twl.c
    +++ b/drivers/rtc/rtc-twl.c
    @@ -470,6 +470,41 @@ static struct rtc_class_ops twl_rtc_ops = {
     	.alarm_irq_enable = twl_rtc_alarm_irq_enable,
     };
 
    +#define REG_BBSPOR_CFG 0xE6
    +#define VRTC_EN_SLP_STS        (1 << 6)
    +#define VRTC_EN_OFF_STS        (1 << 5)
    +#define VRTC_PWEN      (1 << 4)
    +#define BB_CHG_EN      (1 << 3)
    +#define BB_SEL_1       (1 << 2)
    +#define BB_SEL_0       (1 << 1)
    +
    +static int enable_rtc_battery_charging(void)
    +{
    +	int ret;
    +	u8 data;
    +
    +	ret = twl_i2c_read_u8(TWL6030_MODULE_ID0, &data, REG_BBSPOR_CFG);
    +	if (ret < 0) {
    +		pr_err("read bbspor_cfg failed: %d\n", ret);
    +		return ret;
    +	}
    +
    +	/*
    +	 * Charge battery to 3.15v
    +	 * TWL6030 Register Map, Table 224, BBSPOR_CFG Register
    +	 */
    +	data &= ~BB_SEL_0;
    +	data |= (BB_SEL_1 | BB_CHG_EN);
    +
    +	ret = twl_i2c_write_u8(TWL6030_MODULE_ID0, data, REG_BBSPOR_CFG);
    +	if (ret < 0)
    +		pr_err("write bbspor_cfg failed: %d\n", ret);
    +	else
    +		pr_info("enabled rtc battery charging\n");
    +
    +	return ret;
    +}
    +
     /*----------------------------------------------------------------------*/
 
     static int twl_rtc_probe(struct platform_device *pdev)
    @@ -525,6 +560,10 @@ static int twl_rtc_probe(struct platform_device *pdev)
     	if (ret < 0)
     		return ret;
 
    +	ret = enable_rtc_battery_charging();
    +	if (ret < 0)
    +		dev_err(&pdev->dev, "Failed to enable rtc battery charging\n");
    +
     	device_init_wakeup(&pdev->dev, 1);
 
     	rtc = devm_rtc_device_register(&pdev->dev, pdev->name,
    -- 
    2.7.4

### Init scripts

You need some additional userland software to ensure that

1. System time gets restored from the RTC on startup
2. System time is saved to the RTC on shutdown

With Yocto built systems the **busybox-hwclock** package adds an init.d script called **hwclock.sh** to do this.


[duovero]: https://store.gumstix.com/index.php/category/43/
[parlor]: https://store.gumstix.com/index.php/products/287/
[twl6030]: http://www.ti.com/product/twl6030
[swcs045c]: http://www.farnell.com/datasheets/1481246.pdf
[pandaboard-schematic]: http://pandaboard.org/sites/default/files/board_reference/pandaboard-ea1/panda-ea1-schematic.pdf
[twl6030-register-manual]: http://www.cjemicros.f2s.com/public/datasheets/TWL6030_Register_Map.pdf
[panasonic-battery]: http://www.digikey.com/product-detail/en/ML-621S%2FZTN/P007-ND/965124
[battery-charging]: http://industrial.panasonic.com/www-data/pdf/AAA4000/AAA4000PE17.pdf
[trickle-charge-patch]: https://github.com/jumpnow/meta-duovero/blob/morty/recipes-kernel/linux/linux-stable-4.4/0004-rtc-twl-Enable-battery-charging.patch
