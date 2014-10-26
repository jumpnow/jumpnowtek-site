---
layout: post
title: Adding Go language support to a Yocto build
date: 2014-10-20 16:26:00
categories: linux yocto golang
tags: [linux, yocto, golang]
---

There is an existing Yocto *meta-layer* to add support for cross-building [golang][golang] programs as part of an image. This makes it very easy to add *golang* programs to your Yocto built systems.

Note that this is for cross-compiling only. There is no native golang compiler that gets installed on the target device.

Using [these instructions][overo-build] for a [Gumstix Overo][overo] as a base, here is what you need to add to your Yocto configuration

### Fetch the Go meta-layer

I'm going to put the layer in it's own directory. You can put it somewhere else.

    $ mkdir ~/golang
    $ cd golang
    $ git clone https://github.com/errordeveloper/oe-meta-go.git


### Add the new layer to bblayers.conf

Note the new path you are adding must point to where you *cloned* the repo above.

    $ cd ~/overo/build/conf
    $ <edit> bblayers.conf

    ...

    BBLAYERS ?= " \
      ${HOME}/poky-daisy/meta \
      ${HOME}/poky-daisy/meta-yocto \
      ${HOME}/poky-daisy/meta-openembedded/meta-oe \
      ${HOME}/poky-daisy/meta-openembedded/meta-networking \
    +  ${HOME}/golang/oe-meta-go \
      ${HOME}/overo/meta-overo \
      "
    ...

### Add the example helloworld app to an image

There is an example program recipe in the *oe-meta-go* layer 

    oe-meta-go/recipes-devtools/examples/helloworld_0.1.bb

You can use it as a template for your own programs.

I'm going to create a new image recipe to add *go-helloworld* too, but you could also just add the package too an existing image recipe's *IMAGE_INSTALL*.

I'm using an existing *console-image* recipe to configure the bulk of the system.

    $ cd ~/overo/meta-overo/images
    $ <edit> go-image.bb

    SUMMARY = "A development image with a go program"
    HOMEPAGE = "http://www.jumpnowtek.com"
    LICENSE = "MIT"

    require console-image.bb

    GOLANG_STUFF = " \
        go-helloworld \
     "

    IMAGE_INSTALL += " \
        ${GOLANG_STUFF} \
     "

    export IMAGE_BASENAME = "go-image"

### Build the new image

    $ source ~/poky-daisy/oe-init-build-env ~/overo/build
    $ bitbake go-image

After it builds, install the image to an SD card as usual.

### Test
 
    root@overo:~# opkg list-installed | grep hello
    go-helloworld - 0.1-r0

    root@overo:~# ls -l /usr/bin/helloworld
    -rwxr-xr-x 1 root root 1097752 Oct 20 16:07 /usr/bin/helloworld

    root@overo:~# helloworld
    Hello, 世界


[golang]: http://golang.org/
[overo-build]: http://www.jumpnowtek.com/gumstix/overo/Overo-Systems-with-Yocto.html
[overo]: https://www.gumstix.com