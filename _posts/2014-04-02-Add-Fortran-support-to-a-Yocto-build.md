---
layout: post
title: Adding Fortran support to a Yocto build
description: "Adding the Fortran compiler and runtime support to a Yocto build"
date: 2014-04-02 09:43:00
categories: yocto
tags: [linux, yocto, fortran]
---

Being asked to add support for `Fortran` is a rare thing. I am not a `Fortran` developer.

Here are some notes while it's still fresh.

This is was done using tools from the [Yocto Project][yocto] version *1.5.1*, the `[dora]` branch.

## Build

#### local.conf

Add the following line to your `build/conf/local.conf`

    # Enable fortran
    FORTRAN_forcevariable = ",fortran"

#### gcc-runtime.bbappend

Add this one-liner `bbappend` to the `gcc-runtime` recipe

    scott@octo:~/<project>$ cat meta-<project>/recipes-devtools/gcc/gcc-runtime_4.8.bbappend
    RUNTIMETARGET += "libgfortran"

#### Add packages

Add these to your image recipe

    ...
    FORTRAN_TOOLS = " \
        gfortran \
        gfortran-symlinks \
        libgfortran \
        libgfortran-dev \
     "
    ...
    IMAGE_INSTALL += " \
        ...
        ${FORTRAN_TOOLS} \
        ...
     "
     ...

You should do this before building the first time or you'll just have to wait for it a second time. The `gcc-runtime` modification will force a recompile of `gcc` leading to a rebuild of almost everything else.

## Testing

I grabbed some `Fortran` test code from the WikiBooks [Fortran/Fortran examples][fortran-wikibook-examples] page.

I'm using the [Summations with a DO loop][summations-example] example.

#### Native compile and run

Copy the example code to the target board (I'm using a [Gumstix Overo][overo]) and compile it with this command

    root@overo:~# ls
    sum.f90
    root@overo:~# gfortran -o fsum sum.f90
    root@overo:~# ls
    fsum  sum.f90

Here's a run

    root@overo:~# ./fsum
     This program performs summations. Enter 0 to stop.
     Add:
    1
     Add:
    2
     Add:
    3
     Add:
    4
     Add:
    0
     Summation =          10

    root@overo:~# ls
    SumData.DAT  fsum  sum.f90

#### Cross-compile

Setup an environment pointed at the cross-build tools. A script like this will work.

    --- set-fortran-env.sh ---
    export STAGEDIR=$OETMP/sysroots/`uname -m`-linux/usr

    # soft-float
    export PATH=${STAGEDIR}/bin:${STAGEDIR}/bin/armv7a-vfp-neon-poky-linux-gnueabi:${PATH}

    # hard-float
    # export PATH=${STAGEDIR}/bin:${STAGEDIR}/bin/cortexa8hf-vfp-neon-poky-linux-gnueabi:${PATH}

    unset CFLAGS CPPFLAGS CXXFLAGS LDFLAGS

    export ARCH="arm"
    export CROSS_COMPILE="arm-poky-linux-gnueabi-"
    --- end set-fortran-env.sh ---

Before sourcing that file, export an `OETMP` environment variable that is the same as the Yocto `build/conf/local.conf` `TMPDIR` variable.

    export OETMP=/oe8/tmp-poky-dora-build

The default location for `TMPDIR` is `<project>/build/tmp`. But `local.conf` is where it comes from.

After that, a `Makefile` like the following will work

    --- Makefile ---
    # Use Yocto cross-tools to compile a Fortran program
    # Source the setup-fortran-env.sh script first

    CC = arm-poky-linux-gnueabi-gfortran

    SRC = sum.f90
    TARGET = fsum

    $(TARGET): $(SRC)
            $(CC) $(SRC) -o $(TARGET)
    --- end Makefile ---


So it goes like this

    scott@octo:~/<project>/fortran$ ls -l
    total 8
    drwxrwxr-x 2 scott scott 4096 Apr  2 11:06 fsum
    -rwxrwxr-x 1 scott scott  270 Apr  2 10:56 set-fortran-env.sh

    scott@octo:~/<project>/fortran$ export OETMP=/oe8/tmp-poky-dora-build

    scott@octo:~/<project>/fortran$ source set-fortran-env.sh

    scott@octo:~/<project>/fortran$ cd fsum
    scott@octo:~/<project>/fortran/fsum$ ls -l
    total 8
    -rw-rw-r-- 1 scott scott 215 Apr  2 10:58 Makefile
    -rw-rw-r-- 1 scott scott 460 Apr  2 10:13 sum.f90

    scott@octo:~/<project>/fortran/fsum$ make
    arm-poky-linux-gnueabi-gfortran sum.f90 -o fsum

    scott@octo:~/<project>/fortran/fsum$ ls -l
    total 20
    -rwxrwxr-x 1 scott scott 12098 Apr  2 11:08 fsum
    -rw-rw-r-- 1 scott scott   215 Apr  2 10:58 Makefile
    -rw-rw-r-- 1 scott scott   460 Apr  2 10:13 sum.f90


Copy the `fsum` executable to the target board and it should run.

[yocto]: https://www.yoctoproject.org/
[fortran-wikibook-examples]: http://en.wikibooks.org/wiki/Fortran/Fortran_examples
[summations-example]: http://en.wikibooks.org/wiki/Fortran/Fortran_examples#Summations_with_a_DO_loop
[overo]: https://store.gumstix.com/index.php/category/33/
