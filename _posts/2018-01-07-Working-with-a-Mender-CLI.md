---
layout: post
title: Working with a Mender CLI
description: "Using a python command line interface to Mender"
date: 2018-02-16 09:46:00
categories: linux
tags: [mender, linux, beaglebone, duovero, wandboard, raspberry pi, technexion, yocto]
---

I came across a useful Python [utility][mender-backend-cli] for working with the [Mender][mender-io] server from a command line.

It simplifies uploading [mender artifacts][mender-artifacts] from a headless build server.

### Background

I am testing with a collection of boards running a [mender server][mender-server-repo] locally

* [BeagleBone][mender-bbb]
* Gumstix [Duovero][mender-duovero]
* [Odroid-C2][mender-odroid-c2]
* [Raspberry Pis][rpi]
* Technexion [edm1-cf-imx6][edm1-cf-imx6] and [edm1-imx6plus][edm1-imx6plus]
* [Wandboard][mender-wandboard]

The mender server is from the **1.3.x branch** using the [standard install instructions][mender-production-installation] with two small exceptions.

1. I have **dynomite** logging disabled as per this [mailing list thread][dynomite-thread] and [patch][dynomite-logging-disable] from Mender. Without it the dynomite docker volume gets big really fast.

2. I changed the Mender  [keygen script][mender-server-keygen] to add a **SubjectAltName** section to the certs it generates. This quiets warnings from Python. The **keygen** patch is not necessary but explains why you might see more warnings then I am showing in the examples. The patch is at the bottom of this post.

### Export REQUESTS\_CA\_BUNDLE

Typical **python requests module** stuff, I exported a **REQUESTS\_CA\_BUNDLE** environment variable so local certs are accepted. I pointed it at the **server.crt** generated by the **keygen** script. The same **server.crt** used in the mender recipe and installed onto the devices.

    ~$ export REQUESTS_CA_BUNDLE=~/mender/mender-server/production/keys-generated/certs/server.crt

### Using the mender-backend cli

I cloned the [mender-backend-cli][mender-backend-cli] and am running it from there. I didn't bother with the install script.

I already have a user account on the server, so I am logging in with that

    ~/mender/mender-backend-cli$ ./mender-backend -s https://fractal.jumpnow user login -u scott@jumpnowtek.com -p <some-password>
    INFO:requests.packages.urllib3.connectionpool:Starting new HTTPS connection (1): fractal.jumpnow
    INFO:root:request successful
    INFO:root:token: 
       ... <long token here>

That command created  a **usertoken** file in the local directory that gets used automatically by later commands.

    scott@fractal:~/mender/mender-backend-cli$ ls -l usertoken
    -rw-rw-r-- 1 scott scott 773 Jan  7 11:29 usertoken

