---
layout: post
title: Using a Yocto build workstation as a remote opkg repository
date: 2014-07-24 18:00:00
categories: yocto
tags: [yocto, github, opkg]
---

During development of an embedded Linux system you'll frequently want to add 
software packages that didn't make it into the initial build.

I'm using tools from the [Yocto Project][yocto] to build an embedded Linux 
system and using [opkg][opkg] as the package manager.

After the initial build, there are typically three ways I go about adding new 
software packages to the embedded system 

1. Add the new packages to the *image* recipe, rebuild the image and do a
complete reinstall.
2. Build the packages with bitbake, manually copy the .ipk files to the
target and use *opkg* to install.
3. Configure the systems so that *opkg* on the embedded board can remotely
access packages directly on the build workstation.

Okay, there is a fourth method, building directly on the embedded machine.

I try to use this only for simple testing OR where I can't get a cross-build
working with the *Yocto* tools. I prefer an automated, repeatable cross-build 
process on a server/workstation.

The third method is what this document describes.

### Find your package directory
 
So assuming you've already built a system image with *Yocto*, you can find
the installer files for packages you have already built in

    $(TMPDIR)/deploy/ipk

where *$(TMPDIR)* comes from `build/conf/local.conf` or if it is not defined
in `local.conf` it defaults to `build/tmp`. 

For this example, the *$(TMPDIR)* is `/oe7/dart/tmp-poky-dora-build`.

Here's what it looks like

    scott@octo:/oe7/dart/tmp-poky-dora-build/deploy/ipk$ ls -l
    total 364
    drwxr-xr-x 2 scott scott   4096 Jul 24 19:03 all
    drwxr-xr-x 2 scott scott 344064 Jul 24 19:03 cortexa9hf-vfp-neon
    drwxr-xr-x 2 scott scott  16384 Jul 24 19:03 dart
    -rw-r--r-- 1 scott scott      0 Jul 24 19:03 Packages
    -rw-r--r-- 1 scott scott      0 Jun 18 18:35 Packages.flock
    -rw-r--r-- 1 scott scott     20 Jul 24 19:03 Packages.gz
    -rw-r--r-- 1 scott scott      0 Jul 24 19:03 Packages.stamps

The package install files are in three sub-directories

    all/
    cortexa9hf-vfp-neon/
    dart/

*Yocto* has already created a *Package* manifest file for *opkg* in each of 
these directories.

What I'm calling the *architecture* and *machine* directories will depend 
on the system you are building for and the compiler options you choose.

For this example I'm building a [Variscite OMAP4 Dart][dart-board] system with
hard-floating point enabled.

The *architecture* directory is `cortexa9hf-vfp-neon/`.

The *machine* directory is `dart/`.

Modify these instructions accordingly for your system.


### Setup a web server

I'm running Ubuntu and want to use *nginx* as the web server

    sudo apt-get install nginx

Add a new site configuration file for *nginx*. 

    sudo vi /etc/nginx/sites-available/dart-repo

Here is the contents of `dart-repo`

    server {
        listen 80 default_server;

        # set root to $(TMPDIR)/deploy/ipk/
        root /oe7/dart/tmp-poky-dora-build/deploy/ipk/;

        autoindex on;
    }

Remove the *nginx* default enabled site

    sudo rm /etc/nginx/sites-enabled/default
    
Enable the new *dart-repo* site

    sudo ln -s /etc/nginx/sites-available/dart-repo /etc/nginx/sites-enabled/dart-repo

Restart the server

    sudo /etc/init.d/nginx restart


Point a browser at the workstation IP and you should see something like

    Index of /

    =================================================================
    ../
    all/                             24-Jul-2014 23:03          -
    cortexa9hf-vfp-neon/             24-Jul-2014 23:03          -  
    dart/                            24-Jul-2014 23:03          -  
    Packages                         24-Jul-2014 23:03          0  
    Packages.flock                   24-Jul-2014 23:03          0  
    Packages.gz                      24-Jul-2014 23:03         20
    Packages.stamps                  24-Jul-2014 23:03          0
    =================================================================


### Configure the target system

We need to tell *opkg* on the embedded system where to look for packages.

The *opkg* configuration file is `/etc/opkg/opkg.conf`.

Edit the `opkg.conf` file to look like this

    src/gz all http://192.168.10.8/all
    src/gz cortexa9hf-vfp-neon http://192.168.10.8/cortexa9hf-vfp-neon
    src/gz dart http://192.168.10.8/dart

    dest root /
    lists_dir ext /var/lib/opkg


Replacing `192.168.10.8` with the IP of your build workstation.

### Test it out

First run an *opkg* update. 

Updates are not cached, so after a reboot you must run an update again first 
before running other *opkg* commands.

    root@dart:~# opkg update
    Downloading http://192.168.10.8/all/Packages.gz.
    Inflating http://192.168.10.8/all/Packages.gz.
    Updated list of available packages in /var/lib/opkg/all.
    Downloading http://192.168.10.8/cortexa9hf-vfp-neon/Packages.gz.
    Inflating http://192.168.10.8/cortexa9hf-vfp-neon/Packages.gz.
    Updated list of available packages in /var/lib/opkg/cortexa9hf-vfp-neon.
    Downloading http://192.168.10.8/dart/Packages.gz.
    Inflating http://192.168.10.8/dart/Packages.gz.
    Updated list of available packages in /var/lib/opkg/dart.


