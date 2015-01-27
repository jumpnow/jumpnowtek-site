---
layout: post
title: FreeBSD Duovero build workstation setup
description: "Custom crochet configuration for building FreeBSD Duovero systems"
date: 2014-11-25 02:00:00
categories: gumstix-freebsd
tags: [freebsd, gumstix, duovero, crochet]
---

Here's how I've been setting up my FreeBSD workstations for building [Gumstix Duovero][duovero] FreeBSD systems.

I'm using [crochet-freebsd][crochet] to do the heavy lifting.

The faster of the two workstations I'm using can build a *Duovero* image from scratch in about 21 minutes. The slower machine takes about 30 minutes.

### Workstation Install

I'm running *CURRENT* on the build workstations since the switch to the new *3.5 Clang* compiler. There is some new code for ARM boards that requires this version of *Clang* which is the default in *CURRENT*.

I installed from a USB drive using a *amd64-memstick* image from the [FreeBSD ftp site][freebsd-download].

Select *enable sshd* when prompted. You'll also want to add a normal user.

After installation I built the *subversion* port so I could fetch a current `/usr/src`.

Then I followed the [FreeBSD Handbook][fbsd-handbook-current-stable] instructions to update the system to *FreeBSD-CURRENT*. 

And finally I installed these extra ports

* git (for crochet-freebsd and duovero-freebsd)
* kermit (the terminal program I'm most used to, choose any you want from the ports)

I'm doing everything on the workstations through *ssh* sessions, so I don't need much installed.

### Fetch the FreeBSD source

I keep another copy of `CURRENT` source in my home directory that I patch up for the *Duovero* systems.  

Fetch a copy like this

    scott@fbsd:~ % svn co https://svn0.us-east.freebsd.org/base/head ~/src-current


### Fetch the Duovero patches

I'm keeping the Duovero changes to the FreeBSD source in a repository [duovero-freebsd][duovero-freebsd]

Clone it with *git*

    scott@fbsd:~ % git clone git@github.com/scottellis/duovero-freebsd.git

Run the *copy\_to\_src.sh* script to update `~/src-current`.

    scott@fbsd:~ % cd duovero-freebsd
    scott@fbsd:~/duovero-freebsd % ./copy_to_src.sh

The copy script applies my patches for the *Duovero*. I'm working on getting these accepted upstream.

### Crochet setup

I have a branch of *crochet-freebsd* with support for the *Duovero* board here [github.com/scottellis/crochet-freebsd][crochet-scottellis].

Clone it with *git*. You want the `[current]` branch.

    scott@fbsd:~ % git clone -b current git@github.com:scottellis/crochet-freebsd.git


### Fetch and build the Duovero u-boot port

FreeBSD now has *ports* for u-boot for a few ARM boards.

I added 2 more for the *PandaBoard* and the *Duovero*.

You can grab the *shar* archives [here][shar-download].

As root untar them to `/usr/ports/sysutils` like this

    # cd /usr/ports/sysutils
    # sh path/to/u-boot-duovero.shar

That should create a new directory `/usr/ports/sysutils/u-boot-duovero`

Build the port as normal

    # cd /usr/ports/sysutils/u-boot-duovero
    # make install clean

The binaries will be installed in `/usr/local/share/u-boot/u-boot-duovero` which is where the *crochet* scripts will look for them.

Using the u-boot *port*, the *xdev* tools are no longer required when using *crochet*.

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
    
    # uncomment these together
    #option UsrSrc
    #IMAGE_SIZE=$((4096 * 1000 * 1000))

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

The *UsrSrc* option installs `FREEBSD_SRC` onto the SD card as `/usr/src`. You also need to increase the initial SD card image size if installing source.

The lines in the *customize\_freebsd\_partition()* function do the following

1. Add a password of `root` to the `root` account.
2. Allow root logins over ssh.
3. Change the timezone to EST.
4. Trim the *motd* to 2 lines.

### Run crochet

As root

    root@fbsd:/usr/home/scott/crochet-freebsd # ./crochet.sh -c config-duovero.sh

And example of a full build output is [here][crochet-build].

When it's done, you'll have an image in `WORKDIR` that you can [dd(1)][dd] to an SD card.

If you used a *tmpfs* and want to save the image, then be sure to copy the image somewhere permanent or you'll lose it on reboot. I don't usually bother with this since images build so quickly.

[duovero]: https://store.gumstix.com/index.php/category/43/
[crochet]: https://github.com/kientzle/crochet-freebsd
[freebsd-download]: ftp://ftp.freebsd.org/pub/FreeBSD/snapshots/amd64/amd64/ISO-IMAGES/11.0/
[fbsd-handbook-current-stable]: http://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook/current-stable.html
[shar-download]: http://jumpnowtek.com/downloads/freebsd/ports
[crochet-scottellis]: https://github.com/scottellis/crochet-freebsd
[duovero-freebsd]: https://github.com/scottellis/duovero-freebsd
[tmpfs]: http://www.freebsd.org/cgi/man.cgi?query=tmpfs&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
[dd]: http://www.freebsd.org/cgi/man.cgi?query=dd&apropos=0&sektion=0&manpath=FreeBSD+10.1-RELEASE&arch=default&format=html
[crochet-build]: https://gist.github.com/scottellis/7cae83fe9584cd5f157a