You can use **--help** for any command.

    ~/mender/mender-backend-cli$ ./mender-backend --help
    usage: mender-backend [-h] [-d] [-s SERVICE] [-n] [--cacert CACERT]
                          [-u USER_TOKEN]
                          {deployment,artifact,admission,authentication,inventory,user,device,client}
                          ...

    mender backend client

    positional arguments:
      {deployment,artifact,admission,authentication,inventory,user,device,client}
                            Commands
        deployment          Deployments
        artifact            Artifacts
        admission           Admission
        authentication      Device Authentication
        inventory           Inventory
        user                User commands
        device              Device
        client              Simulate a mender client

    optional arguments:
      -h, --help            show this help message and exit
      -d, --debug           Enable debugging output (default: False)
      -s SERVICE, --service SERVICE
                            Service address (default: https://fractal.jumpnow)
      -n, --no-verify       Skip certificate verification (default: False)
      --cacert CACERT       Server certificate for verification (default: )
      -u USER_TOKEN, --user-token USER_TOKEN
                            User token file (default: usertoken)

Every command requires the **-s SERVER** and the default value pointing to Mender's server is not very useful so I changed the default to my local server by editing this file

    mender/cli/__init__.py 

I will switch the code to using an environment variable later, but for the following examples this is why the commands I am showing do not have a **-s SERVER** specified.

I will show a few commands.

Here is a list of devices.

    scott@fractal:~/mender/mender-backend-cli$ ./mender-backend inventory device list
    INFO:root:loading user token from usertoken
    INFO:requests.packages.urllib3.connectionpool:Starting new HTTPS connection (1): fractal.jumpnow
    devices:
    5a54f15cd502db00014b77c3 (type: beaglebone, updated: 2018-02-10T18:54:43.616Z)
    5a5d1f42d502db0001689ab1 (type: duovero, updated: 2018-02-10T18:55:07.918Z)
    5a772d02d502db0001bbcfcd (type: odroid-c2, updated: 2018-02-10T18:54:53.118Z)
    5a778a68d502db0001bbcfd3 (type: wandboard, updated: 2018-02-10T18:52:38.75Z)
    5a778a5cd502db0001bbcfd1 (type: wandboard, updated: 2018-02-10T18:55:12.87Z)

I built a new **mender-test-image** with Yocto.

I then created a signed artifact of that image using the **sign-mender-image.sh** script

    ~/bbb-mender/meta-bbb/scripts$ ./sign-mender-image.sh
    Creating artifact using the following parameters
    TMPDIR: /oe7/bbbm/tmp-rocko
    Artifact name: bbg-test-2
    Private key: /home/scott/bbb-mender/mender-keys/private.key
    Public key: /home/scott/bbb-mender/mender-keys/public.key
    Source: /oe7/bbbm/tmp-rocko/deploy/images/beaglebone/mender-test-image-beaglebone.ext4

    Running mender-artifact to create signed artifact

    Wrote artifact to /home/scott/bbb-mender/upload/bbg-test-2-signed.mender
    Checking artifact

    Mender artifact:
      Name: bbg-test-2
      Format: mender
      Version: 2
      Signature: signed and verified correctly
      Compatible devices: '[beaglebone]'

    Updates:
      0000:
        Type:   rootfs-image
        Files:
          name:     mender-test-image-beaglebone.ext4
          size:     1073741824
          modified: 2018-01-09 17:32:38 -0500 EST
          checksum: 6789a9fd29595b5b2faa31daffa97fff550cc8124c11fd9e8f0db2be070c653b

    Result from mender-artifact read: 0

So now I can use **mender-backend** to upload the artifact

    ~/mender/mender-backend-cli$ ./mender-backend artifact add \
        -n bbg-test-2 \
        -e 'cli test' \
        ~/bbb-mender/upload/bbg-test-2-signed.mender
    INFO:root:loading user token from usertoken90 - 00:00:00
    INFO:requests.packages.urllib3.connectionpool:Starting new HTTPS connection (1): fractal.jumpnow
    created with URL: ./management/v1/deployments/artifacts/5364e050-390b-41f8-8b8c-9edf9f197e4d
    artifact ID:  5364e050-390b-41f8-8b8c-9edf9f197e4d

And now to start a deployment to the BeagleBone Green device

    $ ./mender-backend deployment add \
        -a 'bbg-test-2' \
        -n test \
        -e 5a54f15cd502db00014b77c3 
    INFO:root:loading user token from usertoken
    INFO:requests.packages.urllib3.connectionpool:Starting new HTTPS connection (1): fractal.jumpnow
    created with URL: ./management/v1/deployments/deployments/fab35a4c-4399-443d-a706-2756fb9027ad
    deployment ID:  fab35a4c-4399-443d-a706-2756fb9027ad

If you wanted to deploy to multiple devices at one time you would use the **-e** parameter multiple times.

So for example deploying a previously uploaded artifact **wandq-test-5** to both wandboards in my test network

    ~/mender/mender-backend-cli$ ./mender-backend deployment add \
        -a wandq-test-5 \
        -n wandboards  \
        -e 5a54b487d502db00014b77b5 \
        -e 5a563257d502db00014b77c7


### keygen patch

This keeps both python and browsers from complaining about the missing **SubjectAltName** entry from the certs generated by the mender-server **keygen** script.

The details on how to add **SubjectAltName** in a one-liner came from this [StackExchange][stackexchange-post] post.

Here's the [patch][keygen-SAN-patch].

Now when running the [keygen][mender-server-keygen] script instead of this command

    CERT_API_CN=fractal.jumpnow CERT_STORAGE_CN=fractal.jumpnow ../keygen

I am using this instead

    CERT_API_CN=fractal.jumpnow CERT_API_SAN=DNS:fractal.jumpnow CERT_STORAGE_CN=fractal.jumpnow CERT_STORAGE_SAN=DNS:fractal.jumpnow ../keygen


[mender-backend-cli]: https://github.com/bboozzoo/mender-backend-cli
[mender-io]: https://mender.io/what-is-mender
[mender-artifacts]: https://docs.mender.io/1.3/architecture/mender-artifacts
[wandboard]: http://www.wandboard.org/
[mender-wandboard]: http://www.jumpnowtek.com/wandboard/Adding-Mender-to-a-Wandboard-System.html
[mender-bbb]: http://www.jumpnowtek.com/beaglebone/Adding-Mender-to-a-BeagleBone-System.html
[mender-duovero]: http://www.jumpnowtek.com/gumstix-linux/Adding-Mender-to-a-Duovero-System.html
[mender-odroid-c2]: http://www.jumpnowtek.com/odroid/Adding-Mender-to-a-Odroid-C2-System.html
[mender-production-installation]: https://docs.mender.io/1.3/administration/production-installation
[stackexchange-post]: https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-command-line
[mender-server-repo]: https://github.com/mendersoftware/integration
[mender-server-keygen]: https://github.com/mendersoftware/integration/blob/master/keygen
[keygen-SAN-patch]: https://gist.github.com/scottellis/b27773a4c8242b1a395854b8418d6900 
[dynomite-thread]: https://groups.google.com/a/lists.mender.io/forum/#!topic/mender/v4nH_Vxsg_s
[dynomite-logging-disable]: https://github.com/mendersoftware/integration/commit/64c9c5287247
[edm1-cf-imx6]: https://www.technexion.com/products/system-on-modules/edm/edm-modules/detail/EDM1-CF-IMX6
[edm1-imx6plus]: https://www.technexion.com/products/system-on-modules/edm/edm-modules/detail/EDM1-IMX6PLUS
[rpi]: https://www.raspberrypi.org