---
layout: post
title: Managing a custom opkg repository
date: 2019-11-07 08:30:00
categories: yocto
tags: [yocto, github, opkg]
---

You might be interested in [this article][workstation-repo-post] if you are still in the development cycle.

### Get the opkg utilities

The Yocto project maintains the opkg tools

     ~/projects$ git clone git://git.yoctoproject.org/opkg-utils

The utility we need can be run directly from the repository.

### Create a repository directory

We need a place to host the packages

    ~$ mkdir snapshots
    ~$ cd snapshots

Now to populate.

### Copy package files to the repository

Grab a few packages

    ~/snapshots$ cp ${OETMP}/deploy/ipk/cortexa9hf-neon/xz_5.2.4-r0_cortexa9hf-vfp-neon.ipk .
    ~/snapshots$ cp ${OETMP}/deploy/ipk/cortexa9hf-neon/zip_3.0-r2_cortexa9hf-vfp-neon.ipk .

    ~/snapshots$ ls -l
    total 148
    -rw-r--r-- 1 scott scott  37404 Nov  7 07:53 xz_5.2.4-r0_cortexa9hf-neon.ipk
    -rw-r--r-- 1 scott scott 106596 Nov  7 07:53 zip_3.0-r2_cortexa9hf-neon.ipk

This is just an example.

### Create a package manifest

Use the **opkg-make-index utility** to create a manifest

    ~/snapshots$ ~/projects/opkg-utils/opkg-make-index . > Packages

    ~/snapshots$ ls -l
    total 156
    -rw-r--r-- 1 scott scott    962 Nov  7 08:05 Packages
    -rw-r--r-- 1 scott scott     85 Nov  7 08:05 Packages.stamps
    -rw-r--r-- 1 scott scott  37404 Nov  7 07:53 xz_5.2.4-r0_cortexa9hf-neon.ipk
    -rw-r--r-- 1 scott scott 106596 Nov  7 07:53 zip_3.0-r2_cortexa9hf-neon.ipk


The Packages file contents

    $ cat Packages
    Package: xz
    Version: 5.2.4-r0
    Depends: libc6 (>= 2.29), liblzma5 (>= 5.2.4), update-alternatives-opkg
    Section: base
    Architecture: cortexa9hf-neon
    Maintainer: Poky <poky@yoctoproject.org>
    MD5Sum: b805ced182e5a7cfbaadadeb7388c27d
    Size: 37404
    Filename: xz_5.2.4-r0_cortexa9hf-neon.ipk
    Source: xz_5.2.4.bb
    Description: Utilities for managing LZMA compressed files
     Utilities for managing LZMA compressed files.
    OE: xz
    HomePage: http://tukaani.org/xz/
    License: GPLv2+
    Priority: optional


    Package: zip
    Version: 3.0-r2
    Depends: libc6 (>= 2.29)
    Section: console/utils
    Architecture: cortexa9hf-neon
    Maintainer: Poky <poky@yoctoproject.org>
    MD5Sum: d6d769099807db66bb50a6c1af11cc1d
    Size: 106596
    Filename: zip_3.0-r2_cortexa9hf-neon.ipk
    Source: zip_3.0.bb
    Description: Compressor/archiver for creating and modifying .zip files
     Compressor/archiver for creating and modifying .zip files.
    OE: zip
    HomePage: http://www.info-zip.org
    License: BSD-3-Clause
    Priority: optional


Here is the stamps file

    $ cat Packages.stamps
    1573131195 xz_5.2.4-r0_cortexa9hf-neon.ipk
    1573131195 zip_3.0-r2_cortexa9hf-neon.ipk


Optionally compress the manifest file for faster downloads

    ~/snapshots$ gzip Packages

    ~/snapshots$ ls -l
    total 156
    -rw-r--r-- 1 scott scott    495 Nov  7 08:05 Packages.gz
    -rw-r--r-- 1 scott scott     85 Nov  7 08:05 Packages.stamps
    -rw-r--r-- 1 scott scott  37404 Nov  7 07:53 xz_5.2.4-r0_cortexa9hf-neon.ipk
    -rw-r--r-- 1 scott scott 106596 Nov  7 07:53 zip_3.0-r2_cortexa9hf-neon.ipk

