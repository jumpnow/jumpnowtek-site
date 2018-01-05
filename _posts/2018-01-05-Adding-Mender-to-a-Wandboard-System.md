---
layout: post
title: Adding Mender to a Wandboard System
description: "Incorporating Mender into a Yocto built Wandboard system"
date: 2018-01-05 14:30:00
categories: wandboard 
tags: [mender, wandboard, yocto, linux]
---

[Mender][mender-io] is an open source system for upgrading embedded Linux devices.

For now integrating Mender is easiest if you are using [Yocto][yocto] to build your systems.

I have a simple [meta-layer][meta-wandboard] for [Wandboards][wandboard] that can be adapted without too much effort to add Mender support.

The steps to setup and build are similar to the ones outlined in this post [Building Wandboard Systems with Yocto][wandboard-yocto] with the following differences   

1. The meta-mender repository needs to be cloned and added to **bblayers.conf**
2. Add some mender classes and storage configuration to your **local.conf**
3. Configure the systems for the mender server you plan to use
4. Generate artifact signing keys and copy to the proper location
5. Build the **mender-test-image** instead of the **console-image**
6. Create an SD image file

Detailed explanations of each step follow.

### Add the meta-mender layer

I am assuming the directory structure from the [Building Wandboard Systems][wandboard-yocto] post.

Namely this

    ~/poky-rocko/
         meta-openembedded/
         ...

    ~/wandboard/
        meta-wandboard/
        build/
            conf/

Adjust accordingly if that is not what you are using.

Clone the meta-mender layer, the **[rocko]** branch

    ~$ cd ~/poky-rocko
    ~/poky-rocko$ git clone -b rocko git://github.com/mendersoftware/meta-mender

Then use the example **bblayers.conf-mender-sample** in **meta-wandboard/conf** for your **bblayers.conf**

    ~$ cd wandboard
    ~/wandboard$ mkdir -p build/conf
    ~/wandboard$ cp meta-wandboard/conf/bblayers.conf-mender-sample \
        build/conf/bblayers.conf

Again adjust accordingly if you are using different paths.

### Add Mender configuration to local.conf

There is an example in **meta-wandboard/conf/local.conf-mender-sample**.

Copy it as your **local.conf**

    ~/wandboard$ cp meta-wandboard/conf/local.conf-mender-sample \
        build/conf/local.conf

You can choose to edit **DL\_DIR**, **SSTATE\_DIR** and **TMPDIR** as described in the [Building Wandboard Systems][wandboard-yocto] post or leave them alone and commented.

A **KERNEL\_DEVICETREE** needs to be set in this file (or in **machine.conf**) so both the mender classes and the kernel recipe can see it. 

Only declare one dtb here since the mender patched u-boot is going to embed in the u-boot environment this dtb as the one to feed the kernel. Mender (by default) will override any auto-detection in u-boot about which dtb to load. 

This behavior can be changed with some modifications to mender's u-boot changes, but to get started just choose the correct dtb for the board you are using.

With the exception of **MENDER\_ARTIFACT\_NAME** (set to anything you want) and **MENDER\_SERVER\_URL** (covered in the next section), you should leave the other variables alone for your first build and experiment later.

The systems generated from these definitions assume an SD card that is at least 4 GB and will generate the following layout

    Device         Boot   Start     End Sectors  Size Id Type
    /dev/mmcblk2p1 *      16384   32767   16384    8M  c W95 FAT32 (LBA)
    /dev/mmcblk2p2        32768 2129919 2097152    1G 83 Linux
    /dev/mmcblk2p3      2129920 4227071 2097152    1G 83 Linux
    /dev/mmcblk2p4      4227072 7372799 3145728  1.5G 83 Linux

The systems are set to boot from the SD card on the SOM board not the carrier board.

You can lookup all these definitions in the mender documentation.

### Choose your mender server

You need to tell clients where the mender server is.

If you follow the [Production installation][mender-server-production-install] steps and run your own mender server, you will set the **MENDER\_SERVER\_URL** variable to that server like the example I used here

    MENDER_SERVER_URL = "https://octo.jumpnow"

When setting up server you will have generated some [server keys][server-keys]. The **server.crt** file you generated needs to be copied to

    meta-wandboard/recipes-mender/mender/files/server.crt

before you build the mender recipe.

If instead you choose to use Mender's [hosting service][hosted-mender-io-signup] then you would set the following

    MENDER_SERVER_URL = "https://hosted.mender.io"

and then add another variable with your mender tenant token

    MENDER_TENANT_TOKEN = "<big long token>" 

When using mender's hosting service or if your mender server has an officially signed CA cert, then you should remove the **server.crt** line from **SRC_URI** in my mender recipe bbappend.

    meta-wandboard/recipes-mender/mender/mender_%.bbappend

### Generate artifact signing keys

Signing artifacts is an optional but recommended feature of mender.

You can read about the Mender [Signing and verification][signing-and-verification] framework here.

There is a short README in the **meta-wandboard** repository for setting up the signing keys to work with the **meta-wandboard** build systems and utility scripts.

    meta-wandboard/docs/README-mender-keys

If you follow those instructions you can immediately use a provided utility script to generate and sign mender artifacts for uploading to a mender server

    meta-wandboard/scripts/sign-mender-image.sh
 
### Build the mender-test-image

There is a simple Yocto image recipe you can use for testing

    meta-wandboard/recipes-mender/images/mender-test-image.bb

Build it with bitbake after sourcing the Yocto environment

    ~/wandboard/build$ bitbake mender-test-image 

Note that only the two packages in **MENDER\_EXTRA** are required beyond the additions to **local.conf** to enable mender in the client.

### Create an SD image file

The systems built with configuration described above are intended to be run from an SD card.

For the initial installation to the SD card, care needs to be taken to configure the two rootfs partitions and the data partition for persistent data.

There is a script I am using for this

    meta-wandboard/scripts/create_mender_image.sh

The script does not require any arguments but you may have to modify the **TOPDIR** variable at the top of the script if you are using different paths then described above.

The result of this script can be copied to an SD card using **dd**

    ~/wandboard/upload$ sudo dd if=wandboard-mender-test-4gb.img of=/dev/sdb bs=1M  



[mender-io]: https://mender.io/what-is-mender
[yocto]: https://www.yoctoproject.org/
[meta-wandboard]: https://github.com/jumpnow/meta-wandboard
[wandboard]: http://www.wandboard.org/
[wandboard-yocto]: http://www.jumpnowtek.com/wandboard/Wandboard-Systems-with-Yocto.html
[hosted-mender-io-signup]: https://mender.io/signup
[mender-server-production-install]: https://docs.mender.io/1.3/administration/production-installation
[server-keys]: https://docs.mender.io/1.3/administration/production-installation#certificates-and-keys
[signing-and-verification]: https://docs.mender.io/1.3/artifacts/signing-and-verification