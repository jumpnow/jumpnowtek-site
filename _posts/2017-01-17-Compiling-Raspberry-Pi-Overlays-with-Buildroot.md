---
layout: post
title: Compiling Raspberry Pi Overlays with Buildroot
date: 2017-01-23 16:31:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, overlays, kernel]
---

The Buildroot kernel makefile doesn't build the RPi dtbo overlays from source.

Instead the dtbo overlays are installed as part of the **rpi-firmware** package as copies from the [github.com/raspberrypi/firmware][rpi-firmware-repo] repository.

This is inconvenient when working on overlays and you want to incorporate the changes into Buildroot using patches the way you typically make kernel modifications.

Fortunately it wasn't too hard to add support in Buildroot and build the in-tree RPi overlays directly.

Here is how I am currently doing it.

I added a new config option for the kernel

    diff --git a/linux/Config.in b/linux/Config.in
    index 4a3c29a..6b20ebe 100644
    --- a/linux/Config.in
    +++ b/linux/Config.in
    @@ -383,6 +383,13 @@ config BR2_LINUX_KERNEL_CUSTOM_DTS_PATH

     endif

    +config BR2_LINUX_KERNEL_DTS_OVERLAYS_SUPPORT
    +       bool "Build Device Tree Overlays"
    +       depends on BR2_LINUX_KERNEL_DTS_SUPPORT
    +       help
    +         Build in-tree device tree overlays.
    +         Currently supports Raspberry Pi kernels.
    +
     config BR2_LINUX_KERNEL_INSTALL_TARGET
            bool "Install kernel image to /boot in target"
            depends on !BR2_TARGET_ROOTFS_INITRAMFS

and modified the kernel makefile to build the dtbos and copy them to an `overlays/` directory in the **$(BINARIES_DIR)**.

    diff --git a/linux/linux.mk b/linux/linux.mk
    index 7f4432e..003ca34 100644
    --- a/linux/linux.mk
    +++ b/linux/linux.mk
    @@ -309,6 +309,14 @@ define LINUX_INSTALL_DTB
     endef
     endif # BR2_LINUX_KERNEL_APPENDED_DTB
     endif # BR2_LINUX_KERNEL_DTB_IS_SELF_BUILT
    +
    +ifeq ($(BR2_LINUX_KERNEL_DTS_OVERLAYS_SUPPORT),y)
    +define LINUX_INSTALL_DTB_OVERLAYS
    +       mkdir -p $(1)
    +       cp $(KERNEL_ARCH_PATH)/boot/dts/overlays/*.dtbo $(1)
    +endef
    +endif # BR2_LINUX_KERNEL_DTS_OVERLAYS
    +
     endif # BR2_LINUX_KERNEL_DTS_SUPPORT
    
     ifeq ($(BR2_LINUX_KERNEL_APPENDED_DTB),y)
    @@ -350,6 +358,10 @@ define LINUX_BUILD_CMDS
            @if grep -q "CONFIG_MODULES=y" $(@D)/.config; then      \
                    $(LINUX_MAKE_ENV) $(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) modules ;        \
            fi
    +       $(if $(BR2_LINUX_KERNEL_DTS_OVERLAYS_SUPPORT),
    +               $(LINUX_MAKE_ENV) $(MAKE) $(LINUX_MAKE_FLAGS) -C $(@D) dtbs ;           \
    +       )
    +
            $(LINUX_BUILD_DTB)
            $(LINUX_APPEND_DTB)
     endef
    @@ -390,6 +402,7 @@ endef
     define LINUX_INSTALL_IMAGES_CMDS
            $(call LINUX_INSTALL_IMAGE,$(BINARIES_DIR))
            $(call LINUX_INSTALL_DTB,$(BINARIES_DIR))
    +       $(call LINUX_INSTALL_DTB_OVERLAYS,$(BINARIES_DIR)/overlays)
     endef
    
     ifeq ($(BR2_STRIP_strip),y)

And I modified the *rpi-firmware* config so that it doesn't copy dtbos when the kernel built ones are being used.

    diff --git a/package/rpi-firmware/Config.in b/package/rpi-firmware/Config.in
    index c2983aa..49f25da 100644
    --- a/package/rpi-firmware/Config.in
    +++ b/package/rpi-firmware/Config.in
    @@ -58,8 +58,9 @@ config BR2_PACKAGE_RPI_FIRMWARE_INSTALL_DTBS
    
     config BR2_PACKAGE_RPI_FIRMWARE_INSTALL_DTB_OVERLAYS
            bool "Install DTB overlays"
    -       depends on BR2_PACKAGE_RPI_FIRMWARE_INSTALL_DTBS \
    -               || BR2_LINUX_KERNEL_DTS_SUPPORT
    +       depends on (BR2_PACKAGE_RPI_FIRMWARE_INSTALL_DTBS \
    +               || BR2_LINUX_KERNEL_DTS_SUPPORT) && \
    +               !BR2_LINUX_KERNEL_DTS_OVERLAYS_SUPPORT
            default y
            help
              Say 'y' here if you need to load one or more of the DTB overlays,


With those changes the dtbos will end up in `images/overlays`.

The final piece is to get the `overlays/` directory installed onto the SD card FAT partition where the bootloader looks for them. 

This can be handled with a minor change to the `board/raspberrypi/genimage-raspberrypiX.cfg` template that describes how to create the SD card image.
 
    diff --git a/board/raspberrypi/genimage-raspberrypi3.cfg b/board/raspberrypi/genimage-raspberrypi3.cfg
    index baab0c4..9ceab77 100644
    --- a/board/raspberrypi/genimage-raspberrypi3.cfg
    +++ b/board/raspberrypi/genimage-raspberrypi3.cfg
    @@ -7,7 +7,7 @@ image boot.vfat {
           "rpi-firmware/config.txt",
           "rpi-firmware/fixup.dat",
           "rpi-firmware/start.elf",
    -      "rpi-firmware/overlays",
    +      "overlays",
           "kernel-marked/zImage"
         }
       }

With these changes it's now possible to add or modify overlay dts files in the RPi kernel source, generate a kernel patch and Buildroot will build and install the changes into the image.

[rpi-firmware-repo]: https://github.com/raspberrypi/firmware
