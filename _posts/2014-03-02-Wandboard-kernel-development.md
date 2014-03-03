---
layout: post
title: Wandboard Kernel Development
description: "Working on the Wandboard Linux kernel"
date: 2014-03-02 15:30:00
categories: wandboard
tags: [wandboard, linux, kernel development]
---

I am working on a [Wandboard Quad][wandboard-org] board using tools from the
[Yocto Project][yocto-project].

I have already [built a system][yocto-wandboard] for this board, but now I want
to make some kernel modifications. 

I don't want to use bitbake during development because that's a pretty
slow process.

But I will be using the cross-compiler and other tools that Yocto has already
built and when I'm done with development I will create a patch for use with
Yocto.

The Linux kernel that is running now is built from rules in the Freescale 
[meta-fsl-arm-extra][meta-fsl-arm-extra-dora] layer. I am using the **[dora]**
branch of both the Yocto and Freescale meta-layers.

The default kernel version is **3.0.35**. 

This can be found out by first looking at the 
[meta-fsl-arm-extra/conf/machine/wandboard-quad.conf][wandboard-quad-conf]
configuration file and noting this line

    PREFERRED_PROVIDER_virtual/kernel ?= "linux-wandboard"
 
Then looking under [meta-fsl-arm-extra/recipes-kernel/linux][recipes-linux-kernel]
where there are some recipe files

- linux-wandboard_3.0.35.bb
- linux-wandboard.inc

And this directory

- linux-wandboard-3.0.35/

Inside [linux-wandboard.inc][linux-wandboard-inc] you can find the URL for the
Linux source.
 
    ...
    SRC_URI = "git://github.com/wandboard-org/linux.git \
               file://defconfig \
    "
    ...

So the first thing is to clone this repository.

    scott@hex:~$ git clone git://github.com/wandboard-org/linux.git linux-wandboard

This will take a little while.

The recipe file [linux-wandboard_3.0.35.bb][linux-wandboard-3-0-35-bb] has the
commit that we want to use

    ...
    # Wandboard branch - based on 4.0.0 from Freescale git
    SRCREV = "d35902c77a077a25e4dfedc6aac11ba49c52c586"
    LOCALVERSION = "-4.0.0-wandboard"
    ...

I'm going to call my new branch **[work]** just to keep things simple.

    scott@hex:~/linux-wandboard$ git checkout -b work d35902c
    Switched to a new branch 'work'

A quick check that I'm on the correct commit

     scott@hex:~/linux-wandboard$ git log --oneline | head -5
     d35902c defconfig: Small updates to easy demos
     98cef90 prism.c: add BTN_TOUCH events to prism singletouch device
     ce086c4 Wandboard : Add comments reflecting EDM pin numbers of GPIOs
     672d8f3 Add support for Future Electronics FWBADAPT-7WVGA expansion board
     821af75 Wandboard : Add support for edm framwork

To get the kernel source to the same state as what is currently running, I need
to apply some additional patches that were included in the
**linux-wandboard_3.0.35.bb** recipe.

    ...
    # GPU support patches
    SRC_URI += "file://drm-vivante-Add-00-sufix-in-returned-bus-Id.patch \
    file://0001-ENGR00255688-4.6.9p11.1-gpu-GPU-Kernel-driver-integr.patch \
    file://0002-ENGR00265465-gpu-Add-global-value-for-minimum-3D-clo.patch \
    file://0003-ENGR00261814-4-gpu-use-new-PU-power-on-off-interface.patch \
    file://0004-ENGR00264288-1-GPU-Integrate-4.6.9p12-release-kernel.patch \
    file://0005-ENGR00264275-GPU-Correct-suspend-resume-calling-afte.patch \
    file://0006-ENGR00265130-gpu-Correct-section-mismatch-in-gpu-ker.patch"
    ...

