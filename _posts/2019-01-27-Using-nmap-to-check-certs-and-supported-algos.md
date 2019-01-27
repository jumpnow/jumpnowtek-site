---
layout: post
title: Using Nmap to check certs and supported TLS algorithms
description: "Use Nmap to look at certs and enumerating a servers supported TLS algorithms list"
date: 2019-01-27 12:30:00
categories: security
tags: [nmap, tls, ssl, certificates]
---

[Nmap][nmap] scripts can be used to quickly check a server certificate and the TLS algorithms supported.

The [OWASP site][owasp] has a whole lot more on [testing SSL/TLS][owasp-tls-testing], but these Nmap scripts are a convenient first pass.

Use the [ssl-cert][nmap-ssl-cert] script to look at a certificate

    $ nmap --script ssl-cert -p 443 jumpnowtek.com

    Starting Nmap 7.60 ( https://nmap.org ) at 2019-01-27 11:34 EST
    Nmap scan report for jumpnowtek.com (166.78.186.4)
    Host is up (0.076s latency).

    PORT    STATE SERVICE
    443/tcp open  https
    | ssl-cert: Subject: commonName=jumpnowtek.com
    | Subject Alternative Name: DNS:jumpnowtek.com
    | Issuer: commonName=Let's Encrypt Authority X3/organizationName=Let's Encrypt/countryName=US
    | Public Key type: rsa
    | Public Key bits: 2048
    | Signature Algorithm: sha256WithRSAEncryption
    | Not valid before: 2018-12-27T21:17:55
    | Not valid after:  2019-03-27T21:17:55
    | MD5:   4fb8 940d fb34 4d8d efff e0e1 4035 2da0
    |_SHA-1: 0b72 7673 23f8 2a35 3fde a1ce e3c4 26e2 6415 1a31

    Nmap done: 1 IP address (1 host up) scanned in 1.13 seconds

Use the [ssl-enum-ciphers][nmap-ssl-enum-ciphers] script to see the SSL/TLS algorithms a server supports

    $ nmap --script ssl-enum-ciphers -p 443 jumpnowtek.com

    Starting Nmap 7.60 ( https://nmap.org ) at 2019-01-27 11:35 EST
    Nmap scan report for jumpnowtek.com (166.78.186.4)
    Host is up (0.075s latency).

    PORT    STATE SERVICE
    443/tcp open  https
    | ssl-enum-ciphers:
    |   TLSv1.0:
    |     ciphers:
    |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |       TLS_DHE_RSA_WITH_AES_128_CBC_SHA (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_256_CBC_SHA (dh 2048) - A
    |       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |     compressors:
    |       NULL
    |     cipher preference: server
    |   TLSv1.1:
    |     ciphers:
    |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |       TLS_DHE_RSA_WITH_AES_128_CBC_SHA (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_256_CBC_SHA (dh 2048) - A
    |       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |     compressors:
    |       NULL
    |     cipher preference: server
    |   TLSv1.2:
    |     ciphers:
    |       TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (rsa 2048) - A
    |       TLS_DHE_RSA_WITH_AES_128_GCM_SHA256 (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_256_GCM_SHA384 (dh 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256 (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384 (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |       TLS_DHE_RSA_WITH_AES_128_CBC_SHA256 (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_128_CBC_SHA (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_256_CBC_SHA256 (dh 2048) - A
    |       TLS_DHE_RSA_WITH_AES_256_CBC_SHA (dh 2048) - A
    |       TLS_RSA_WITH_AES_128_GCM_SHA256 (rsa 2048) - A
    |       TLS_RSA_WITH_AES_256_GCM_SHA384 (rsa 2048) - A
    |       TLS_RSA_WITH_AES_128_CBC_SHA256 (rsa 2048) - A
    |       TLS_RSA_WITH_AES_256_CBC_SHA256 (rsa 2048) - A
    |       TLS_RSA_WITH_AES_128_CBC_SHA (rsa 2048) - A
    |       TLS_RSA_WITH_AES_256_CBC_SHA (rsa 2048) - A
    |     compressors:
    |       NULL
    |     cipher preference: server
    |_  least strength: A

    Nmap done: 1 IP address (1 host up) scanned in 27.90 seconds

See the [manual][nmap-ssl-enum-ciphers] for the meaning of the ratings, but **A** is good.

You can also use Nmap scripts to look for well-known ssl and tls vulnerabilities

* [ssl-ccs-injection][nmap-ssl-ccs-injection]: Connection setup bugs allowing for MITM attacks ([ccs-injection-vuln][ccs-injection-vuln], [ccs-injection-primer][ccs-injection-primer])
* [ssl-cert-intaddr][nmap-ssl-cert-intaddr]: Leaking of internal IP addresses
* [ssl-date][nmap-ssl-date]: Leaking of remote server time
* [ssl-dh-params][nmap-ssl-dh-params]: Use of weak [Diffie-Hellman][diffie-hellman] parameters
* [ssl-heartbleed][nmap-ssl-heartbleed]: Vulnerable to OpenSSL [Heartbleed][heartbleed]
* [ssl-known-key][nmap-ssl-known-key]: Server is using a known bad certificate
* [ssl-poodle][nmap-ssl-poodle]: Server allows vulnerable SSLv3 CBC ciphers ([POODLE][poodle])
* [sslv2][nmap-sslv2]: Server allows obsolete SSLv2 ciphers
* [sslv2-drown][nmap-sslv2-drown]: Server allows SSLv2 ciphers associated with [DROWN][drown] attacks

You can run all the ssl/tls tests at once using a wildcard

    $ nmap --script ssl* -p 443 jumpnowtek.com

Or you can comma separate the specific tests you want

    $ nmap --script ssl-cert,ssl-enum-ciphers -p 443 jumpnowtek.com

If you want to Nmap to check all potential ports that are running TLS services you can use the **-sV** option and Nmap will figure out which ports are appropriate to run the tests.

    $ nmap -sV --script -ssl-cert jumpnowtek.com



[owasp]: https://www.owasp.org/index.php/Main_Page
[owasp-tls-testing]: https://www.owasp.org/index.php/Testing_for_Weak_SSL/TLS_Ciphers,_Insufficient_Transport_Layer_Protection_(OTG-CRYPST-001)
[nmap]: https://nmap.org/
[nmap-ssl-cert]: https://nmap.org/nsedoc/scripts/ssl-cert.html
[nmap-ssl-enum-ciphers]: https://nmap.org/nsedoc/scripts/ssl-enum-ciphers.html
[nmap-ssl-ccs-injection]: https://nmap.org/nsedoc/scripts/ssl-ccs-injection.html
[nmap-ssl-cert-intaddr]: https://nmap.org/nsedoc/scripts/ssl-cert-intaddr.html
[nmap-ssl-date]: https://nmap.org/nsedoc/scripts/ssl-date.html
[nmap-ssl-dh-params]: https://nmap.org/nsedoc/scripts/ssl-dh-params.html
[nmap-ssl-heartbleed]: https://nmap.org/nsedoc/scripts/ssl-heartbleed.html
[nmap-ssl-known-key]: https://nmap.org/nsedoc/scripts/ssl-known-key.html
[nmap-ssl-poodle]: https://nmap.org/nsedoc/scripts/ssl-poodle.html
[nmap-sslv2]: https://nmap.org/nsedoc/scripts/sslv2.html
[nmap-sslv2-drown]: https://nmap.org/nsedoc/scripts/sslv2-drown.html
[diffie-hellman]: https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange
[poodle]: https://www.us-cert.gov/ncas/alerts/TA14-290A
[drown]: https://www.us-cert.gov/ncas/current-activity/2016/03/01/SSLv2-DROWN-Attack
[heartbleed]: https://www.us-cert.gov/ncas/alerts/TA14-098A
[ccs-injection-vuln]: http://ccsinjection.lepidum.co.jp/
[ccs-injection-primer]: https://www.tripwire.com/state-of-security/vulnerability-management/openssl-ccs-injection-primer/




