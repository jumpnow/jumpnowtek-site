---
layout: post
title: Managing a custom opkg repository
date: 2014-07-25 12:20:00
categories: yocto
tags: [yocto, github, opkg]
---

## Managing a Custom Opkg Repository

### Get the opkg utilities

     scott@octo:~$ git clone git://git.yoctoproject.org/opkg-utils

### Create a repository directory

    scott@octo:~$ mkdir snapshots
    scott@octo:~$ cd snapshots


### Copy package files to the repository

Grabbing two packages for the example

    scott@octo:~/snapshots$ cp ${OETMP}/deploy/ipk/xz_5.1.2alpha_r0_cortexa9hf-vfp-neon.ipk .
	scott@octo:~/snapshots$ cp ${OETMP}/deploy/ipk/zip_3.0-r2_cortexa9hf-vfp-neon.ipk .

    scott@octo:~/snapshots$ ls -l
    total 248
    -rw-r--r-- 1 scott scott  44206 Jul 24 20:22 xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk
    -rw-r--r-- 1 scott scott 208716 Jul 24 20:22 zip_3.0-r2_cortexa9hf-vfp-neon.ipk


### Create a package manifest

    scott@octo:~/snapshots$ ../opkg-utils/opkg-make-index . > Packages

    scott@octo:~/snapshots$ ls -l
    total 256
    -rw-rw-r-- 1 scott scott    939 Jul 24 20:28 Packages
    -rw-rw-r-- 1 scott scott     98 Jul 24 20:28 Packages.stamps
    -rw-r--r-- 1 scott scott  44206 Jul 24 20:22 xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk
    -rw-r--r-- 1 scott scott 208716 Jul 24 20:22 zip_3.0-r2_cortexa9hf-vfp-neon.ipk

    scott@octo:~/snapshots$ cat Packages
    Package: xz
    Version: 5.1.2alpha-r0
    Depends: liblzma5 (>= 5.1.2alpha), libc6 (>= 2.18)
    Section: base
    Architecture: cortexa9hf-vfp-neon
    Maintainer: Poky <poky@yoctoproject.org>
    MD5Sum: 68647a46a2282d2cf1e03fe22a4378a2
    Size: 44206
    Filename: xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk
    Source: http://tukaani.org/xz/xz-5.1.2alpha.tar.gz
    Description:  xz version 5.1.2alpha-r0  utils for managing LZMA compressed files
    OE: xz
    HomePage: http://tukaani.org/xz/
    License: GPLv2+
    Priority: optional
    
    
    Package: zip
    Version: 3.0-r2
    Depends: libc6 (>= 2.18)
    Section: console/utils
    Architecture: cortexa9hf-vfp-neon
    Maintainer: Poky <poky@yoctoproject.org>
    MD5Sum: 49fd89470ce5fbd2a8506074da6f0e1e
    Size: 208716
    Filename: zip_3.0-r2_cortexa9hf-vfp-neon.ipk
    Source: ftp://ftp.info-zip.org/pub/infozip/src/zip30.tgz
    Description:  zip version 3.0-r2  Archiver for .zip files
    OE: zip
    HomePage: http://www.info-zip.org
    License: BSD-3-Clause
    Priority: optional

    scott@octo:~/snapshots$ cat Packages.stamps
    1406247771 zip_3.0-r2_cortexa9hf-vfp-neon.ipk
    1406247771 xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk

### Compress the package manifest

    scott@octo:~/snapshots$ gzip Packages

    scott@octo:~/snapshots$ ls -l
    total 256
    -rw-rw-r-- 1 scott scott    494 Jul 24 20:28 Packages.gz
    -rw-rw-r-- 1 scott scott     98 Jul 24 20:28 Packages.stamps
    -rw-r--r-- 1 scott scott  44206 Jul 24 20:22 xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk
    -rw-r--r-- 1 scott scott 208716 Jul 24 20:22 zip_3.0-r2_cortexa9hf-vfp-neon.ipk


### Install a web server

Nginx is a good choice

    scott@octo:~/snapshots$ sudo aptitude install nginx

### Allow web access to the repository files

Create a *site* file for the snapshots directory.

Configuration assumes this is just for local testing on a private LAN.

    scott@octo:~$ sudo vi /etc/nginx/sites-available/snapshots

The *snapshots* site file should look something like this

    server {
        listen 80 default_server;
        server_name octo.jumpnow;
        root /home/scott/;

        location /snapshots/ {
            autoindex on;
        }
    }


Disable the nginx *default* site

    scott@octo:~$ sudo rm /etc/nginx/sites-enabled/default

Enable the new *snapshots* site

    scott@octo:~$ sudo ln -s /etc/nginx/sites-available/snapshots /etc/nginx/sites-enabled/snapshots


Restart `nginx`

    scott@octo:~$ sudo /etc/init.d/nginx restart
    * Restarting nginx nginx


### Test with a web server

In a browser, this *URL* would work locally

    http://octo.jumpnow/snapshots/

Displays this

    Index of /snapshots/
    ------------------------------------------------------------------------
    ../
    Packages.gz                                 25-Jul-2014 00:28        494
    Packages.stamps                             25-Jul-2014 00:28         98
    xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk    25-Jul-2014 00:28      44206
    zip_3.0-r2_cortexa9hf-vfp-neon.ipk          25-Jul-2014 00:28     208716


### Setup the opkg conf file on the embedded system

The configuration file for opkg is `/etc/opkg/opkg.conf`

Edit the file to have this for the contents

    src/gz snapshots http://octo.jumpnow/snapshots
    dest root /
    lists_dir ext /var/opkg-lists

