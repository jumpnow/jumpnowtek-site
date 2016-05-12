---
layout: post
title: Building Raspberry Pi Systems with Yocto
description: "Building customized systems for the Raspberry Pi using tools from the Yocto Project"
date: 2016-05-12 10:46:00
categories: rpi
tags: [linux, rpi, yocto, rpi2, rpi3, rpi zero, rpi compute]
---

Building systems for [Raspberry Pi][rpi] boards using tools from the [Yocto Project][Yocto].

The example images in [meta-rpi][meta-rpi] build systems that support C, C++, [Qt5][qt], Perl and Python development, the languages and tools that I commonly use. Other languages are supported, but you will have to add the packages to your image recipe.

Yocto is a good tool for building minimal, customized systems like single function hacking projects or industrial / commercial embedded products.

If you are looking for a full-featured desktop experience you will probably be better off sticking with [Raspbian][raspbian] or another one of the full-featured [RPi distributions][rpi-distros].

If things like quick boot times, small image sizes or read-only rootfs are important to your project, then you might want to use Yocto.

I am using the Yocto [meta-raspberrypi][meta-raspberrypi] layer, but have updated recipes for the Linux kernel, [bootfiles][firmware-repo] and some [userland][userland-repo] components.

I have done some testing with the following boards using the `4.4.8` kernel

* [RPi3][rpi3-b]
* [RPi2][rpi2-b]
* [RPi Zero][rpi-zero]
* [RPi 1 Model B][rpi1-model-b]
* [RPi compute module][rpi-compute] with the [Raspberry Pi Compute Module Dev Kit][rpi-compute-dev-kit]
* [RPi compute module][rpi-compute] with the [Gumstix Pi Compute Dev Board][gumstix-pi-compute]
* [RPi compute module][rpi-compute] with the [Western Digital Media Stick][wd-media-stick]

All boot fine. Ethernet works where applicable. HDMI and USB work. RPi3 wifi works, I have not tried the RPi3 bluetooth. I have it disabled so I can use the serial console.

The serial console works off the header pins on all the boards.  

*SPI*, *I2C* and generic *GPIO* are all standard embedded Linux stuff. *DTS* overlays are available for common configurations.

I have one RPi2 running as my office [music system][rpi-pandora].

I use RPi2s and now the RPi3 frequently as Linux test platforms for Qt applications. I do most Qt development on Windows, but eventually most applications have to run on Linux and MacOS as well. The quad-core RPis work great both for compiling and running Qt5 applications.

 
### Downloads

If you want a quick look at the resulting systems, you can download an example for the RPi 2/3 image [here][downloads]. 

Instructions for installing onto an SD card are in the [README][readme].

### System Info

The Yocto version is `2.1` the `[krogoth]` branch.

The `4.4.9` Linux kernel comes from the [github.com/raspberrypi/linux][rpi-kernel] repository.

These are **sysvinit** systems using [eudev][eudev].

The Qt version is `5.6.0`. There is no *X11* and no desktop installed. [Qt][qt] GUI applications can be run using the `-platform linuxfb` switch.

Perl `5.22` and Python `2.7.11` each with a number of modules is included.

[omxplayer][omxplayer] for playing video and audio files from the command line, hardware accelerated.

[Raspicam][raspicam] command line tools for using the Raspberry Pi camera module.

An example Raspberry Pi [music system][rpi-pandora] using an [IQaudIO Pi-DigiAMP+][digiamp-plus] add-on board and [pianobar][pianobar], a console-based client for [Pandora][pandora] internet radio.

That system also works with the [HiFiBerry Amp+][hifiberry-amp] board.

