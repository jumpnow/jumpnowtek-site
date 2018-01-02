## Overview

Some notes on getting the [Mender][mender-io] software upgrade system working with Wandboard images. I am using a custom Yocto meta layer for my Wandbord builds and needed a few changes to get things working.

### U-Boot

a) I am using the default u-boot version **2017.09** that comes with Yocto 2.4 [rocko]. I did need a **u-boot\_%.bbappend** for the BBB for the following customizations

    FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

    SRC_URI += "file://0001-Add-bootargs-setting.patch \
                file://0002-Add-environment-debug.patch \
               "

    UBOOT_SUFFIX = "img"
    SPL_BINARY = "SPL"

The **0001-Add-bootargs-setting.patch** is required to define a **bootargs** variable in the u-boot environment.

The **0002-Add-environment-debug.patch** was only for debugging, but it doesn't hurt anything. I would remove it for any production project.


b) Mender requires inclusion of the **u-boot-fw-utils** package in the image. 

The **meta-mender-core** layer overrides the default **u-boot-fw-utils** recipe with a custom one that fixes up **fw_env.config** for mender use. This primarily has to do with how big and where the u-boot environment will reside.

The u-boot environment storage is in the first 8 MB of unpartitioned space at the start of the device. (TODO: explain where this 8 MB number comes from).

Mender exposes some variables that allow you to specify where the u-boot environment will reside within this unpartitioned space, both a primary and a redundant value.

This is what I am using.

    MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET_1 = "0x400000"
    MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET_2 = "0x600000"

That sets the offsets at 4MB and 6MB into the device which avoids the location where the u-boot binaries are placed.


c) The u-boot environment size needs to be declared in a Yocto environment variable. I chose machine conf but could have used local.conf for this as well.

    BOOTENV_SIZE = "0x20000"


d) The mender u-boot environment needs to know about the **KERNEL\_IMAGETYPE**. I chose machine conf again, but could have used local.conf. 

Note: I was previously specifying this variable in the kernel recipe but moved it to machine conf since the mender recipe also needs to know this

    KERNEL_IMAGETYPE = "zImage"


e) Mender also wants to know the dtb to load. To do this a mender build script parses the Yocto **KERNEL\_DEVICETREE** variable and attempts to determine the dtb from this. 

If you currently build more then one dtb by specifying multiple dtbs in **KERNEL\_DEVICETREE**, then mender will choose the last one in this list to load and pass to the kernel. Maybe this is the dtb you want. Probably it is not. I suggest only declaring one dtb in **KERNEL\_DEVICETREE** and doing separate builds for boards requiring a different dtb.

The **KERNEL\_DEVICETREE** definition needs to be in a place where both the kernel recipe and the mender recipe can see it. So either machine conf or local.conf will work. I chose local.conf for this.

    KERNEL_DEVICETREE = "imx6q-wandboard-revb1.dtb"

f) Mender needs to know both the u-boot storage device and the rootfs storage device. Usually these are the same device, but even if they are, u-boot and the Linux kernel may have different names for them.

The Wandboard SD card on the SOM is such a device.

For u-boot the device is **mmc0**. For linux it is **mmc2** (/dev/mmcblk2).

Mender is equipped to accommodate this.

For linux, use this declaration in local.conf

    MENDER_STORAGE_DEVICE = "/dev/mmcblk2"

And for u-boot, use the following lines also in local.conf

    MENDER_UBOOT_STORAGE_INTERFACE = "mmc"
    MENDER_UBOOT_STORAGE_DEVICE = "0"


g) Mender needs some additional storage partitioning details in local.conf. The assumption here is a  device at least 4GB in size.

    IMAGE_ROOTFS_SIZE = "1048576"
    MENDER_STORAGE_TOTAL_SIZE_MB = "3616"
    MENDER_PARTITION_ALIGNMENT_KB = "4096"
    MENDER_BOOT_PART_SIZE_MB = "8"
    MENDER_DATA_PART_SIZE_MB = "1536"

The calculation for **MENDER\_STORAGE\_TOTAL\_SIZE\_MB** is

    STORAGE_TOTAL_SIZE_MB = (2 * IMAGE_ROOTFS_SIZE) / 1024) 
                            + BOOT_PART_SIZE_MB
                            + DATA_PART_SIZE_MB
                            + uboot_env_storage_size
                            + (4 * num_partitions * 1MB)

