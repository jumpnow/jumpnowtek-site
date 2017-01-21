---
layout: post
title: Compiling Raspberry Pi Overlays with Buildroot
date: 2017-01-21 11:31:00
categories: rpi
tags: [linux, rpi, buildroot, rpi3, overlays, kernel]
---

The Buildroot kernel makefile doesn't build the RPi DTBO overlays from source.

Instead the DTBO overlays are installed as part of the **rpi-firmware** package as copies from the [github.com/raspberrypi/firmware][rpi-firmware-repo] repository.

This is inconvenient when working on overlays and you want to incorporate the changes into Buildroot using patches the way you typically would.

Fortunately Buildroot makes it pretty easy to add support for changing this behavior and building the in-tree overlays.

Here's what I did.

The kernel **Config.in**

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

and the kernel makefile **linux.mk**

    diff --git a/linux/linux.mk b/linux/linux.mk
    index 7f4432e..8195a96 100644
    --- a/linux/linux.mk
    +++ b/linux/linux.mk
    @@ -309,6 +309,13 @@ define LINUX_INSTALL_DTB
     endef
     endif # BR2_LINUX_KERNEL_APPENDED_DTB
     endif # BR2_LINUX_KERNEL_DTB_IS_SELF_BUILT
    +
    +ifeq ($(BR2_LINUX_KERNEL_DTS_OVERLAYS_SUPPORT),y)
    +define LINUX_INSTALL_DTB_OVERLAYS
    +       cp $(KERNEL_ARCH_PATH)/boot/dts/overlays/*.dtbo $(1)
    +endef
    +endif # BR2_LINUX_KERNEL_DTS_OVERLAYS
    +
     endif # BR2_LINUX_KERNEL_DTS_SUPPORT

     ifeq ($(BR2_LINUX_KERNEL_APPENDED_DTB),y)
    @@ -350,6 +357,10 @@ define LINUX_BUILD_CMDS
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
    @@ -390,6 +401,8 @@ endef
     define LINUX_INSTALL_IMAGES_CMDS
            $(call LINUX_INSTALL_IMAGE,$(BINARIES_DIR))
            $(call LINUX_INSTALL_DTB,$(BINARIES_DIR))
    +       mkdir -p $(BINARIES_DIR)/overlays
    +       $(call LINUX_INSTALL_DTB_OVERLAYS,$(BINARIES_DIR)/overlays)
     endef
    
     ifeq ($(BR2_STRIP_strip),y)


And I modified the rpi-firmware **Config.in** so that it doesn't copy overlays when the kernel built ones are being used.

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


With those changes and **BR2\_LINUX\_KERNEL\_DTS\_OVERLAYS\_SUPPORT** enabled in the main config, an overlays directory with the dtbos will get created in `images/overlays`.

The final piece is to get this `overlay/` directory installed onto the SD card image boot directory. 

A minor modification to the `board/raspberrypi/genimage-raspberrypiX.cfg` handles this
 
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


With these changes I can now add or modify overlay dts files in the RPi kernel source, generate a kernel patch and Buildroot will build and install the changes into the image.

[rpi-firmware-repo]: https://github.com/raspberrypi/firmware