As of 2016-05-12, here is the list of DTS overlays that are installed with the `4.4.9` kernel running on an RPi2/3

    root@rpi3:~# uname -a
    Linux rpi3 4.4.9 #1 SMP Thu May 12 08:20:50 EDT 2016 armv7l armv7l armv7l GNU/Linux

    root@rpi3:~# ls /mnt/fat/overlays/
    adau1977-adc-overlay.dtb         piscreen-overlay.dtb
    ads7846-overlay.dtb              piscreen2r-overlay.dtb
    akkordion-iqdacplus-overlay.dtb  pitft22-overlay.dtb
    at86rf233-overlay.dtb            pitft28-capacitive-overlay.dtb
    bmp085_i2c-sensor-overlay.dtb    pitft28-resistive-overlay.dtb
    boomberry-dac-overlay.dtb        pps-gpio-overlay.dtb
    boomberry-digi-overlay.dtb       pwm-2chan-overlay.dtb
    dht11-overlay.dtb                pwm-overlay.dtb
    dpi24-overlay.dtb                qca7000-overlay.dtb
    dwc-otg-overlay.dtb              raspidac3-overlay.dtb
    dwc2-overlay.dtb                 rpi-backlight-overlay.dtb
    enc28j60-overlay.dtb             rpi-dac-overlay.dtb
    gpio-ir-overlay.dtb              rpi-display-overlay.dtb
    gpio-poweroff-overlay.dtb        rpi-ft5406-overlay.dtb
    hifiberry-amp-overlay.dtb        rpi-proto-overlay.dtb
    hifiberry-dac-overlay.dtb        rpi-sense-overlay.dtb
    hifiberry-dacplus-overlay.dtb    sdhost-overlay.dtb
    hifiberry-digi-overlay.dtb       sdio-1bit-overlay.dtb
    hy28a-overlay.dtb                sdio-overlay.dtb
    hy28b-overlay.dtb                sdtweak-overlay.dtb
    i2c-gpio-overlay.dtb             smi-dev-overlay.dtb
    i2c-mux-overlay.dtb              smi-nand-overlay.dtb
    i2c-pwm-pca9685a-overlay.dtb     smi-overlay.dtb
    i2c-rtc-overlay.dtb              spi-gpio35-39-overlay.dtb
    i2c0-bcm2708-overlay.dtb         spi1-1cs-overlay.dtb
    i2c1-bcm2708-overlay.dtb         spi1-2cs-overlay.dtb
    i2s-gpio28-31-overlay.dtb        spi1-3cs-overlay.dtb
    i2s-mmap-overlay.dtb             spi2-1cs-overlay.dtb
    iqaudio-dac-overlay.dtb          spi2-2cs-overlay.dtb
    iqaudio-dacplus-overlay.dtb      spi2-3cs-overlay.dtb
    lirc-rpi-overlay.dtb             tinylcd35-overlay.dtb
    mcp2515-can0-overlay.dtb         uart1-overlay.dtb
    mcp2515-can1-overlay.dtb         vc4-kms-v3d-overlay.dtb
    mmc-overlay.dtb                  vga666-overlay.dtb
    mz61581-overlay.dtb              w1-gpio-overlay.dtb
    pi3-act-led-overlay.dtb          w1-gpio-pullup-overlay.dtb
    pi3-disable-bt-overlay.dtb       wittypi-overlay.dtb
    pi3-miniuart-bt-overlay.dtb

I've only tested a few

* hifiberry-amp
* iqaudio-dacplus
* i2s-mmap
* sdhost (the default, but you can overclock now)
* pi3-disable-bt-overlay

They all come from the official Raspberry Pi kernel tree so I have confidence they all work fine. I need  some more hardware to test many of them.


### Ubuntu Setup

I primarily use Ubuntu *15.10* or *16.04* 64-bit server installations. Other versions should work.

You will need at least the following packages installed

    build-essential
    chrpath
    diffstat
    gawk
    git
    libncurses5-dev
    pkg-config
    subversion
    texi2html
    texinfo

You will also want to change the default Ubuntu shell from `dash` to `bash` by running this command from a shell
 
    sudo dpkg-reconfigure dash

Choose **No** to dash when prompted.

### Fedora Setup

I have used a Fedora *23* 64-bit workstation.

The extra packages I needed to install for Yocto were

    chrpath
    perl-bignum
    perl-Thread-Queue
    texinfo

and the package group

    Development Tools

