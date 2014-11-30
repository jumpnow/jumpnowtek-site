---
layout: post
title: FreeBSD Duovero build workstation setup
description: "Custom crochet configuration for building FreeBSD Duovero systems"
date: 2014-11-25 02:00:00
categories: freebsd
tags: [freebsd, gumstix, duovero, crochet]
---

I'm still pretty new to this (cut my teeth on `10.1 RC3`), but here's how I've been setting up my FreeBSD workstations for building [Gumstix Duovero][duovero] images using [crochet-freebsd][crochet].

The faster of the two workstations I'm using can build a *Duovero* image from scratch in about 21 minutes. The slower machine takes about 30 minutes.

I'm pretty happy with the process so far. It's quick enough. No doubt I'll be fine-tuning bits and pieces as I use it more. 

### Workstation Install

The workstations are dedicated to this purpose, no VM. 

I installed from a USB drive using a *amd64-memstick* image from the [FreeBSD ftp site][freebsd-download].

Make sure you select *install src* and *enable sshd* when prompted. You also want to add a normal user.

After installation and setting up the network, I add the following binary packages with [pkg(7)][pkg]

* subversion (for CURRENT source)
* git (for crochet-freebsd and duovero-freebsd)
* gmake (for u-boot builds)
* gsed (for u-boot builds)
* kermit (the terminal program I'm most used to, choose any you want from the ports)


I do everything on the workstations through *ssh* sessions.

### Fetch the FreeBSD source

The workstations run `10.1 RELEASE`, but I'm using `11.0 CURRENT` source for the *Duoveros*.

I'm keeping the `CURRENT` source in my home directory. 

Fetch it like this.

    scott@fbsd:~ % svn co https://svn0.us-east.freebsd.org/base/head ~/src-current

The FreeBSD arm code is progressing rapidly, so you'll want to update regularly

    scott@fbsd:~ % cd ~/src-current
	scott@fbsd:~/src-current % svn up

You probably want to delete the contents of *WORKDIR* (described below) and do a full rebuild when you update this.

### Fetch the Duovero changes

I'm keeping the Duovero changes to the FreeBSD source in a repository [here][duovero-freebsd]

Clone it with *git*

    scott@fbsd:~ % git clone git@github.com/scottellis/duovero-freebsd.git

Run the *copy\_to\_src.sh* script to update `~/src-current`.

    scott@fbsd:~ % cd duovero-freebsd
    scott@fbsd:~/duovero-freebsd % ./copy_to_src.sh
  
You'll also want to update this regularly if you want to follow my stuff.

    scott@fbsd:~/duovero-freebsd % git pull

And then run the *copy\_to\_src.sh* script again.

### Crochet setup

I have a branch of *crochet-freebsd* with support for the *Duovero* board here [github.com/scottellis/crochet-freebsd][crochet-scottellis].

Clone it with *git*. You want the `[duovero]` branch.

    scott@fbsd:~ % git clone -b duovero git@github.com:scottellis/crochet-freebsd.git

Again, update regularly.

### Fetch the u-boot source code

Use ftp to download a tar ball

    scott@fbsd:~ % ftp ftp://ftp.denx.de/pub/u-boot/u-boot-2014.10.tar.bz2

Unpack u-boot in the *crochet-freebsd* directory

    scott@fbsd:~ % cd crochet-freebsd
    scott@fbsd:~/crochet-freebsd % tar xf ../u-boot-2014.10.tar.bz2

That's a onetime process unless the u-boot patches in `crochet-freebsd/board/Duovero/files` change.

If so, delete the `~/crochet-freebsd/u-boot-2014.10/` directory and untar it again.

### Building xdev tools

As root, run the following to build the FreeBSD arm cross-dev tools

    root@fbsd:~ # cd /usr/src

    root@fbsd:/usr/src # make XDEV=arm XDEV_ARCH=armv6 WITH_GCC=1 WITH_GCC_BOOTSTRAP=1 WITHOUT_CLANG=1 WITHOUT_CLANG_BOOTSTRAP=1 WITHOUT_CLANG_IS_CC=1 WITHOUT_TESTS=1 xdev

That's a onetime process.

### Tmpfs work directory (optional)

*Crochet* uses a *work* directory for temporary files when it does a build. Since I have enough memory on these build workstations and since I'm not using them for anything else, I use a memory based [tmpfs(5)][tmpfs] file system for the *work* directory.

If you want to do the same, as root edit `/etc/fstab` and add a line like this

    tmpfs           /work           tmpfs   rw,mode=01777   0       0

Create the mount point

    root@fbsd:~ # mkdir /work

And mount it

    root@fbsd:~ # mount /work

Here's what it looks like after a build

    scott@fbsd:~ % df -h
    Filesystem     Size    Used   Avail Capacity  Mounted on
    /dev/ada0p2    899G     16G    811G     2%    /
    devfs          1.0K    1.0K      0B   100%    /dev
    tmpfs           32G    5.3G     27G    17%    /work


If you don't do this, the default *work* directory will be `~/crochet-freebsd/work`. You can put the *work* directory anywhere you want. See the *config-duovero.sh* script below.


### Adjust the config-duovero.sh script

Here's what my default *config-duovero.sh* script looks like.

    scott@fbsd:~/dev/crochet-freebsd % cat config-duovero.sh
    board_setup Duovero

    WORKDIR=/work
    FREEBSD_SRC=/usr/home/scott/src-current

    FREEBSD_BUILDWORLD_EXTRA_ARGS="-j10"
    FREEBSD_BUILDKERNEL_EXTRA_ARGS="-j10"

    option AutoSize
    option UsrSrc

    #IMAGE_SIZE=$((1024 * 1000 * 1000))

    customize_freebsd_partition () {
        pw moduser root -V etc/ -w yes
        sed -i -e 's/^#PermitRootLogin no/PermitRootLogin yes/' etc/ssh/sshd_config
        cp usr/share/zoneinfo/EST5EDT etc/localtime
        cat etc/motd | head -2 > etc/motd
    }


This is the script that will be fed to *crochet*.

This particular config is for an 8-core workstation that uses the *tmpfs work* directory.

You'll probably want to tweak the script for your build machine.

The *AutoSize* option adds a script to expand the filesystem on the SD card at boot.

The *UsrSrc* option installs `FREEBSD_SRC` onto the SD card as `/usr/src`.

The lines in the *customize\_freebsd\_partition()* function do the following

1. Add a password of `root` to the `root` account.
2. Allow root logins over ssh.
3. Change the timezone to EST.
4. Trim the *motd* to 2 lines.

### Run crochet

As root

    root@fbsd:/usr/home/scott/crochet-freebsd # ./crochet.sh -c config-duovero.sh

And example of a full build output is [here][crochet-build].

When it's done, you'll have an image you can [dd(1)][dd] to an SD card under `WORKDIR`. 

If you used a *tmpfs*, then be sure to copy the image somewhere permanent or you'll lose it on reboot.

### Smaller image files

The default images I'm building are 4GB uncompressed. That's big enough to include the source code. They compress to around *~400 MB* which is still pretty big.

If you want smaller image without including a populated `/usr/src` do the following

1. Comment or remove the `option UsrSrc` line in `config-duovero.sh`
2. Uncomment the `IMAGE_SIZE` line in `config-duovero.sh` to generate a `1GB` image

You don't have to do a full-rebuild. Just delete the image file from `WORKDIR` and run *crochet* again. It should only take a minute or so.

The default `4GB` image size comes from `crochet-freebsd/board/Duovero/setup.sh`.

[duovero]: https://store.gumstix.com/index.php/category/43/
[crochet]: https://github.com/kientzle/crochet-freebsd
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/releases/ISO-IMAGES/10.1/
[pkg]: http://www.freebsd.org/cgi/man.cgi?query=pkg&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
[crochet-scottellis]: https://github.com/scottellis/crochet-freebsd
[duovero-freebsd]: https://github.com/scottellis/duovero-freebsd
[tmpfs]: http://www.freebsd.org/cgi/man.cgi?query=tmpfs&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
[dd]: http://www.freebsd.org/cgi/man.cgi?query=dd&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
[crochet-build]: https://gist.github.com/scottellis/7cae83fe9584cd5f157a