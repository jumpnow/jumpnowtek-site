---
layout: post
title: Building 64-bit Systems for Raspberry Pi 4 with Yocto
description: "Building customized 64-bit systems for the Raspberry Pi 4 using tools from the Yocto Project"
date: 2020-05-17 08:10:00
categories: rpi
tags: [linux, rpi, yocto, rpi4, 64-bit]
---

This post is about building 64-bit Linux systems for [Raspberry Pi][rpi] 4 boards using software from the [Yocto Project][Yocto].

Yocto is a set of tools for building a custom embedded Linux distribution. The systems are usually targeted for a particular application such as a commercial product.

Yocto uses what it calls **meta-layers** to define the configuration. Within each meta-layer are recipes, classes and configuration files that support the primary build tool, a python app called **bitbake**.

I have a custom meta-layer for the RPi4 boards called [meta-rpi64][meta-rpi64].

There are a some example images in [meta-rpi64][meta-rpi64] that I have been experimenting with.

These systems use **sysvinit**, but Yocto supports **systemd**.

The systems support both QWidget and QML [Qt][qt] applications using the [linuxfb][qt-embedded] backend, useful for dedicated full-screen applications that do not require a window manager.

### Downloads

If you want a quick look at the resulting systems, you can download some pre-built images [here][downloads].

Instructions for installing onto an SD card are in the [README][readme].

The login user is **root** with password **jumpnowtek**.

You will be prompted to change the password on first login.

A dhcp client will run on the ethernet interface and an ssh server is running.

**Note:** There is a firewall rule that will lock out your IP for 2 minutes after 5 failed logins.

### System Info

The Yocto version is **3.1**, the `[dunfell]` branch.

The default is a **5.4** Linux kernel from the [github.com/raspberrypi/linux][rpi-kernel] repository.

There is also a **4.19** kernel available though I am not testing this anymore.

These are **sysvinit** systems using [eudev][eudev].

The Qt version is **5.13.2** There is no **X11** and no desktop installed. [Qt][qt] GUI applications can be run fullscreen using one of the [Qt embedded linux plugins][qt-embedded] like **linuxfb** or **eglfs**, both are provided. The default is **linuxfb**.

**Note:** eglfs is not working with the **5.4** kernel, but QML apps are working now with **linuxfb** which is different from earlier versions.

Python **3.8.2** with a number of modules is included.

gcc/g++ **9.3.0** and associated build tools are installed.

git **2.24.1** is installed.

wireguard from [wireguard-linux-compat][wireguard-linux-compat] is installed.

### Ubuntu Setup

I am using **18.04** and **20.04** 64-bit servers for builds.

You will need at least the following packages installed

    build-essential
    chrpath
    diffstat
    gawk
    libncurses5-dev
    python3-distutils
    texinfo

You should change the default Ubuntu shell from **dash** to **bash** by running this command from a shell

    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Clone the dependency repositories

For all upstream repositories, use the `[dunfell]` branch.

The directory layout I am describing here is my preference. All of the paths to the meta-layers are configurable. If you choose something different, adjust the following instructions accordingly.

First the main Yocto project **poky** layer

    ~$ git clone -b dunfell git://git.yoctoproject.org/poky.git poky-dunfell

Then the dependency layers under that

    ~$ cd poky-dunfell
    ~/poky-dunfell$ git clone -b dunfell git://git.openembedded.org/meta-openembedded
    ~/poky-dunfell$ git clone -b dunfell https://github.com/meta-qt5/meta-qt5
    ~/poky-dunfell$ git clone -b dunfell git://git.yoctoproject.org/meta-raspberrypi
    ~/poky-dunfell$ git clone -b dunfell git://git.yoctoproject.org/meta-security.git

And my own common meta-layer that changes some upstream package defaults and adds a few custom recipes.

    ~/poky-dunfell$ git clone -b dunfell https://github.com/jumpnow/meta-jumpnow

<br/>

### Clone the meta-rpi repository

Create a separate sub-directory for the **meta-rpi64** repository before cloning. This is where you will be doing most of your customization.

    ~$ mkdir ~/rpi64
    ~$ cd ~/rpi64
    ~/rpi64$ git clone -b dunfell git://github.com/jumpnow/meta-rpi64

The `meta-rpi64/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Again much of the following are only my conventions.

Choose a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/rpi64/` with the `meta-rpi64` layer.