There might be more packages required since I had already installed *qt-creator* and the *Development Tools* group before I did the first build with Yocto.

Fedora already uses `bash` as the shell. 

### Clone the dependency repositories

First the main Yocto project `poky` repository

    scott@octo:~ git clone -b krogoth git://git.yoctoproject.org/poky.git poky-krogoth

The `meta-openembedded` repository

    scott@octo:~$ cd poky-krogoth
    scott@octo:~/poky-krogoth$ git clone -b krogoth git://git.openembedded.org/meta-openembedded

The `meta-qt5` repository

    scott@octo:~/poky-krogoth$ git clone -b krogoth https://github.com/meta-qt5/meta-qt5.git

And finally the `meta-raspberrypi` repository. There is no `[krogoth]` branch yet, so use `[master]`

    scott@octo:~/poky-krogoth$ git clone -b master git://git.yoctoproject.org/meta-raspberrypi

Those 4 repositories shouldn't need modifications other then updates and can be reused for different projects and different boards.

### Clone the meta-rpi repository

Create a separate sub-directory for the `meta-rpi` repository before cloning. This is where you will be doing customizations.

    scott@octo:~$ mkdir ~/rpi
    scott@octo:~$ cd ~/rpi
    scott@octo:~/rpi$ git clone -b krogoth git://github.com/jumpnow/meta-rpi

The `meta-rpi/README.md` file has the last commits from the dependency repositories that I tested. You can always checkout those commits explicitly if you run into problems.

### Initialize the build directory

Much of the following are only the conventions that I use. All of the paths to the meta-layers are configurable.
 
First setup a build directory. I tend to do this on a per board and/or per project basis so I can quickly switch between projects. For this example I'll put the build directory under `~/rpi/` with the `meta-rpi` layer.

You could manually create the directory structure like this

    scott@octo:~$ mkdir -p ~/rpi/build/conf


Or you could use the *Yocto* environment script `oe-init-build-env` like this passing in the path to the build directory

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/rpi/build

The *Yocto* environment script will create the build directory if it does not already exist.
 
### Customize the configuration files

There are some sample configuration files in the `meta-rpi/conf` directory.

Copy them to the `build/conf` directory (removing the '-sample')

    scott@octo:~/rpi$ cp meta-rpi/conf/local.conf-sample build/conf/local.conf
    scott@octo:~/rpi$ cp meta-rpi/conf/bblayers.conf-sample build/conf/bblayers.conf

If you used the `oe-init-build-env` script to create the build directory, it generated some generic configuration files in the `build/conf` directory. It is okay to copy over them.

It is not necessary, but you may want to customize the configuration files before your first build.

Do not use the '**~**' character when defining directory paths in the configuration files. 

### Edit bblayers.conf

In `bblayers.conf` file replace `${HOME}` with the appropriate path to the meta-layer repositories on your system if you modified any of the paths in the previous instructions.

For example, if your directory structure does not look exactly like this, you will need to modify `bblayers.conf`


    ~/poky-krogoth/
         meta-openembedded/
         meta-qt5/
         meta-raspberrypi
         ...

    ~/rpi/
        meta-rpi/
        build/
            conf/


### Edit local.conf

The variables you may want to customize are the following:

- MACHINE
- TMPDIR
- DL\_DIR
- SSTATE\_DIR


The defaults for all of these work fine. Adjustments are optional.

##### MACHINE

The choices are **raspberrypi2** the default or **raspberrypi**.

Use **raspberrypi2** for the RPi3.

There is a new **raspberrypi3** MACHINE option with `[krogoth]`, but all it adds to the **raspberrypi2** configuration is the RPi3 wifi drivers. I prefer to add drivers like that explicitly in my *image* recipe if I need them.

You can only build for one type of MACHINE at a time because of the different instruction sets.

##### TMPDIR

This is where temporary build files and the final build binaries will end up. Expect to use at least 50GB. You probably want at least 80GB available.

The default location is in the `build` directory, in this example `~/rpi/build/tmp`.

If you specify an alternate location as I do in the example conf file make sure the directory is writable by the user running the build.

