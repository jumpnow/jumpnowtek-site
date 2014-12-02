---
layout: post
title: FreeBSD Duovero Kernel Development
description: "Rebuilding a FreeBSD kernel on the Duovero"
date: 2014-12-02 07:15:00
categories: freebsd
tags: [freebsd, gumstix, duovero, kernel]
---

Just a quick post. 

With `/usr/src` populated (*option UsrSrc* in crochet), rebuilding a kernel on the Duovero is very easy.

The first build takes awhile, maybe 20 minutes. (TODO: time this)

    root@duovero:/usr/src # make buildkernel KERNCONF=DUOVERO

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

Installing the new kernel takes about 5 seconds

    root@duovero:/usr/src # make installkernel KERNCONF=DUOVERO

And then power cycle the board (see Note).

Coming from Linux and Yocto built systems, this is all very slick.

### Note

Fixing soft reboot on the Duovero is on my list of TODOs. The problem and workaround are known.
