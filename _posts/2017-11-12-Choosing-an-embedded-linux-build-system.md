---
layout: post
title: Choosing an embedded Linux build system
date: 2017-11-12 12:32:00
categories: linux
tags: [linux, embedded, buildroot, yocto, qt5]
---

[Buildroot][buildroot] and [Yocto/Open Embedded][yocto] are two popular open source frameworks for building custom embedded Linux systems. 

Both are primarily targeted at commercial projects. Neither is a particularly good choice if you just want to build a general purpose Linux system.

An important point is that you can build similar systems with either framework with a few exceptions noted below.

So here is the quick summary I give customers when asked.

#### Common Features

* Complete system build from source
* Allow choice of kernel and bootloader
* Support for modifying packages with patches or custom configuration files
* Can build cross-toolchains for development
* Convenient support for read-only root filesystems
* Support offline builds
* The build configuration files integrate well with SCM tools

<br />
#### Buildroot Advantages

* Simple Makefile approach, easier to understand how the build system works
* Reduced resource requirements on the build machine
* Very easy to customize the final root filesystem (overlays) 

<br />
#### Yocto Advantages

* Convenient sharing of build configuration among similar projects (meta-layers)
* Larger community ([Linux Foundation][linux-foundation] project)
* Can build a toolchain that runs on the target
* A package management system 

Those last two are deliberate decisions by **Buildroot** and not usually issues for commercial products

1. End-user products don't typically require dev tools

2. [Full-system A/B upgrades][AB-upgrades] are usually a better solution for embedded systems then incremental package upgrades

<br />
#### Summary

If you have decided on a package manager approach to upgrades or have a family of products with slightly different package requirements, I would recommend **Yocto**.

Otherwise I would recommend **Buildroot**. 

It's just easier.

[buildroot]: https://buildroot.org/
[yocto]: https://www.yoctoproject.org/
[AB-upgrades]: http://www.jumpnowtek.com/yocto/An-upgrade-strategy-for-embedded-Linux-systems.html
[linux-foundation]: https://www.linuxfoundation.org/