##### DL_DIR

This is where the downloaded source files will be stored. You can share this among configurations and builds so I always create a general location for this outside the project directory. Make sure the build user has write permission to the directory you decide on.

The default location is in the `build` directory, `~/rpi/build/sources`.

##### SSTATE_DIR

This is another Yocto build directory that can get pretty big, greater then 8GB. I often put this somewhere else other then my home directory as well.

The default location is in the `build` directory, `~/rpi/build/sstate-cache`.

### Run the build

You need to [source][source-script] the Yocto environment into your shell before you can use [bitbake][bitbake]. The `oe-init-build-env` will not overwrite your customized conf files.

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/rpi/build

    ### Shell environment set up for builds. ###

    You can now run 'bitbake '

    Common targets are:
        core-image-minimal
        core-image-sato
        meta-toolchain
        meta-toolchain-sdk
        adt-installer
        meta-ide-support

    You can also run generated qemu images with a command like 'runqemu qemux86'
    scott@octo:~/rpi/build$


I don't use those *Common targets*, but instead use my own custom image recipes.

There are three example images available in the *meta-rpi* layer. The recipes for the images can be found in `meta-rpi/images/`

* console-image.bb
* qt5-image.bb
* audio-image.bb

You should add your own custom images to this same directory.

#### console-image

A basic console developer image. See the recipe `meta-rpi/images/console-image.bb` for specifics, but some of the installed programs are

    gcc/g++ and associated build tools
    git
    ssh/scp server and client
    perl and python with a number of modules
    omxplayer
    raspicam utilities

The *console-image* has a line

    inherit core-image

which is `poky-krogoth/meta/classes/core-image.bbclass` and pulls in some required base packages.  This is useful to know if you create your own image recipe.

#### qt5-image

This image includes the `console-image` and adds `Qt5` with the associated development headers and `qmake`.

#### audio-image

See this [post][rpi-pandora] for details on using this image.

### Build

To build the `console-image` run the following command

    scott@octo:~/rpi/build$ bitbake console-image

You may occasionally run into build errors related to packages that either failed to download or sometimes out of order builds. The easy solution is to clean the failed package and rerun the build again.

For instance if the build for `zip` failed for some reason, I would run this

    scott@octo:~/rpi/build$ bitbake -c cleansstate zip
    scott@octo:~/rpi/build$ bitbake zip

And then continue with the full build.

    scott@octo:~/rpi/build$ bitbake console-image

To build the `qt5-image` it would be

    scott@octo:~/rpi/build$ bitbake qt5-image