Install a package (assumes you've bitbaked *inetutils* and have not already
installed *rsh*)

    root@dart:~# opkg install inetutils-rsh
    Installing inetutils-rsh (1.9.1-r1) to root...
    Downloading http://192.168.10.8/cortexa9hf-vfp-neon/inetutils-rsh_1.9.1-r1_cortexa9hf-vfp-neon.ipk.
    Configuring inetutils-rsh.
    update-alternatives: Linking //usr/bin/rcp to /usr/bin/rcp.inetutils
    update-alternatives: Linking //usr/bin/rexec to /usr/bin/rexec.inetutils
    update-alternatives: Linking //usr/bin/rlogin to /usr/bin/rlogin.inetutils
    update-alternatives: Linking //usr/bin/rsh to /usr/bin/rsh.inetutils


Check for updates

    root@dart:~# opkg list-upgradable

Run updates

    root@dart:~# opkg upgrade


Help with the *opkg* commands can be found by running *opkg* without any 
arguments.

### Refreshing the Package manifests

When you build or rebuild a package with *bitbake* on the build machine, the
*Package* manifests are NOT automatically updated.

The *Package* manifests will be updated if you build an *image* recipe.

Until the *Package* manifests are updated, you won't see new packages on the
embedded machine.

Here's an example

I rebuilt the *opkg-collateral* recipe after making the changes described
in the next section.

The original *PR* was `-r2` and after the change `-r3`.

    scott@octo:/oe7/dart/tmp-poky-dora-build/deploy/ipk/cortexa9hf-vfp-neon$ ls -l opkg-coll*
    -rw-r--r-- 2 scott scott 1248 Jul 25 11:10 opkg-collateral_1.0-r3_cortexa9hf-vfp-neon.ipk
    -rw-r--r-- 2 scott scott  720 Jul 25 11:10 opkg-collateral-dbg_1.0-r3_cortexa9hf-vfp-neon.ipk
    -rw-r--r-- 2 scott scott  750 Jul 25 11:10 opkg-collateral-dev_1.0-r3_cortexa9hf-vfp-neon.ipk

Note that the *Package* manifest files are still old.

    scott@octo:/oe7/dart/tmp-poky-dora-build/deploy/ipk/cortexa9hf-vfp-neon$ ls -l Pack*
    -rw-r--r-- 1 scott scott 3885124 Jul 24 19:03 Packages
    -rw-r--r-- 1 scott scott       0 Jun 18 18:35 Packages.flock
    -rw-r--r-- 1 scott scott  245491 Jul 24 19:03 Packages.gz
    -rw-r--r-- 1 scott scott  239181 Jul 24 19:03 Packages.stamps


The embedded board does not see any changes
    
    root@dart:~# opkg update
    ...

    root@dart:~# opkg list-upgradable

Shows nothing

After rebuilding the *console-image* the *Package* manifests are updated.

    scott@octo:/oe7/dart/tmp-poky-dora-build/deploy/ipk/cortexa9hf-vfp-neon$ ls -l Pack*
    -rw-r--r-- 1 scott scott 3885124 Jul 25 11:17 Packages
    -rw-r--r-- 1 scott scott       0 Jun 18 18:35 Packages.flock
    -rw-r--r-- 1 scott scott  245486 Jul 25 11:17 Packages.gz
    -rw-r--r-- 1 scott scott  239363 Jul 25 11:17 Packages.stamps


Now checking on the embedded board
 
    root@dart:~# opkg update
    ...

    root@dart:~# opkg list-upgradable
    opkg-collateral - 1.0-r2 - 1.0-r3

And if I run an upgrade now

    root@dart:~# opkg upgrade
    Upgrading opkg-collateral on root from 1.0-r2 to 1.0-r3...
    Downloading http://192.168.10.8/cortexa9hf-vfp-neon/opkg-collateral_1.0-r3_cortexa9hf-vfp-neon.ipk.
    Configuring opkg-collateral.
    Collected errors:
     * resolve_conffiles: Existing conffile /etc/opkg/opkg.conf is different from the conffile in the new package. The new conffile will be placed at /etc/opkg/opkg.conf-opkg.

The error is only because I manually modified `/etc/opkg/opkg.conf` and *opkg*
will not overwrite my changes.


### opkg-collateral recipe

The default `opkg.conf` file is generated by the *opkg-collateral* recipe.

You can create a *.bbappend* to add default *src* file entries to `opkg.conf`.

    mkdir -p meta-<your-layer>/recipes-devtools/opkg
    cd meta-<your-layer>/recipes-devtools/opkg
    vi opkg-collateral.bbappend

The contents of `opkg-collateral.bbappend`

    FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

    PRINC := "${@int(PRINC) + 1}"

Then create the new `src` file that the recipe will use to populate `opkg.conf`

    mkdir opkg-collateral
    cd opkg-collateral
    vi src

The contents of `src` will be something like

    src/gz all http://192.168.10.8/all
    src/gz cortexa9hf-vfp-neon http://192.168.10.8/cortexa9hf-vfp-neon
    src/gz dart http://192.168.10.8/dart

Adjust accordingly for your system.
 

[yocto]: https://www.yoctoproject.org/
[opkg]: https://code.google.com/p/opkg/
[dart-board]: http://www.variscite.com/products/system-on-module-som/cortex-a9/dart-4460-cpu-ti-omap-4-omap4460
