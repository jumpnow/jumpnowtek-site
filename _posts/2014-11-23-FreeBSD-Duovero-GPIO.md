---
layout: post
title: FreeBSD Duovero GPIO
description: "Working with GPIO on a FreeBSD Duovero system"
date: 2014-11-23 07:00:00
categories: freebsd
tags: [freebsd, gumstix, duovero, gpio]
---

Here's a first look at working with *GPIO* pins on a [Gumstix Duovero][duovero].

I'm currently using a [Parlor][parlor] expansion board, so I'm most interested in *GPIO* accessible on the 40-pin header. 

I chose the following pins

    PIN : Current   : GPIO
    ======================
     9  : HDQ_SIO   : 127
    19  : BSP2_CLKX : 110
    20  : BSP2_FSX  : 113
    21  : BSP2_DX   : 112
    22  : BSP2_DR   : 111
    23  : BSP_CLKS  : 118

*Current* refers to the default function the pad is set to with an unmodified u-boot.

For now I am going to skip how to change the pin muxing from within *FreeBSD* and just do it in *u-boot*. This is frequently done in *Linux* systems as well.

I added a new u-boot [gpio pin muxing patch][uboot-pinmux-patch] to my *crochet* config.
Here's what it does

    PIN : GPIO : MUX
    19  : 110  : Output  
    20  : 113  : Output
    21  : 112  : Output
    22  : 111  : Output
    23  : 118  : Input, pull-down
     9  : 127  : Input, pull-up 

*FreeBSD* provides a [gpioctl(1)][gpioctl] utility for managing *GPIO* from userland. The *OMAP4* have 6 banks of 32 *GPIO* pins potentially available, though on any given board only a small subset are actually usable as *GPIO*.

The *gpioctl* utility will list all 192 pins using the `-l` command

    root@duovero:~ # gpioctl -l
    ...
    pin 109:        0       gpio_109<>
    pin 110:        0       gpio_110<OUT>
    pin 111:        0       gpio_111<OUT>
    pin 112:        0       gpio_112<OUT>
    pin 113:        0       gpio_113<OUT>
    pin 114:        0       gpio_114<>
    pin 115:        0       gpio_115<>
    pin 116:        0       gpio_116<>
    pin 117:        0       gpio_117<>
    pin 118:        0       gpio_118<IN,PD>
    pin 119:        0       gpio_119<>
    pin 120:        0       gpio_120<>
    pin 121:        0       gpio_121<>
    pin 122:        0       gpio_122<>
    pin 123:        0       gpio_123<>
    pin 124:        0       gpio_124<>
    pin 125:        0       gpio_125<>
    pin 126:        0       gpio_126<>
    pin 127:        1       gpio_127<IN,PU>
    pin 128:        0       gpio_128<>
    pin 129:        0       gpio_129<>
    ...

As can be seen from the clipped output, the *GPIO* I've configured is showing up as expected.

To read the value of a gpio pin, you can use *gpioctl* like this

    root@duovero:~ # gpioctl 110
    0

To turn **ON** a gpio pin

    root@duovero:~ # gpioctl 110 1

To turn it **OFF**

    root@duovero:~ # gpioctl 110 0

Now to test the input **gpio_118**. I'm going to use **gpio_110** to drive it.

First before connecting the two pins

    root@duovero:~ # gpioctl 110 0
    root@duovero:~ # gpioctl 110
    0
    root@duovero:~ # gpioctl 118
    0

After connecting the two pins

    root@duovero:~ # gpioctl 110 1
    root@duovero:~ # gpioctl 118
    1
    root@duovero:~ # gpioctl 110 0
    root@duovero:~ # gpioctl 118
    0

And now the same thing with the *pulled up* **gpio_127** using **gpio_112** to drive it

Before connecting the two

    root@duovero:~ # gpioctl 112
    0
    root@duovero:~ # gpioctl 127
    1

After connecting **gpio_127** and **gpio_112**

    root@duovero:~ # gpioctl 127
    0
    root@duovero:~ # gpioctl 112 1
    root@duovero:~ # gpioctl 127
    1
    root@duovero:~ # gpioctl 112 0
    root@duovero:~ # gpioctl 127
    0

Using *gpioctl* would work fine in a script.

#### C Programming

Working with *GPIO* from within a C program is more typical for me.

The *gpioctl* source code provides a good example of all the features provided by the [gpio(4)][gpiobus] driver. But because I like to test these things myself, here is an simpler piece of code that only does *GPIO* reads and writes - [fbsd-gpio][fbsd-gpio].
 


[duovero]: https://store.gumstix.com/index.php/category/43/
[parlor]: https://store.gumstix.com/index.php/products/287/
[uboot-pinmux-patch]: https://github.com/scottellis/crochet-freebsd/blob/duovero/board/Duovero/files/uboot-2014.10_0003-mux-bsp2-and-onewire-header-pins-as-gpio.patch
[gpioctl]: http://www.freebsd.org/cgi/man.cgi?query=gpioctl&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[gpiobus]: http://www.freebsd.org/cgi/man.cgi?query=gpio&apropos=0&sektion=0&manpath=FreeBSD+11-current&arch=default&format=html
[fbsd-gpio]: https://github.com/scottellis/fbsd-gpio