The `cleansstate` command (with two s's) works for image recipes as well.

The image files won't get deleted from the *TMPDIR* until the next time you build.

 
### Copying the binaries to an SD card (or eMMC)

After the build completes, the bootloader, kernel and rootfs image files can be found in `<TMPDIR>/deploy/images/raspberrypi2/` or `<TMPDIR>/deploy/images/raspberrypi` depending on `MACHINE`.

The `meta-rpi/scripts` directory has some helper scripts to format and copy the files to a microSD card.

See [this post][rpi-compute-post] for an additional first step required for the [RPi Compute][rpi-compute] eMMC.

#### mk2parts.sh

This script will partition an SD card with the minimal 2 partitions required for the RPI.

Insert the microSD into your workstation and note where it shows up.

[lsblk][lsblk] is convenient for finding the microSD card. 

For example

    scott@octo:~/rpi/meta-rpi$ lsblk
    NAME    MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
    sda       8:0    0 931.5G  0 disk
    |-sda1    8:1    0  93.1G  0 part /
    |-sda2    8:2    0  93.1G  0 part /home
    |-sda3    8:3    0  29.8G  0 part [SWAP]
    |-sda4    8:4    0     1K  0 part
    |-sda5    8:5    0   100G  0 part /oe5
    |-sda6    8:6    0   100G  0 part /oe6
    |-sda7    8:7    0   100G  0 part /oe7
    |-sda8    8:8    0   100G  0 part /oe8
    |-sda9    8:9    0   100G  0 part /oe9
    `-sda10   8:10   0 215.5G  0 part /oe10
    sdb       8:16   1   7.4G  0 disk
    |-sdb1    8:17   1    64M  0 part
    `-sdb2    8:18   1   7.3G  0 part

I would use `sdb` for the format and copy script parameters on this machine.

It doesn't matter if some partitions from the SD card are mounted. The `mk2parts.sh` script will unmount them.

**BE CAREFUL** with this script. It will format any disk on your workstation.

    scott@octo:~$ cd ~/rpi/meta-rpi/scripts
    scott@octo:~/rpi/meta-rpi/scripts$ sudo ./mk2parts.sh sdb

You only have to format the SD card once.

#### /media/card

You will need to create a mount point on your workstation for the copy scripts to use.

    scott@octo:~$ sudo mkdir /media/card

You only have to create this directory once.

#### copy_boot.sh

This script copies the BCM2835 bootloader files, the Linux kernel, dtbs for both RPi 2 and RPi boards and a number of DTB overlays (that I have not tried) to the boot partition of the SD card.

This *copy_boot.sh* script needs to know the `TMPDIR` to find the binaries. It looks for an environment variable called `OETMP`.

For instance, if I had this in the `local.conf`

    TMPDIR = "/oe8/rpi/tmp-krogoth"

Then I would export this environment variable before running `copy_boot.sh`

    scott@octo:~/rpi/meta-rpi/scripts$ export OETMP=/oe8/rpi/tmp-krogoth

If you didn't override the default `TMPDIR` in `local.conf`, then set it to the default `TMPDIR`

    scott@octo:~/rpi/meta-rpi/scripts$ export OETMP=~/rpi/build/tmp

The `copy_boot.sh` script also needs a `MACHINE` environment variable specifying the type of RPi board.

	scott@octo:~/rpi/meta-rpi/scripts$ export MACHINE=raspberrypi2

or

	scott@octo:~/rpi/meta-rpi/scripts$ export MACHINE=raspberrypi


Then run the `copy_boot.sh` script passing the location of SD card

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdb

This script should run very fast.

#### copy_rootfs.sh

This script copies the root file system to the second partition of the SD card.
 
The `copy_rootfs.sh` script needs the same `OETMP` and `MACHINE` environment variables.

The script accepts an optional command line argument for the image type, for example `console` or `qt5-x11`. The default is `console` if no argument is provided.

The script also accepts a `hostname` argument if you want the host name to be something other then the default `raspberrypi2`.

Here's an example of how you'd run `copy_rootfs.sh`

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb console

or

    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb qt5-x11 rpi2

The *copy\_rootfs.sh* script will take longer to run and depends a lot on the quality of your SD card. With a good *Class 10* card it should take less then 30 seconds.

The copy scripts will **NOT** unmount partitions automatically. If an SD card partition is already mounted, the script will complain and abort. This is for safety, mine mostly, since I run these scripts many times a day on different machines and the SD cards show up in different places.

Here's a realistic example session where I want to copy already built images to a second SD card that I just inserted.

    scott@octo:~$ sudo umount /dev/sdb1
    scott@octo:~$ sudo umount /dev/sdb2
    scott@octo:~$ export OETMP=/oe8/rpi/tmp-krogoth
    scott@octo:~$ export MACHINE=raspberrypi2
    scott@octo:~$ cd rpi/meta-rpi/scripts
    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_boot.sh sdb
    scott@octo:~/rpi/meta-rpi/scripts$ ./copy_rootfs.sh sdb console rpi


Both *copy\_boot.sh* and *copy\_rootfs.sh* are simple scripts easily modified for custom use. Once I get past the development stage I usually wrap them both with another script for convenience.

#### Some custom package examples

[spiloop][spiloop] is a *spidev* test application installed in `/usr/bin`.

The *bitbake recipe* that builds and packages *spiloop* is here

    meta-rpi/recipes-misc/spiloop/spiloop_1.0.bb

Use it to test the *spidev* driver before and after placing a jumper between pins *19* and *21*.

[tspress][tspress] is a Qt5 GUI application installed in `/usr/bin` with the *qt5-x11-image*.

The *bitbake recipe* is here

    meta-rpi/recipes-qt/tspress/tspress.bb

Check the *README* in the [tspress][tspress] repository for usage.

[qcolorcheck][qcolorcheck] is another simple Qt5 GUI application. I use it when working on new display drivers. It gets installed in `/usr/bin` with the *qt5-x11-image*.

The *bitbake recipe* is here

    meta-rpi/recipes-qt/qcolorcheck/qcolorcheck.bb

#### Adding additional packages

To display the list of available packages from the `meta-` repositories included in *bblayers.conf*

    scott@octo:~$ source poky-krogoth/oe-init-build-env ~/rpi/build

    scott@octo:~/rpi/build$ bitbake -s

Once you have the package name, you can choose to either

1. Add the new package to the `console-image` or `qt5-image`, whichever you are using.

2. Create a new image file and either include the `console-image` the way the `qt5-image` does or create a complete new image recipe. The `console-image` can be used as a template.

The new package needs to get included directly in the *IMAGE_INSTALL* variable or indirectly through another variable in the image file.

#### Playing videos

I did not install any movies in the default `meta-rpi` images. They can be pretty big.

Recipes for a few sample movies can be found here

    scott@octo:~$ ls -l poky-krogoth/meta-openembedded/meta-multimedia/recipes-multimedia/sample-content/
    total 16
    -rw-rw-r-- 1 scott scott 656 Oct 30 08:56 bigbuckbunny-1080p.bb
    -rw-rw-r-- 1 scott scott 661 Oct 30 08:56 bigbuckbunny-480p.bb
    -rw-rw-r-- 1 scott scott 653 Oct 30 08:56 bigbuckbunny-720p.bb
    -rw-rw-r-- 1 scott scott 576 Oct 30 08:56 tearsofsteel-1080p.bb

If you add one or more of them to the *IMAGE_INSTALL* list in your image recipe, they will get installed under `/usr/share/movies`.

Assuming you have an HDMI display attached, you can play them with `omxplayer` like this

    root@rpi:~# omxplayer -o hdmi /usr/share/movies/ToS-4k-1920.mov

You could also copy videos to the *RPi* after it's running.

Here's an example using one of the sample movies in `meta-openembedded` (*Tears of Steel*).

Get the *URI* from the recipe

    scott@fractal:~$ cat poky-krogoth/meta-openembedded/meta-multimedia/recipes-multimedia/sample-content/tearsofsteel-1080p.bb
    SUMMARY = "Tears of Steel movie - 1080P"
    LICENSE = "CC-BY-3.0"
    LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/CC-BY-3.0;md5=dfa02b5755629022e267f10b9c0a2ab7"
    
    SRC_URI = "http://ftp.nluug.nl/pub/graphics/blender/demo/movies/ToS/ToS-4k-1920.mov"
    SRC_URI[md5sum] = "e3fee55b1779c553e37b1d3988e6fad6"
    SRC_URI[sha256sum] = "bd2b5bc6c16d4085034f47ef7e4b3938afe86b4eec4ac3cf2685367d3b0b23b0"

    inherit allarch

    do_install() {
            install -d ${D}${datadir}/movies
            install -m 0644 ${WORKDIR}/ToS-4k-1920.mov ${D}${datadir}/movies/
    }

    FILES_${PN} += "${datadir}/movies"

Then using `wget` on the *RPi*

    root@rpi2:~# wget http://ftp.nluug.nl/pub/graphics/blender/demo/movies/ToS/ToS-4k-1920.mov
    
    root@rpi2:~# omxplayer -o hdmi ToS-4k-1920.mov
    Video codec omx-h264 width 1920 height 800 profile 100 fps 24.000000
    Audio codec aac channels 2 samplerate 44100 bitspersample 16
    Subtitle count: 0, state: off, index: 1, delay: 0
    V:PortSettingsChanged: 1920x800@24.00 interlace:0 deinterlace:0 anaglyph:0 par:1.00 layer:0 alpha:255

If you get errors like this

    COMXAudio::Decode timeout

Increase memory allocated to the GPU in `config.txt`

    gpu_mem=128


#### Using the Raspberry Pi Camera

The [raspicam][rpi_camera_module] command line tools are installed with the `console-image`.

* raspistill
* raspivid
* raspiyuv

To enable the RPi camera, add or edit the following in the RPi configuration file `config.txt`

    start_x=1
    gpu_mem=128
    disable_camera_led=1   # optional for disabling the red LED on the camera

To get access to `config.txt`, mount the boot partition first

    root@rpi# mkdir /mnt/fat
    root@rpi# mount /dev/mmcblk0p1 /mnt/fat

Then edit, save and reboot.

    root@rpi# vi /mnt/fat/config.txt

or

	root@rpi# nano /mnt/fat/config.txt


A quick test of the camera for 60 seconds (flipping the image because of the way I have my camera mounted)

    root@rpi2# raspistill -t 60000 -hf -vf


[rpi]: https://www.raspberrypi.org/
[raspbian]: https://www.raspbian.org/
[rpi-distros]: https://www.raspberrypi.org/downloads/
[qt]: http://www.qt.io/
[yocto]: https://www.yoctoproject.org/
[meta-rpi]: https://github.com/jumpnow/meta-rpi
[omxplayer]: http://elinux.org/Omxplayer
[rpi-kernel]: https://github.com/raspberrypi/linux
[tspress]: https://github.com/scottellis/tspress
[qcolorcheck]:  https://github.com/scottellis/qcolorcheck
[spiloop]: https://github.com/scottellis/spiloop
[serialecho]: https://github.com/scottellis/serialecho
[lsblk]: http://linux.die.net/man/8/lsblk
[opkg-repo]: http://www.jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
[bitbake]: http://www.yoctoproject.org/docs/2.1/bitbake-user-manual/bitbake-user-manual.html
[source-script]: http://stackoverflow.com/questions/4779756/what-is-the-difference-between-source-script-sh-and-script-sh
[raspicam]: https://www.raspberrypi.org/documentation/usage/camera/raspicam/README.md
[rpi_camera_module]: https://www.raspberrypi.org/documentation/raspbian/applications/camera.md
[downloads]: http://www.jumpnowtek.com/downloads/rpi/
[readme]: http://www.jumpnowtek.com/downloads/rpi/README.txt
[digiamp-plus]: http://www.iqaudio.co.uk/home/9-pi-digiamp-0712411999650.html
[pianobar]: https://6xq.net/pianobar/
[pandora]: http://www.pandora.com
[rpi-pandora]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Pandora-music-player.html
[hifiberry-amp]: https://www.hifiberry.com/ampplus/
[rpi-compute]: https://www.raspberrypi.org/products/compute-module/
[rpi2-b]: https://www.raspberrypi.org/products/raspberry-pi-2-model-b/
[rpi-compute-post]: http://www.jumpnowtek.com/rpi/Working-with-the-raspberry-pi-compute.html
[rpi3-b]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[gumstix-pi-compute]: https://store.gumstix.com/expansion/partners-3rd-party/gumstix-pi-compute-dev-board.html
[rpi-zero]: https://www.raspberrypi.org/products/pi-zero/
[rpi-compute-dev-kit]: https://www.raspberrypi.org/products/compute-module-development-kit/
[rpi1-model-b]: https://www.raspberrypi.org/products/model-b/
[firmware-repo]: https://github.com/raspberrypi/firmware
[userland-repo]: https://github.com/raspberrypi/userland
[meta-raspberrypi]: http://git.yoctoproject.org/cgit/cgit.cgi/meta-raspberrypi
[eudev]: https://wiki.gentoo.org/wiki/Project:Eudev
[wd-media-stick]: http://store.wdc.com/store/wdus/en_US/DisplayAccesoryProductDetailsPage/ThemeID.40718400/Accessories/Media_Stick_for_Raspberry_Pi/productID.331153900/categoryId.70262300