The repository is ready, now need a web server to deliver.


### Install a web server

Nginx is a good choice

    ~$ sudo aptitude install nginx

Defaults are fine for this example.

This is not a post about web server configuration.

### Allow web access to the repository files

Create a *site* file for the snapshots directory.

Configuration assumes this is just for local testing on a private LAN.

    ~$ sudo vi /etc/nginx/sites-available/snapshots

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

    ~$ sudo rm /etc/nginx/sites-enabled/default

Enable the new *snapshots* site

    ~$ sudo ln -s /etc/nginx/sites-available/snapshots /etc/nginx/sites-enabled/snapshots


Restart `nginx`

    ~$ sudo systemctl restart nginx
    * Restarting nginx nginx

It should be ready to go.

### Test the web server

In a browser, this URL would work locally

    http://octo.jumpnow/snapshots/

Displays this

    Index of /snapshots/
    ------------------------------------------------------------------------
    ../
    Packages.gz                                 25-Jul-2014 00:28        494
    Packages.stamps                             25-Jul-2014 00:28         98
    xz_5.1.2alpha-r0_cortexa9hf-vfp-neon.ipk    25-Jul-2014 00:28      44206
    zip_3.0-r2_cortexa9hf-vfp-neon.ipk          25-Jul-2014 00:28     208716


Or you could just use **curl**

    $ curl http://octo.jumpnow/snapshots/
    <html>
    <head><title>Index of /snapshots/</title></head>
    <body>
    <h1>Index of /snapshots/</h1><hr><pre><a href="../">../</a>
    <a href="Packages">Packages</a>                                                  07-Nov-2019 13:05                 962
    <a href="Packages.stamps">Packages.stamps</a>                                    07-Nov-2019 13:05                  85
    <a href="xz_5.2.4-r0_cortexa9hf-neon.ipk">xz_5.2.4-r0_cortexa9hf-neon.ipk</a>    07-Nov-2019 12:53               37404
    <a href="zip_3.0-r2_cortexa9hf-neon.ipk">zip_3.0-r2_cortexa9hf-neon.ipk</a>      07-Nov-2019 12:53              106596
    </pre><hr></body>
    </html>

Now over to the embedded system.

### Setup the opkg conf file

The configuration file for opkg is `/etc/opkg/opkg.conf`

Edit the file to have this for the contents (omit the /gz if Packages not compressed)

    src/gz snapshots http://octo.jumpnow/snapshots
    dest root /
    lists_dir ext /var/opkg-lists

After that opkg on the device should recognize the opkg server

    root@wandq:~# opkg update
    Downloading http://octo.jumpnow/snapshots/Packages.gz.
    Updated source 'snapshots'.

    root@wandq:~# opkg list xz
    xz - 5.2.4-r0 - Utilities for managing LZMA compressed files
     Utilities for managing LZMA compressed files.

    root@wandq:~# opkg list zip
    zip - 3.0-r2 - Compressor/archiver for creating and modifying .zip files
     Compressor/archiver for creating and modifying .zip files.

The systems is up to date, so not much to test right now.

    root@wandq:~# opkg list-upgradable
    <nothing>

I could manually remove a package

    root@wandq:~# opkg remove zip
    Removing zip (3.0) from root...

And then reinstall from the remote repository

    root@wandq:~# opkg install zip
    Installing zip (3.0) on root
    Downloading http://octo.jumpnow/snapshots/zip_3.0-r2_cortexa9hf-neon.ipk.
    Configuring zip.

So it does work.

[workstation-repo-post]: https://jumpnowtek.com/yocto/Using-your-build-workstation-as-a-remote-package-repository.html