You could manually create the directory structure like this

    $ mkdir -p ~/rpi64/build/conf

Or you could use the Yocto environment script **oe-init-build-env** like this passing in the path to the build directory

    ~$ source poky-dunfell/oe-init-build-env ~/rpi64/build

The Yocto environment script will create the build directory if it does not already exist.

### Customize the configuration files

There are some sample configuration files in the **meta-rpi/conf** directory.

Copy them to the **build/conf** directory (removing the '-sample')

    ~/rpi64$ cp meta-rpi64/conf/local.conf.sample build/conf/local.conf
    ~/rpi64$ cp meta-rpi64/conf/bblayers.conf.sample build/conf/bblayers.conf

If you used the **oe-init-build-env** script to create the build directory, it generated some generic configuration files in the **build/conf** directory. If you want to look at them, save them with a different name before overwriting. They are not needed.

Also not necessary, but something you may want to do is customize the configuration files before your first build.

**Warning:** Do not use the '**~**' character when defining directory paths in the Yocto configuration files.

### Edit bblayers.conf

In **bblayers.conf** file replace **${HOME}** with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

**WARNING:** Do not include **meta-yocto-bsp** in your **bblayers.conf**. The Yocto BSP requirements for the Raspberry Pi are in **meta-raspberrypi**.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`

    ~/poky-dunfell/
        meta-jumpnow/
        meta-openembedded/
        meta-qt5/
        meta-raspberrypi
        ...

    ~/rpi64/
        meta-rpi64/
        build/
            conf/

<br>

### Edit local.conf

The variables you may want to customize are the following:

- MACHINE
- TMPDIR
- DL\_DIR
- SSTATE\_DIR

<br>

##### MACHINE

The **MACHINE** variable is used to determine the target architecture and various compiler tuning flags.

See the conf files under `meta-raspberrypi/conf/machine` for details.

The only choice for **MACHINE** that I have tested with 64-bit builds is **raspberrypi4-64**.


##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use around **20GB**.

The default location is under the **build** directory, in this example **~/rpi64/build/tmp**.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and builds so I always create a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the **build** directory, **~/rpi64/build/sources**.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then **4GB**. I often put this somewhere else other then my home directory as well.

The default location is in the **build** directory, **~/rpi64/build/sstate-cache**.

#### KERNEL VERSION

The default is **5.4**.

Comment this line

    PREFERRED_VERSION_linux-raspberrypi = "5.4.%"

and uncomment this one

    # PREFERRED_VERSION_linux-raspberrypi = "4.19.%"

to use a **4.19** kernel.

#### ROOT PASSWORD

There is only one login user by default, **root**.

The default password is set to **jumpnowtek** by these two lines in the **local.conf** file

    INHERIT += "extrausers"
    EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

These two lines force a password change on first login

    INHERIT += "chageusers"
    CHAGE_USERS_PARAMS = "chage -d0 root; "

You can comment them out if you do not want that behavior.

If you want no password at all (development only hopefully), comment those four lines and uncomment this line

    EXTRA_IMAGE_FEATURES = "debug-tweaks"

    #INHERIT += "extrausers"
    #EXTRA_USERS_PARAMS = "usermod -P jumpnowtek root; "

    #INHERIT += "chageusers"
    #CHAGE_USERS_PARAMS = "chage -d0 root; "

You can always add or change the password once logged in.

### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The **oe-init-build-env** will not overwrite your customized conf files.

    ~$ source poky-dunfell/oe-init-build-env ~/rpi64/build

    ### Shell environment set up for builds. ###

    You can now run 'bitbake <target>'

    Common targets are:
        core-image-minimal
        core-image-sato
        meta-toolchain
        meta-ide-support

    You can also run generated qemu images with a command like 'runqemu qemux86'

    Other commonly useful commands are:
     - 'devtool' and 'recipetool' handle common recipe tasks
     - 'bitbake-layers' handles common layer tasks
     - 'oe-pkgdata-util' handles common target package tasks

    ~/rpi/build$


I don't use any of those *Common targets*, but instead always write my own custom image recipes.

The **meta-rpi64** layer has some examples under **meta-rpi64/images/** with a lot of the details coming from the **meta-jumpnow/images/basic-dev-image.bb** recipe.

### Build

To build the **console-image** run the following command

    ~/rpi64/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for **zip** failed for some reason, I would run this

    ~/rpi64/build$ bitbake -c cleansstate zip
    ~/rpi64/build$ bitbake zip

And then continue with the full build.

    ~/rpi64/build$ bitbake console-image

To build the `qt5-image` it would be

    ~/rpi64/build$ bitbake qt5-image

The **cleansstate** command (with two s's) works for image recipes as well.

The image files won't get deleted from the **TMPDIR** until the next time you build.


### Copying the binaries to an SD card (or eMMC)

After the build completes, the bootloader, kernel and rootfs image files can be found in **$TMPDIR/deploy/images/$MACHINE** with **TMPDIR** and **MACHINE** coming from your **local.conf**.

The **meta-rpi64/scripts** directory has some helper scripts to format and copy the files to a microSD card.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the RPI.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card.

For example

    ~/rpi64/meta-rpi64/scripts$ lsblk
    NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    loop0    7:0    0  16.9M  1 loop /snap/aws-cli/151
    loop1    7:1    0  91.4M  1 loop /snap/core/8689
    loop2    7:2    0  10.3M  1 loop /snap/doctl/281
    loop3    7:3    0  10.3M  1 loop /snap/doctl/276
    loop4    7:4    0  91.3M  1 loop /snap/core/8592
    sda      8:0    0 931.5G  0 disk
    ├─sda1   8:1    0     1M  0 part
    ├─sda2   8:2    0   150G  0 part /
    ├─sda3   8:3    0   200G  0 part /src
    ├─sda4   8:4    0   200G  0 part /home
    ├─sda5   8:5    0   120G  0 part /oe5
    ├─sda6   8:6    0   120G  0 part /oe6
    └─sda7   8:7    0 141.5G  0 part /oe7
    sdb      8:16   0 447.1G  0 disk
    ├─sdb1   8:17   0   150G  0 part /oe8
    ├─sdb2   8:18   0   150G  0 part /oe9
    └─sdb3   8:19   0 147.1G  0 part /oe10
    sdc      8:32   1   7.4G  0 disk
    ├─sdc1   8:33   1    64M  0 part
    └─sdc2   8:34   1     7.3G  0 part


So I will use **sdc** for the card on this machine.

It doesn't matter if some partitions from the SD card are mounted. The **mk2parts.sh** script will unmount them.

**NOTE**: This script will format any disk on your workstation so make sure you choose the SD card.

The script tries to protect against accidents by not running against any device that has partitions currently mounted. I disable automount on my workstations to avoid having to manually unmount partitions.

    ~$ cd ~/rpi64/meta-rpi64/scripts
    ~/rpi64/meta-rpi64/scripts$ sudo ./mk2parts.sh sdc

You only have to format the SD card once.

#### Temporary mount point

You will need to create a mount point on your workstation for the copy scripts to use.

This is the default

    ~$ sudo mkdir /media/card

You only have to create this directory once.

If you don't want that location, you will have to edit the following scripts to use the mount point you choose.

#### copy_boot.sh

This script copies the GPU firmware, the Linux kernel, dtbs and overlays, config.txt and cmdline.txt to the boot partition of the SD card.

This **copy_boot.sh** script needs to know the **TMPDIR** to find the binaries.

If you use the directory structure described above, the script should figure this out on its own.

If not it looks for an environment variable called **OETMP**.

For instance, if I had this in `build/conf/local.conf`

    TMPDIR = "/oe8/rpi64/tmp-dunfell"

Then I would export this environment variable before running `copy_boot.sh`

    ~/rpi64/meta-rpi64/scripts$ export OETMP=/oe8/rpi64/tmp-dunfell

If you didn't override the default **TMPDIR** in `local.conf`, then set it to the default **TMPDIR**

    ~/rpi64/meta-rpi64/scripts$ export OETMP=~/rpi64/build/tmp

The `copy_boot.sh` script also needs a **MACHINE** environment variable specifying the type of RPi board.

Again the script will attempt to figure this out, but if not you can specify with an environment variable.

	~/rpi64/meta-rpi64/scripts$ export MACHINE=raspberrypi4-64


Then run the **copy_boot.sh** script passing the location of SD card

    ~/rpi64/meta-rpi64/scripts$ ./copy_boot.sh sdc

This script should run very fast.

If you want to customize the **config.txt** or **cmdline.txt** files for the system, you can place either of those files in the **meta-rpi64/scripts** directory and the **copy_boot.sh** script will copy them as well.

Take a look at the script if this is unclear.

#### copy_rootfs.sh

This script copies the root file system to the second partition of the SD card.

The **copy_rootfs.sh** script needs the same **OETMP** and **MACHINE** environment variables.

The script accepts an optional command line argument for the image type, for example **console** or **qt5**. The default is **console** if no argument is provided.

The script also accepts a **hostname** argument if you want the host name to be something other then the default **MACHINE**.

Here's an example of how you would run **copy_rootfs.sh**

    ~/rpi64/meta-rpi64/scripts$ ./copy_rootfs.sh sdc console

or

    ~/rpi64/meta-rpi64/scripts$ ./copy_rootfs.sh sdc qt5 rpi4

The **copy_rootfs.sh** script will take longer to run and depends a lot on the quality of your SD card. With a good **Class 10** card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here is an example session copying the console-image system to an SD card already partitioned.

    ~$ cd rpi64/meta-rpi64/scripts

    ~/rpi64/meta-rpi64/scripts$ ./copy_boot.sh sdc
    MACHINE: raspberrypi4-64
    OETMP: /oe8/rpi64/tmp-dunfell
    Formatting FAT partition on /dev/sdc1
    mkfs.fat 4.1 (2017-01-24)
    Mounting /dev/sdc1
    Copying bootloader files
    Creating overlay directory
    Copying overlay dtbos
    Copying dtbs
    Copying kernel
    Unmounting /dev/sdc1
    Done

    ~/rpi64/meta-rpi64/scripts$ ./copy_rootfs.sh sdc
    MACHINE: raspberrypi4-64
    OETMP: /oe8/rpi64/tmp-dunfell
    IMAGE: console
    HOSTNAME: raspberrypi4-64
    Formatting /dev/sdc2 as ext4
    Mounting /dev/sdc2
    Extracting console-image-raspberrypi4-64.tar.xz to /media/card
    Generating a random-seed for urandom
    1+0 records in
    1+0 records out
    512 bytes copied, 7.5506e-05 s, 6.8 MB/s
    Writing raspberrypi4-64 to /etc/hostname
    Unmounting /dev/sdc2
    Done

Both **copy_boot.sh** and **copy_rootfs.sh** are simple scripts, easily customized.

#### Some custom package examples

[spiloop][spiloop] is a **spidev** test application.

The **bitbake recipe** that builds and packages **spiloop** is here

    meta-jumpnow/recipes-misc/spiloop/spiloop_git.bb

Use it to test the **spidev** driver before and after placing a jumper between pins the SPI data pins.

[tspress][tspress] is a Qt5 QWidget application installed with the `qt5-image`. I use it for testing touchscreens.

The recipe is here and can be used a guide for your own applications.

    meta-rpi64/recipes-qt/tspress/tspress_git.bb

[qmlswipe][qmlswipe] is a Qt5 QML application installed with the `qt5-image`. Again just for basic testing.

The recipe is here and can be used a guide for your own applications.

    meta-rpi64/recipes-qt/qmlswipe/qmlswipe_git.bb

<br>

#### Adding additional packages

To display the list of available recipes from the **meta-layers** included in **bblayers.conf**

    ~$ source poky-dunfell/oe-init-build-env ~/rpi64/build

    ~/rpi64/build$ bitbake -s

Once you have the recipe name, you need to find what packages the recipe produces. Use the **oe-pkgdata-util** utility for this.

For instance, to see the packages produced by the **openssh** recipe

    ~/rpi64/build$ oe-pkgdata-util list-pkgs -p openssh
    openssh-keygen
    openssh-scp
    openssh-ssh
    openssh-sshd
    openssh-sftp
    openssh-misc
    openssh-sftp-server
    openssh-dbg
    openssh-dev
    openssh-doc
    openssh

These are the individual packages you could add to your image recipe.

You can also use **oe-pkgdata-util** to check the individual files a package will install.

For instance, to see the files for the **openssh-sshd** package

    ~/rpi64/build$ oe-pkgdata-util list-pkg-files openssh-sshd
    openssh-sshd:
            /etc/default/volatiles/99_sshd
            /etc/init.d/sshd
            /etc/ssh/moduli
            /etc/ssh/sshd_config
            /etc/ssh/sshd_config_readonly
            /usr/libexec/openssh/sshd_check_keys
            /usr/sbin/sshd


For a package to be installed in your image it has to get into the **IMAGE_INSTALL** variable some way or another. See the example image recipes for some common conventions.

#### A running system

    root@rpi4:~# uname -a
    Linux rpi4 5.4.40-v8 #1 SMP PREEMPT Fri May 15 16:20:21 UTC 2020 aarch64 aarch64 aarch64 GNU/Linux

    root@rpi4:~# cat /etc/issue
    Poky (Yocto Project Reference Distro) 3.1 \n \l

    root@rpi4:~# free
                  total        used        free      shared  buff/cache   available
    Mem:        1896972       38708     1808644         220       49620     1826340
    Swap:             0           0           0

    root@rpi4:~# ifconfig -a
    eth0      Link encap:Ethernet  HWaddr DC:A6:32:31:A5:1C  
              inet addr:192.168.10.206  Bcast:192.168.10.255  Mask:255.255.255.0
              UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
              RX packets:741 errors:0 dropped:1 overruns:0 frame:0
              TX packets:525 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:67727 (66.1 KiB)  TX bytes:66960 (65.3 KiB)

    lo        Link encap:Local Loopback  
              inet addr:127.0.0.1  Mask:255.0.0.0
              UP LOOPBACK RUNNING  MTU:65536  Metric:1
              RX packets:0 errors:0 dropped:0 overruns:0 frame:0
              TX packets:0 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)
    
    wlan0     Link encap:Ethernet  HWaddr DC:A6:32:31:A5:1D  
              BROADCAST MULTICAST  MTU:1500  Metric:1
              RX packets:6 errors:0 dropped:0 overruns:0 frame:0
              TX packets:11 errors:0 dropped:0 overruns:0 carrier:0
              collisions:0 txqueuelen:1000 
              RX bytes:1026 (1.0 KiB)  TX bytes:1782 (1.7 KiB)

    root@rpi4:~# df -h
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/root       7.2G  526M  6.3G   8% /
    devtmpfs        798M     0  798M   0% /dev
    tmpfs           927M  156K  927M   1% /run
    tmpfs           927M   64K  927M   1% /var/volatile

    root@rpi4:~# gcc --version
    gcc (GCC) 9.3.0
    Copyright (C) 2019 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    root@rpi4:~# git --version
    git version 2.24.1

    root@rpi4:~# python3 --version
    Python 3.8.2

    root@rpi4:~# lsmod
        Tainted: G  
    ipv6 544768 18 [permanent], Live 0xffffffc008dfe000
    ipt_REJECT 16384 1 - Live 0xffffffc008bcb000
    nf_reject_ipv4 16384 1 ipt_REJECT, Live 0xffffffc008bc6000
    xt_recent 24576 2 - Live 0xffffffc008b7e000
    xt_tcpudp 16384 4 - Live 0xffffffc008b79000
    xt_state 16384 0 - Live 0xffffffc008b8b000
    xt_conntrack 16384 3 - Live 0xffffffc008b86000
    nf_conntrack 147456 2 xt_state,xt_conntrack, Live 0xffffffc008dd9000
    nf_defrag_ipv4 16384 1 nf_conntrack, Live 0xffffffc008b74000
    nf_defrag_ipv6 20480 2 ipv6,nf_conntrack, Live 0xffffffc008b5f000
    iptable_filter 16384 1 - Live 0xffffffc008b6f000
    ip_tables 32768 2 iptable_filter, Live 0xffffffc008b66000
    x_tables 45056 7 ipt_REJECT,xt_recent,xt_tcpudp,xt_state,xt_conntrack,iptable_filter,ip_tables, Live 0xffffffc008b53000
    brcmfmac 339968 0 - Live 0xffffffc008d85000
    brcmutil 20480 1 brcmfmac, Live 0xffffffc008bad000
    sha256_generic 16384 0 - Live 0xffffffc008b4e000
    libsha256 20480 1 sha256_generic, Live 0xffffffc008b2f000
    bcm2835_codec 49152 0 - Live 0xffffffc008b41000 (C)
    bcm2835_isp 32768 0 - Live 0xffffffc008a6d000 (C)
    bcm2835_v4l2 49152 0 - Live 0xffffffc008bb9000 (C)
    videobuf2_dma_contig 20480 2 bcm2835_codec,bcm2835_isp, Live 0xffffffc008bb3000
    v4l2_mem2mem 36864 1 bcm2835_codec, Live 0xffffffc008ba3000
    bcm2835_mmal_vchiq 36864 3 bcm2835_codec,bcm2835_isp,bcm2835_v4l2, Live 0xffffffc008b99000 (C)
    videobuf2_vmalloc 20480 1 bcm2835_v4l2, Live 0xffffffc008a3c000
    vc4 270336 0 - Live 0xffffffc008d42000
    cfg80211 811008 1 brcmfmac, Live 0xffffffc008c7b000
    videobuf2_memops 16384 2 videobuf2_dma_contig,videobuf2_vmalloc, Live 0xffffffc008b94000
    videobuf2_v4l2 32768 4 bcm2835_codec,bcm2835_isp,bcm2835_v4l2,v4l2_mem2mem, Live 0xffffffc008b38000
    v3d 73728 0 - Live 0xffffffc008b1c000
    videobuf2_common 61440 5 bcm2835_codec,bcm2835_isp,bcm2835_v4l2,v4l2_mem2mem,videobuf2_v4l2, Live 0xffffffc008b0c000
    raspberrypi_hwmon 16384 0 - Live 0xffffffc008b07000
    cec 53248 1 vc4, Live 0xffffffc008c6d000
    rfkill 36864 1 cfg80211, Live 0xffffffc008c47000
    gpu_sched 40960 1 v3d, Live 0xffffffc008c32000
    hwmon 32768 1 raspberrypi_hwmon, Live 0xffffffc008a33000
    videodev 299008 6 bcm2835_codec,bcm2835_isp,bcm2835_v4l2,v4l2_mem2mem,videobuf2_v4l2,videobuf2_common, Live 0xffffffc008bd5000
    snd_soc_core 229376 1 vc4, Live 0xffffffc008ace000
    snd_compress 20480 1 snd_soc_core, Live 0xffffffc008a99000
    mc 57344 6 bcm2835_codec,bcm2835_isp,v4l2_mem2mem,videobuf2_v4l2,videobuf2_common,videodev, Live 0xffffffc008abb000
    snd_pcm_dmaengine 20480 1 snd_soc_core, Live 0xffffffc008ab1000
    vc_sm_cma 40960 1 bcm2835_mmal_vchiq, Live 0xffffffc008aa1000 (C)
    rpivid_mem 16384 0 - Live 0xffffffc008a43000
    snd_pcm 135168 3 vc4,snd_soc_core,snd_pcm_dmaengine, Live 0xffffffc008a77000
    snd_timer 45056 1 snd_pcm, Live 0xffffffc008a27000
    snd 98304 4 snd_soc_core,snd_compress,snd_pcm,snd_timer, Live 0xffffffc008a54000
    uio_pdrv_genirq 16384 0 - Live 0xffffffc008a4c000
    uio 24576 1 uio_pdrv_genirq, Live 0xffffffc008a20000


[rpi]: https://www.raspberrypi.org/
[qt]: http://www.qt.io/
[qml]: http://doc.qt.io/qt-5/qtqml-index.html
[yocto]: https://www.yoctoproject.org/
[raspbian]: https://www.raspbian.org
[meta-rpi64]: https://github.com/jumpnow/meta-rpi64
[rpi-kernel]: https://github.com/raspberrypi/linux
[tspress]: https://github.com/scottellis/tspress
[qmlswipe]:  https://github.com/scottellis/qmlswipe
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: https://jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bitbake]: http://www.yoctoproject.org/docs/2.1/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-sh
[downloads]: https://jumpnowtek.com/downloads/rpi64/
[readme]: https://jumpnowtek.com/downloads/rpi64/README.txt
[firmware-repo]: https://github.com/raspberrypi/firmware
[meta-raspberrypi]: http://git.yoctoproject.org/cgit/cgit.cgi/meta-raspberrypi
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev
[qt-embedded]: http://doc.qt.io/qt-5/embedded-linux.html
[wireguard-linux-compat]: https://git.zx2c4.com/wireguard-linux-compat/about/