So for instance if I wanted to shrink the data partition to 128 MB I would use the following   

    IMAGE_ROOTFS_SIZE = "1048576"
    MENDER_STORAGE_TOTAL_SIZE_MB = "2208"
    MENDER_PARTITION_ALIGNMENT_KB = "4096"
    MENDER_BOOT_PART_SIZE_MB = "8"
    MENDER_DATA_PART_SIZE_MB = "128"

It is only the **IMAGE\_ROOTFS\_SIZE** that matters for upgrades.

### Mender software

a) Include the **meta-mender-core** layer in **bblayers.conf**. I am using the **[rocko]** branch of meta-mender

    ...
    BBLAYERS ?= " \
      ${HOME}/poky-rocko/meta \
      ${HOME}/poky-rocko/meta-poky \
      ${HOME}/poky-rocko/meta-openembedded/meta-oe \
      ${HOME}/poky-rocko/meta-openembedded/meta-networking \
      ${HOME}/poky-rocko/meta-openembedded/meta-python \
      ${HOME}/mender/meta-mender/meta-mender-core \
      ${HOME}/wand-mender/meta-wandboard \
    "

b) Inherit some mender classes in local.conf
  
    INHERIT += "mender-image mender-install mender-uboot"

c) Add mender bbappend to customize for my systems. This is my **mender_%.bbappend**
  
    FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

    SRC_URI_append = " \
        file://artifact-verify-key.pem \
        file://server.crt \
    "

    SYSTEMD_AUTO_ENABLE = "disable"
    MENDER_UPDATE_POLL_INTERVAL_SECONDS = "180"
    MENDER_INVENTORY_POLL_INTERVAL_SECONDS = "180"
    MENDER_RETRY_POLL_INTERVAL_SECONDS = "30"

The aggressive poll times are for development. You would want to make them longer in production.
  
d) The **artifact-verify-key.pem** is the public key used to verify upgrade artifacts. See the instructions in `meta-wandboard/docs/README-mender-keys` for generating and using mender signing keys.
	 
e) I am running a mender server locally and **server.crt** is the self-signed cert for my server. See the instructions for [setting up a production server][mender-prod-server-doc] in the mender docs.
  
f) Add the url to my mender server so it gets added in the device **mender.conf**. I did this in **local.conf** though could also be done in the mender bbappend.
	 
    MENDER_SERVER_URL = "https://octo.jumpnow"


g) Add a mender artifact name variable in **local.conf** so artifacts get a name. This ends up in **/etc/mender/artifact_info** on the device.
	 
    MENDER_ARTIFACT_NAME = "wandq-test-1"


f) I am running sysvinit not systemd, so add an init script to start the mender service on the units. See the example in **meta-bbb/recipes-mender/mender-sysvinit**.

	 
### Image creation

a) After failing to get the mender sdimg files to build for the BBB, I didn't even bother to try with the wandboards. Instead I just reused the script I am using for the BBBs. 

Note that you only need this sdimg file for initial provisioning. After that upgrades happen via **artifacts** and do not use an sdimg file.

The script I am using is here

    meta-wandboard/scripts/create_mender_image.sh

A benefit to using a script like this is that it will also work (with small modifications) for **Buildroot** built systems where the **wic** tool does not exist.

The script creates 4 partitions which is not necessary with the wandboards where the bootloader binaries **SPL** and **u-image.img** are on the unpartitioned space of the SD.

I was in a hurry to see things working on the wandboard and did not investigate how to tell mender that no u-boot partition is necessary. So currently the **p1** FAT partition on the SD card is never used.

TODO: See about removing the u-boot partition.


b) Add **ext4** to **IMAGE_FSTYPES** in machine conf. This is the file that the **mender-artifact** utility uses to create and sign artifacts prior to uploading to the server.

    IMAGE_FSTYPES = "tar.xz ext4"

The **tar.xz** type is there for my installer script.

c) See the script **meta-bbb/scripts/sign-mender-image.sh** for a utility that creates and signs artifacts generated by meta-bbb images.
	 
	 
[mender-io]: https://mender.io/	 
[mender-prod-server-doc]: https://docs.mender.io/1.3/administration/production-installation	