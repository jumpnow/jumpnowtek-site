## Overview

Some notes on getting the [Mender][mender-io] upgrade software working with [Beaglebone][beagleboard-org] systems. 

I am using Yocto and a custom meta layer to build the Beaglebone systems.

### U-Boot

**a)** I am using the default u-boot version **2017.09** that comes with Yocto 2.4 [rocko] branch.

I did need a **u-boot\_%.bbappend** for the beaglebones for the following customizations
  
    UBOOT_SUFFIX = "img"
    SPL_BINARY = "MLO"

**b)** Mender requires utilities from the **u-boot-fw-utils** package. 

The **meta-mender-core** layer overrides the default **u-boot-fw-utils** recipe with a custom one that fixes up **fw_env.config** for mender use. This primarily has to do with the size and location of the  u-boot environment.

The u-boot environment default is in the first 8 MB of unpartitioned space at the start of the device. (TODO: explain where this 8 MB number comes from).

Mender exposes some variables that allow you to specify where the u-boot environment will reside within this unpartitioned space, both a primary and a redundant value.

This is what I am using.

    MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET_1 = "0x400000"
    MENDER_UBOOT_ENV_STORAGE_DEVICE_OFFSET_2 = "0x600000"

That sets the offsets at 4MB and 6MB into the device.

**c)** The u-boot environment size needs to be declared in a Yocto environment variable. I chose machine conf but could have used local.conf for this.

    BOOTENV_SIZE = "0x20000"

**d)** The mender u-boot environment needs to know about the **KERNEL\_IMAGETYPE**. I chose machine conf again, but could have used local.conf. 

Note: I was previously specifying this variable in the kernel recipe but had to move it to machine conf so the mender recipe could see it

    KERNEL_IMAGETYPE = "zImage"


**e)** Mender also wants to know the dtb to load. To do this a mender build script parses the Yocto **KERNEL\_DEVICETREE** variable and attempts to determine the dtb from this. 

If you currently build more then one dtb by specifying multiple dtbs in **KERNEL\_DEVICETREE**, then mender will choose the last one in this list to load and pass to the kernel. Maybe this is the dtb you want. Probably it is not. I suggest only declaring one dtb in **KERNEL\_DEVICETREE** and doing separate builds for boards requiring a different dtb.. 

The **KERNEL\_DEVICETREE** definition needs to be in a place where both the kernel recipe and the mender recipe can see it. So either machine conf or local.conf will work. I chose local.conf for this.

I am testing with a BeagleBone Green.

    KERNEL_DEVICETREE = "am335x-bonegreen.dtb"

**f)** Mender needs to know both the u-boot storage device and the rootfs/data storage device. For the Beaglebone SD card, these can be specified with a single definition in local.conf.

    MENDER_STORAGE_DEVICE = "/dev/mmcblk0"

This is required and would be different for systems booting from the **eMMC**.

**g)** Mender needs some additional storage partitioning details also in local.conf 

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

**a)** Include the **meta-mender-core** layer in **bblayers.conf**. I am using the **[rocko]** branch of meta-mender

    ...
    BBLAYERS ?= " \
      ${HOME}/poky-rocko/meta \
      ${HOME}/poky-rocko/meta-poky \
      ${HOME}/poky-rocko/meta-openembedded/meta-oe \
      ${HOME}/poky-rocko/meta-openembedded/meta-networking \
      ${HOME}/poky-rocko/meta-openembedded/meta-python \
      ${HOME}/mender/meta-mender/meta-mender-core \
      ${HOME}/bbb-mender/meta-bbb \
    "

**b)** Inherit some mender classes in local.conf
  
    INHERIT += "mender-image mender-install mender-uboot"

**c)** Add mender bbappend to customize for my systems. 

This is my **mender_%.bbappend**
  
    FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

    SRC_URI_append = " \
        file://artifact-verify-key.pem \
        file://server.crt \
    "

    SYSTEMD_AUTO_ENABLE = "disable"
    MENDER_UPDATE_POLL_INTERVAL_SECONDS = "180"
    MENDER_INVENTORY_POLL_INTERVAL_SECONDS = "180"
    MENDER_RETRY_POLL_INTERVAL_SECONDS = "30"

The aggressive poll times are for development.
  
The **artifact-verify-key.pem** is the public key used to verify upgrade artifacts. There are some instructions here

    meta-bbb/docs/README-mender-keys
	 
I am running a mender server locally and **server.crt** is the self-signed cert for my server. See the instructions for [setting up a production server][mender-prod-server-doc] in the mender docs.
  
**d)** Add the url to my mender server so it gets added in the device **mender.conf**. I did this in **local.conf** though could also be done in the mender bbappend.
	 
    MENDER_SERVER_URL = "https://octo.jumpnow"


**e)** Add a mender artifact name variable in **local.conf** so the artifacts get a name. This ends up in **/etc/mender/artifact_info** on the device.
	 
    MENDER_ARTIFACT_NAME = "bbb-test-1"


**f)** I am running sysvinit not systemd, so add an init script to start the mender service on the units. See the example in 

    meta-bbb/recipes-mender/mender-sysvinit/files/init

	 
### Image creation

**a)** I couldn't get the default mender sdimg files to build. My fault no doube, but I've never had great success with Yocto's **wic** tool and I don't bother fighting it anymore. It's easy enough to do the same thing with a shell script. 

For completeness, the mender idea is that you inherit **mender-image-sd** in **local.conf** and that will generate an sdimg automatically during builds. Of course this also slows subsequent builds when you are only building upgrade **artifacts** ...
 
The sdimg is only used for initial provisioning. This is the initial system you copy to the SD card. After that all upgrades happen via 'artifacts' and do not use sdimg files.

To build installer image files I am using a custom shell script. It's a small variation of an existing image script I already use and so was pretty easy to write. 

    meta-bbb/scripts/create_mender_image.sh

A benefit to using a script like this is that it will also work (with small modifications) for **Buildroot** built systems where the **wic** tool does not exist.

b) Add **ext4** to **IMAGE_FSTYPES** in machine conf. This is the file that the **mender-artifact** utility uses to create and sign artifacts prior to uploading to the server.

    IMAGE_FSTYPES = "tar.xz ext4"

The **tar.xz** type is there for my installer script.

**c)** I have a utility script that creates artifacts and signs them

    meta-bbb/scripts/sign-mender-image.sh

The output from this script can be uploaded to the mender server.

[mender-io]: https://mender.io/	 
[mender-prod-server-doc]: https://docs.mender.io/1.3/administration/production-installation
[beagleboard-org]: http://beagleboard.org/