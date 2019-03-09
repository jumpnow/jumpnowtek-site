---
layout: post
title: Enumerating SSH Algorithms with Nmap
description: "Using the Nmap ssh2-enum-algos script to check an ssh server"
date: 2019-02-07 08:30:00
categories: security
tags: [ssh, nmap, ssh2-enum-algos, encryption, keys, nse]
---

[SSH][ssh] is an extremely popular way to securely communicate with a remote host.

An SSH session starts with the two sides first negotiating a set of encryption protocols to use.

They do this by each sending a list of supported algorithms and agreeing to use one of them.

Then after a [Diffie-Hellman][diffie-hellman] exchange to get a session key, encrypted communications can begin starting with [hostkey-fingerprint][hostkey-fingerprints] checks and authentication.

As with [SSL/TLS][nmap-tls-check], Nmap can be used to check the encryption algorithms an SSH server supports using an [NSE script][nsedoc].

The script for this is called [ssh2-enum-algos][ssh2-enum-algos] and run against an [OpenSSH][openssh] server the output will look something like this

    # nmap -p22 -n -sV --script ssh2-enum-algos 192.168.10.221
    Starting Nmap 7.70 ( https://nmap.org ) at 2019-02-07 06:12 EST
    Nmap scan report for 192.168.10.221
    Host is up (0.00059s latency).

    PORT   STATE SERVICE VERSION
    22/tcp open  ssh     OpenSSH 7.8 (protocol 2.0)
    | ssh2-enum-algos:
    |   kex_algorithms: (10)
    |       curve25519-sha256
    |       curve25519-sha256@libssh.org
    |       ecdh-sha2-nistp256
    |       ecdh-sha2-nistp384
    |       ecdh-sha2-nistp521
    |       diffie-hellman-group-exchange-sha256
    |       diffie-hellman-group16-sha512
    |       diffie-hellman-group18-sha512
    |       diffie-hellman-group14-sha256
    |       diffie-hellman-group14-sha1
    |   server_host_key_algorithms: (5)
    |       rsa-sha2-512
    |       rsa-sha2-256
    |       ssh-rsa
    |       ecdsa-sha2-nistp256
    |       ssh-ed25519
    |   encryption_algorithms: (6)
    |       chacha20-poly1305@openssh.com
    |       aes128-ctr
    |       aes192-ctr
    |       aes256-ctr
    |       aes128-gcm@openssh.com
    |       aes256-gcm@openssh.com
    |   mac_algorithms: (10)
    |       umac-64-etm@openssh.com
    |       umac-128-etm@openssh.com
    |       hmac-sha2-256-etm@openssh.com
    |       hmac-sha2-512-etm@openssh.com
    |       hmac-sha1-etm@openssh.com
    |       umac-64@openssh.com
    |       umac-128@openssh.com
    |       hmac-sha2-256
    |       hmac-sha2-512
    |       hmac-sha1
    |   compression_algorithms: (1)
    |_      none
    MAC Address: 00:1F:7B:B4:01:3F (TechNexion)

    Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    Nmap done: 1 IP address (1 host up) scanned in 2.25 seconds



In embedded Linux systems it is not uncommon to use [Dropbear][dropbear] as the SSH server because of the smaller footprint it has over OpenSSH.

For example, the open-source firewall/router [pfSense][pfsense] uses Dropbear SSH. Router firmware [Asuswrt][asuswrt] and third-party versions of Asuswrt like [Asuswrt-merlin][asuswrt-merlin] also use Dropbear.

The embedded Linux build frameworks [Yocto][yocto] and [Buildroot][buildroot] both provide Dropbear as an SSH server option and it is the default for their smaller systems.

Unfortunately the default [ssh2-enum-algos][ssh2-enum-algos] script does not work against a [Dropbear][dropbear] server.

The problem is the script is a little too rigid in the way it expects the communications to go.

The script wants the following exchange

    Server -> Banner
              Banner <- Client
              Key Exchange Init <- Client
    Server -> Key Exchange Init

That works fine with an OpenSSH server and the script shows the algorithms the server provided in the *Key Exchange Init*.

A Dropbear server sends both a *Banner* and *Key Exchange Init* in the same packet saving a round-trip.

So the script processing goes like this and fails.

    Server -> Banner, Key Exchange Init
              Banner <- Client
              Key Exchange Init <- Client
    Server -> <nothing>


Here is what it looks like.

For this test I was running a Dropbear server on a workstation on port 2222.

    # nmap -p2222 -n -sV --script ssh2-enum-algos 192.168.10.12
    Starting Nmap 7.70 ( https://nmap.org ) at 2019-02-07 06:14 EST
    Nmap scan report for 192.168.10.12
    Host is up (0.00082s latency).

    PORT     STATE SERVICE VERSION
    2222/tcp open  ssh     Dropbear sshd 2018.76 (protocol 2.0)
    MAC Address: 08:62:66:4C:29:91 (Asustek Computer)
    Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

    Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    Nmap done: 1 IP address (1 host up) scanned in 2.21 seconds

Normal fail behavior for Nmap scripts is to stay silent.

It was not a big change to the ssh2-enum-algos script to enable handling a Dropbear server.

Basically just check if the server *Banner* was for Dropbear and continue parsing out the *Key Exchange Init* already received.

The sending of the client *Banner* and *KEX* packets can also be skipped.

After those changes

    # nmap -p2222 -n -sV --script /opt/ssh2-enum-algos.nse 192.168.10.12
    Starting Nmap 7.70 ( https://nmap.org ) at 2019-02-07 05:52 EST
    Nmap scan report for 192.168.10.12
    Host is up (0.00077s latency).

    PORT     STATE SERVICE VERSION
    2222/tcp open  ssh     Dropbear sshd 2018.76 (protocol 2.0)
    | ssh2-enum-algos:
    |   kex_algorithms: (8)
    |       curve25519-sha256
    |       curve25519-sha256@libssh.org
    |       ecdh-sha2-nistp521
    |       ecdh-sha2-nistp384
    |       ecdh-sha2-nistp256
    |       diffie-hellman-group14-sha256
    |       diffie-hellman-group14-sha1
    |       kexguess2@matt.ucc.asn.au
    |   server_host_key_algorithms: (3)
    |       ecdsa-sha2-nistp256
    |       ssh-rsa
    |       ssh-dss
    |   encryption_algorithms: (6)
    |       aes128-ctr
    |       aes256-ctr
    |       aes128-cbc
    |       aes256-cbc
    |       3des-ctr
    |       3des-cbc
    |   mac_algorithms: (3)
    |       hmac-sha1-96
    |       hmac-sha1
    |       hmac-sha2-256
    |   compression_algorithms: (2)
    |       zlib@openssh.com
    |_      none
    MAC Address: 08:62:66:4C:29:91 (Asustek Computer)
    Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

    Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
    Nmap done: 1 IP address (1 host up) scanned in 2.22 seconds


I sent a [patch][nmap-pull] to the Nmap developers, but no feedback yet.

That patch is for the current development branch of Nmap.

To use with released versions of Nmap, switch back to **stdnse.strsplit** instead of the newer **stringaux.strsplit**.

On a related note, [Ncrack][ncrack], the standalone brute-force passsword cracking tool, also fails against Dropbear SSH servers for the same reason. A similar tool [Hydra][thc-hydra] has no problems with Dropbear.

But all is not lost as the NSE [ssh-brute][ssh-brute] script does work against either Dropbear or OpenSSH.

[ssh]: https://en.wikipedia.org/wiki/Secure_Shell
[nmap-tls-check]: https://jumpnowtek.com/security/Using-nmap-to-check-certs-and-supported-algos.html
[nmap]: https://nmap.org/
[nsedoc]: https://nmap.org/nsedoc/
[ssh2-enum-algos]: https://nmap.org/nsedoc/scripts/ssh2-enum-algos.html
[dropbear]: https://matt.ucc.asn.au/dropbear/dropbear.html
[openssh]: https://www.openssh.com/
[yocto]: https://www.yoctoproject.org/
[buildroot]: https://buildroot.org/
[pfsense]: https://www.pfsense.org/
[asuswrt]: https://www.asus.com/us/ASUSWRT/
[asuswrt-merlin]: https://asuswrt.lostrealm.ca/
[diffie-hellman]: https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange
[nmap-pull]: https://github.com/nmap/nmap/pull/1460
[ncrack]: https://nmap.org/ncrack/
[ssh-brute]: https://nmap.org/nsedoc/scripts/ssh-brute.html
[hostkey-fingerprints]: https://jumpnowtek.com/security/SSH-Hostkey-Fingerprints.html
[thc-hydra]: https://github.com/vanhauser-thc/thc-hydra
