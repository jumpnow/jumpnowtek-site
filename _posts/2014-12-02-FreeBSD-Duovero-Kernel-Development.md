---
layout: post
title: FreeBSD Duovero Kernel Development
description: "Rebuilding a FreeBSD kernel on the Duovero"
date: 2014-12-02 07:15:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero, kernel]
---

Just a quick post. 

With `/usr/src` populated (*option UsrSrc* in crochet), rebuilding a kernel on the Duovero is very easy.

The first build takes awhile, approximately **36** minutes for me (Note 1).

    root@duovero:/usr/src # make buildkernel KERNCONF=DUOVERO

If you add a `-j2`, then the initial build time drops to about **23** minutes.

    root@duovero:/usr/src # make -j2 buildkernel KERNCONF=DUOVERO

But afterwards, incremental compiles take around 1.5 minutes.

    root@duovero:/usr/src # make buildkernel -DKERNFAST KERNCONF=DUOVERO
    
    --------------------------------------------------------------
    >>> Kernel build for DUOVERO started on Tue Dec  2 07:09:45 EST 2014
    --------------------------------------------------------------
    ===> DUOVERO
    ...
    --------------------------------------------------------------
    >>> Kernel build for DUOVERO completed on Tue Dec  2 07:11:08 EST 2014
    --------------------------------------------------------------

Since compiling small changes is the typical workflow during kernel/driver development, this is very convenient.

Installing the new kernel takes about **5** seconds

    root@duovero:/usr/src # make installkernel KERNCONF=DUOVERO

And then power cycle the board (Note 2).

Coming from Linux and Yocto built systems, this is all very slick.

### Note 1

I'm using SanDisk Extreme 16GB UHS-I/U3 Micro SDHC Memory Cards. They cost around $16 from Amazon. They are worth it.


### Note 2
 
Here are a couple of patches that change the behavior of reboot to be a warm reboot instead of a cold reboot on the OMAP4.

[0005-omap4-prcm-use-defined-constants-in-reset-function.patch][prcm-use-constants-patch]

[0006-omap4-do-warm-reset-on-reboot.patch][reset-patch]


The patches won't apply cleanly unless some of the earlier *prcm* patches in that series are applied first. The `reboot` patch is trivial though and can be manually done.

With these patches the duovero will now `reboot` when given the command. Unfortunately, occasionally the host USB does not come up on reboot. Additional investigation required, but without USB, no wifi and no networking. So you end up needing to do a second cold reboot when this happens. Most of the time `reboot` now works, but this random failure is annoying. 

Really need to write an ethernet driver...

[prcm-use-constants-patch]: https://github.com/scottellis/duovero-freebsd/blob/master/patches/0005-omap4-prcm-use-defined-constants-in-reset-function.patch
[reset-patch]: https://github.com/scottellis/duovero-freebsd/blob/master/patches/0006-omap4-do-warm-reset-on-reboot.patch

