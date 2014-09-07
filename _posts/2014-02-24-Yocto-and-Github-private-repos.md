---
layout: post
title: Using private Github repos with Yocto
date: 2014-02-24 13:21:00
categories: yocto
tags: [yocto, github, private repository]
---

Make sure you have SSH keys for Github setup so that you can do this from a command line on the build machine

    git clone git@github.com:scottellis/private-repo.git

You should run that clone command at least once. If the github server keys are new you'll need to answer the prompt from ssh to accept the new key. If this happens when running *bitbake* the process will hang on the *fetch* stage.

The *SRC_URI* to use in the bitbake recipe is

    SRC_URI="git://git@github.com/scottellis/private-repo.git;protocol=ssh"

