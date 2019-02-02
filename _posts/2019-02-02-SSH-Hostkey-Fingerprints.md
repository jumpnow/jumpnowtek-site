---
layout: post
title: SSH Hostkey Fingerprints
description: "Examining ssh hostkey fingerprints"
date: 2019-02-02 14:55:00
categories: security
tags: [ssh, hostkey, fingerprints, openssh, putty, nmap, winscp, nse]
---

When using ssh to connect to a remote server, the server will present a PKI public key that can be used to identify the server.

As part of session key negotiations, the client will ask the server to prove possession of the private key that goes with this public key.

The first time you connect to a server, ssh clients typically prompt you with a **fingerprint** of the server public key and give you a choice whether or not to continue.

For future connections, ssh clients remembers this fingerprint and will warn you if it ever changes.

On Linux, the fingerprint is usually stored in **~/.ssh/known_hosts**.

On Windows using [putty][putty] or [WinSCP][winscp], the fingerprints are stored in the registry by default.

Fingerprints are generated from a hashing of the public key using either the **md5** or **sha256** hashing algorithm.

So for example, here is a server with the following public keys

    server$ for i in /etc/ssh/*.pub; do echo; echo $i; cat $i; done; echo

    /etc/ssh/ssh_host_ecdsa_key.pub
    ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBK3yWbEKMA5/O8M0V8tKxMPj7BLabRD+o5MQOIEIXW4+AfFZ+XYYNlS7XUV+POkDHFlWd8VtkLZJWP8UwmvuK88= root@oc2

    /etc/ssh/ssh_host_ed25519_key.pub
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOesfEMHbJ878E4a6k5I37DKfcg9y7aXlrstFg8VRW6g root@oc2

    /etc/ssh/ssh_host_rsa_key.pub
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCmbvmrcLgEw0c26Q4IHRLdSDBmpe/QjH9mvpzKahzaPk7R/GdIY7/EhBizizA5cIOlWHlqugOCUd9DdSaMgH0xuX6ot0ExU3rsGpUcVhNXHzsPrWgm8tJ/0wJvDftasjt8Z+IFCbwptLQNWKOCXnAH6RuwvefqPeRPPzqUoIxYYCZQT9haWNpqUP3MiwTzIBaOUGo5Vg4GqSEpxGB1rkRQ2SNHfDWf+BFRoaL709twZl5teGe1hOtEFd9XB5kkJUtAzB24sQZ2A0+AZ37/1kw3ZOEKxm9DkFzaur4dfo1Mj+hF+1cS4Byv8Dt5pooXqdFih5FW09RqqUeThtc9xZFb root@oc2

The **ssh-keygen** utility can be used to show fingerprints, the default uses **sha256** hashing

    server$ for i in /etc/ssh/*.pub; do echo; echo $i; ssh-keygen -lf $i; done; echo

    /etc/ssh/ssh_host_ecdsa_key.pub
    256 SHA256:wcq2B0YttUcSQOJZVOS6u72qdgBztv7AbvkCgGyApFg root@oc2 (ECDSA)

    /etc/ssh/ssh_host_ed25519_key.pub
    256 SHA256:2uZZNuef2qHYGbYIB9BWO0nPqr+ZoxyxWGtx2Hf/Juk root@oc2 (ED25519)

    /etc/ssh/ssh_host_rsa_key.pub
    2048 SHA256:SOwuptNrcECFjxB1tP6jw7Y3CJoDEdu9o4RQvDO6XUw root@oc2 (RSA)

**ssh-keygen** can also show fingerprints using the older **md5** hash algorithm

    server$ for i in /etc/ssh/*.pub; do echo; echo $i; ssh-keygen -E md5 -lf $i; done; echo

    /etc/ssh/ssh_host_ecdsa_key.pub
    256 MD5:c7:4d:2d:72:fe:ba:12:3b:bf:39:53:75:ab:a4:96:2e root@oc2 (ECDSA)

    /etc/ssh/ssh_host_ed25519_key.pub
    256 MD5:62:c0:0b:df:91:c9:fd:dc:23:28:66:16:62:44:4f:d0 root@oc2 (ED25519)

    /etc/ssh/ssh_host_rsa_key.pub
    2048 MD5:c8:fb:66:94:34:44:da:0b:7b:e0:2e:dd:66:74:ec:e1 root@oc2 (RSA)


On the client side, a fairly recent [OpenSSH (7.8p1)][openssh] client will show you **sha256** hashed fingerprints by default

    client$ ssh 192.168.10.240
    The authenticity of host '192.168.10.240 (192.168.10.240)' can't be established.
    ECDSA key fingerprint is SHA256:wcq2B0YttUcSQOJZVOS6u72qdgBztv7AbvkCgGyApFg.
    Are you sure you want to continue connecting (yes/no)?

You can specify if you want to see **md5** fingerprint hashes

    client$ ssh -o FingerprintHash=md5 192.168.10.240
    The authenticity of host '192.168.10.240 (192.168.10.240)' can't be established.
    ECDSA key fingerprint is MD5:c7:4d:2d:72:fe:ba:12:3b:bf:39:53:75:ab:a4:96:2e.
    Are you sure you want to continue connecting (yes/no)?


[Putty (0.7)][putty] uses **md5** fingerprint hashes. I didn't see anywhere to change this.

[WinSCP (5.13.7)][winscp] will show you both **md5** and **sha256** fingerprint hashes.


[Nmap (7.70)][nmap] and in particular the NSE [ssh-hostkey][nse-ssh-hostkey] script uses **md5** fingerprints

    client$ nmap -p22 -n --script ssh-hostkey 192.168.10.240
    Starting Nmap 7.70 ( https://nmap.org ) at 2019-02-02 12:05 EST
    Nmap scan report for 192.168.10.240
    Host is up (0.00059s latency).

    PORT   STATE SERVICE
    22/tcp open  ssh
    | ssh-hostkey:
    |   2048 c8:fb:66:94:34:44:da:0b:7b:e0:2e:dd:66:74:ec:e1 (RSA)
    |   256 c7:4d:2d:72:fe:ba:12:3b:bf:39:53:75:ab:a4:96:2e (ECDSA)
    |_  256 62:c0:0b:df:91:c9:fd:dc:23:28:66:16:62:44:4f:d0 (ED25519)
    MAC Address: 00:1E:06:33:70:56 (Wibrain)

    Nmap done: 1 IP address (1 host up) scanned in 2.78 seconds

Digging a little deeper, NSE script [ssh-hostkey][nse-ssh-hostkey] uses the NSE library [ssh2][nse-ssh2] and in the **ssh2.fetch\_host\_key()** function called by ssh-hostkey there is no facility for specifying the hashing algorithm. It uses **md5**.

    $ cat /usr/share/nmap/nselib/ssh2.lua
    ...
    --- Fetch an SSH-2 host key.
    -- @param host Nmap host table.
    -- @param port Nmap port table.
    -- @param key_type key type to fetch.
    -- @return A table with the following fields: <code>key</code>,
    -- <code>key_type</code>, <code>fp_input</code>, <code>bits</code>,
    -- <code>full_key</code>, <code>algorithm</code>, and <code>fingerprint</code>.
    fetch_host_key = function( host, port, key_type )
      local socket = nmap.new_socket()
      local status
    ...
      socket:close()
      return { key=base64.enc(public_host_key),
               key_type=key_type,
               fp_input=public_host_key,
               bits=bits,
               full_key=('%s %s'):format(key_type,base64.enc(public_host_key)),
               algorithm=algorithm,
               fingerprint=openssl.md5(public_host_key) }
    end
  

Finally, if for some unknown reason you do not have [ssh-keygen][ssh-keygen] available and want to generate fingerprints on the command line, here is a short Linux script that will do it.

    #!/bin/sh

    for i in ${1}/*.pub; do
        echo ""
        echo $i
        md5=$(cat $i | cut -d' ' -f2 | base64 -d | openssl dgst -c -md5 | cut -d' ' -f2)
        echo "   MD5:$md5"
        sha256=$(cat $i | cut -d' ' -f2 | base64 -d | sha256sum | cut -d' ' -f1 | xxd -r -p | base64 | sed 's/=*$//')
        echo "   SHA256:$sha256"
    done

    echo ""

Calling it **fingerprint.sh** and run

    $ ./fingerprint.sh /etc/ssh

    /etc/ssh/ssh_host_ecdsa_key.pub
       MD5:c7:4d:2d:72:fe:ba:12:3b:bf:39:53:75:ab:a4:96:2e
       SHA256:wcq2B0YttUcSQOJZVOS6u72qdgBztv7AbvkCgGyApFg

    /etc/ssh/ssh_host_ed25519_key.pub
       MD5:62:c0:0b:df:91:c9:fd:dc:23:28:66:16:62:44:4f:d0
       SHA256:2uZZNuef2qHYGbYIB9BWO0nPqr+ZoxyxWGtx2Hf/Juk

    /etc/ssh/ssh_host_rsa_key.pub
       MD5:c8:fb:66:94:34:44:da:0b:7b:e0:2e:dd:66:74:ec:e1
       SHA256:SOwuptNrcECFjxB1tP6jw7Y3CJoDEdu9o4RQvDO6XUw



[openssh]: https://www.openssh.com/
[putty]: https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
[winscp]: https://winscp.net/eng/index.php
[nmap]: https://nmap.org/
[nse-ssh-hostkey]: https://nmap.org/nsedoc/scripts/ssh-hostkey.html
[nse-ssh2]: https://nmap.org/nsedoc/lib/ssh2.html
[ssh-keygen]: https://man.openbsd.org/ssh-keygen