Here's one way to go about it

    scott@hex:~/linux-wandboard$ git am ~/poky-dora/meta-fsl-arm-extra/recipes-kernel/linux/linux-wandboard-3.0.35/*.patch

    Applying: ENGR00255688 4.6.9p11.1 [gpu]GPU Kernel driver integration
    Applying: ENGR00265465 gpu:Add global value for minimum 3D clock export
    Applying: ENGR00261814-4 gpu: use new PU power on/off interface
    /oe25/linux-wandboard/.git/rebase-apply/patch:15: trailing whitespace.
    #if LINUX_VERSION_CODE < KERNEL_VERSION(3,5,0)
    /oe25/linux-wandboard/.git/rebase-apply/patch:17: space before tab in indent.
                    regulator_enable(Os->device->gpu_regulator);
    /oe25/linux-wandboard/.git/rebase-apply/patch:30: trailing whitespace.
    #if LINUX_VERSION_CODE < KERNEL_VERSION(3,5,0)
    /oe25/linux-wandboard/.git/rebase-apply/patch:35: space before tab in indent.
                    imx_gpc_power_up_pu(false);
    warning: 4 lines add whitespace errors.
    Applying: ENGR00264288-1 [GPU]Integrate 4.6.9p12 release kernel part code
    /oe25/linux-wandboard/.git/rebase-apply/patch:1973: space before tab in indent.
            newSemaphore = (struct semaphore *)kmalloc(gcmSIZEOF(struct semaphore), GFP_KERNEL | gcdNOWARN);
    warning: 1 line adds whitespace errors.
    Applying: ENGR00264275 [GPU]Correct suspend/resume calling after adding runtime pm.
    Applying: ENGR00265130 gpu:Correct section mismatch in gpu kernel driver
    Applying: drm/vivante: Add ":00" sufix in returned bus Id

A check of the latest commits after the patches

    scott@hex:/oe25/linux-wandboard$ git log --oneline | head -15
    60f7201 drm/vivante: Add ":00" sufix in returned bus Id
    3ee67f3 ENGR00265130 gpu:Correct section mismatch in gpu kernel driver
    32e78d7 ENGR00264275 [GPU]Correct suspend/resume calling after adding runtime pm.
    5f8fe6f ENGR00264288-1 [GPU]Integrate 4.6.9p12 release kernel part code
    8081dc7 ENGR00261814-4 gpu: use new PU power on/off interface
    9e9c852 ENGR00265465 gpu:Add global value for minimum 3D clock export
    b30614f ENGR00255688 4.6.9p11.1 [gpu]GPU Kernel driver integration
    d35902c defconfig: Small updates to easy demos
    98cef90 prism.c: add BTN_TOUCH events to prism singletouch device
    ce086c4 Wandboard : Add comments reflecting EDM pin numbers of GPIOs
    672d8f3 Add support for Future Electronics FWBADAPT-7WVGA expansion board
    821af75 Wandboard : Add support for edm framwork
    a66d9e6 Add support for Prism I2C touchscreen
    5074e84 Add basic EDM framework
    929768a wandboard: modify mipi-csi to ipu mux setting

In this case, the patches were **not** applied in the same order as the Yocto
build would have done it.
 
The **drm-vivante-Add-00...** patch got applied last instead of first because 
of the alpha-numeric ordering. This could potentially be a problem. You'll know
it if the patch command fails.

In this case it was okay.

Some alternatives to apply the list of patches in the correct order would be 

1. Apply the patches one at a time manually
2. Use quilt after first creating a **series** file with the correct ordering 

It's easy to experiment. 

You can always reset the repository to the starting commit this way

    scott@hex:~/linux-wandboard$ git reset --hard d35902c
    HEAD is now at d35902c defconfig: Small updates to easy demos


[wandboard-org]: http://www.wandboard.org/
[yocto-project]: https://www.yoctoproject.org/
[yocto-wandboard]: /wandboard/Wandboard-Systems-with-Yocto.html
[meta-fsl-arm-extra-dora]: https://github.com/Freescale/meta-fsl-arm-extra/tree/dora
[wandboard-quad-conf]: https://github.com/Freescale/meta-fsl-arm-extra/blob/dora/conf/machine/wandboard-quad.conf
[recipes-linux-kernel]: https://github.com/Freescale/meta-fsl-arm-extra/tree/dora/recipes-kernel/linux
[linux-wandboard-inc]: https://github.com/Freescale/meta-fsl-arm-extra/blob/dora/recipes-kernel/linux/linux-wandboard.inc
[linux-wandboard-3-0-35-bb]: https://github.com/Freescale/meta-fsl-arm-extra/blob/dora/recipes-kernel/linux/linux-wandboard_3.0.35.bb