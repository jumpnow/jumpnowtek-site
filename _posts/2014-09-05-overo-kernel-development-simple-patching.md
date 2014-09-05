---
layout: post
title: Overo Kernel Development - Simple patching
description: "Applying a simple patch to the Overo Linux kernel"
date: 2014-09-05 04:30:00
categories: overo
tags: [overo, linux, yocto, kernel development]
---

Assuming you are using Yocto to build your [Gumstix Overo][gumstix] system, 
here's how you might go about adding a *simple* patch to your kernel.
There are alternative workflows for more involved kernel changes.

I'm using [Yocto][yocto-project] and this [meta-overo][meta-overo] repository.

Instructions for using this *meta-layer* can be found [here][using-meta-overo]

The kernel is `3.5.7`.

The patch used in the example here is taken from a question on the 
[gumstix mailing list][spi-mailing-list-thread] to change the priority of the
SPI worker thread. Used only because it's a simple one-line change to one file.

Find your *TMPDIR*, either defined in `build/conf/local.conf` or defaulting
to `build/tmp`.

Change to the directory of the kernel source

    $ cd <TMPDIR>/work/overo-poky-linux-gnueabi/linux-stable/3.5.7-r0/git

Edit the file(s) you want to change, in this example 

    $ <edit> drivers/spi/spi-omap2-mcspi.c

The kernel source directory is a *git* repository, so commit the change

    $ git add drivers/spi/spi-omap2-mcspi.c
    $ git commit -m 'add RT priority to spi worker thread'

Generate a patch file

    $ git format-patch -1
    0001-add-RT-priority-to-spi-worker-thread.patch

A quick look at the patch

    $ cat 0001-add-RT-priority-to-spi-worker-thread.patch
    From 874e08240b210e4a6e92605c75533af03b94281d Mon Sep 17 00:00:00 2001
    From: Scott Ellis <scott@jumpnowtek.com>
    Date: Fri, 5 Sep 2014 04:08:21 -0400
    Subject: [PATCH] add RT priority to spi worker thread
    
    ---
     drivers/spi/spi-omap2-mcspi.c | 2 ++
     1 file changed, 2 insertions(+)
    
    diff --git a/drivers/spi/spi-omap2-mcspi.c b/drivers/spi/spi-omap2-mcspi.c
    index d9848fe..2e4ef9b 100644
    --- a/drivers/spi/spi-omap2-mcspi.c
    +++ b/drivers/spi/spi-omap2-mcspi.c
    @@ -1198,6 +1198,8 @@ static int __devinit omap2_mcspi_probe(struct platform_device *pdev)
            if (status || omap2_mcspi_master_setup(mcspi) < 0)
                    goto disable_pm;
    
    +       master->rt = 1;
    +
            status = spi_register_master(master);
            if (status < 0)
                    goto err_spi_register;
    --
    1.9.1
  
Copy the patch file to the *meta-layer* where the kernel *recipe* can find it

    $ cp 0001-add-RT-priority-to-spi-worker-thread.patch \
        ~/overo/meta-overo/recipes-kernel/linux/linux-stable-3.5

Since there are already a number of kernel patches in that directory, rename 
the new patch file to keep things tidy.

    $ cd ~/overo/meta-overo/recipes-kernel/linux/linux-stable-3.5

    $ mv 0001-add-RT-priority-to-spi-worker-thread.patch \
         0036-add-RT-priority-to-spi-worker-thread

Add the patch to the kernel recipe

    $ cd ~/overo/meta-overo/recipes-kernel/linux
    $ <edit> linux-stable_3.5.7.bb

    $ git diff linux-stable_3.5.7.bb
    diff --git a/recipes-kernel/linux/linux-stable_3.5.7.bb b/recipes-kernel/linux/linux-stable_3.5.7.bb
    index d8ae61a..e5bafb6 100644
    --- a/recipes-kernel/linux/linux-stable_3.5.7.bb
    +++ b/recipes-kernel/linux/linux-stable_3.5.7.bb
    @@ -49,6 +49,7 @@ SRC_URI = " \
         file://0033-ARM-7668-1-fix-memset-related-crashes-caused-by-rece.patch \
         file://0034-ARM-7670-1-fix-the-memset-fix.patch \
         file://0035-OMAP2-3-clock-fix-sprz319-erratum-2.1.patch \
    +    file://0036-add-RT-priority-to-spi-worker-thread.patch \
         file://defconfig \
     "

Rebuild the kernel

    $ source ~/poky-daisy/oe-init-build-env ~/overo/build

    $ bitbake -c cleansstate virtual/kernel
    $ bitbake virtual/kernel

Rebuild the image

    $ bitbake -c cleansstate console-image
    
    (optional)
    $ rm <TMPDIR>/deploy/images/overo/console-image*
        
    $ bitbake console-image


If the change worked, as a final step you probably want to go back and commit
the new patch and the kernel recipe change in the *meta-layer* repository.

    $ cd ~/overo/meta-overo

Create a new branch (optional)

    $ git checkout -b spi-patch-example

Commit the changes

    $ git status
    On branch spi-patch-example
    Changes not staged for commit:
      (use "git add <file>..." to update what will be committed)
      (use "git checkout -- <file>..." to discard changes in working directory)
    
            modified:   recipes-kernel/linux/linux-stable_3.5.7.bb
    
    Untracked files:
      (use "git add <file>..." to include in what will be committed)
    
            recipes-kernel/linux/linux-stable-3.5/0036-add-RT-priority-to-spi-worker-thread.patch
    
    no changes added to commit (use "git add" and/or "git commit -a")

    $ git add recipes-kernel/linux/linux-stable-3.5/0036-add-RT-priority-to-spi-worker-thread.patch
    $ git add recipes-kernel/linux/linux-stable_3.5.7.bb
    $ git commit -m 'kernel: Add spi rt worker thread patch'


[gumstix]: http://www.gumstix.com/
[yocto-project]: https://www.yoctoproject.org/
[meta-overo]: https://github.com/jumpnow/meta-overo
[using-meta-overo]: http://www.jumpnowtek.com/gumstix/overo/Overo-Systems-with-Yocto.html
[spi-mailing-list-thread]: http://gumstix.8.x6.nabble.com/SPI-and-multi-threading-issue-td4969428.html