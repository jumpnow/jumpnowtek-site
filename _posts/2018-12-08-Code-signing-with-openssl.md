---
layout: post
title: Signing code with OpenSSL
description: "Digital signing with OpenSSL"
date: 2018-12-08 10:00:00
categories: security
tags: [openssl, signing]
---

Including a [cryptographic hash][crypto-hash] for a file you are distributing provides **integrity verification**, proof of no corruption.

In order to provide **authentication**, proof of authorship, we need a [digital signature][digital-sig].

A digital signature involves [public key cryptography][pub-key-crypto].

A digital signature provides **authentication**, **verification** and **non-repudiation**, though when signing code we are often not as interested in non-repudiation.

In software development, providing a digital signature is often called code signing.

The general algorithm is simple:

**To Sign**

1. Generate a hash of the file
2. Encrypt the hash with the private key producing a signature file

**To Verify**

1. Generate a hash of the file
2. Unencrypt the signature file with the public key
3. Compare the two

Obviously the crypto hash algorithm has to be the same in both signing and verification.

So why not just sign the original file? 

Public key cryptography is slow and doesn't work well on the large files. Hashing the data first means we only have to encrypt a small file of fixed size.

The [OpenSSL][openssl] command line tool makes the work of signing code fairly easy.

### Create a Public/Private Key Pair

Generate a private key with key size of 4096 bits.

    $ openssl genrsa -out private.pem 4096

Generate a public key from the private key.

    $ openssl rsa -in private.pem -pubout -out public.pem

The private key is a secret and should not be given out.

The public key is meant to be shared.

### Signing

Openssl can combine the hashing and encryption in one step.

This example uses **sha256** as the hashing (digest) algorithm. 

Assume the data file is some big binary blob.

    $ openssl dgst -sha256 -sign private.pem -out data.sig data

### Verifying

Verification requires the public key and knowledge of the hashing algorithm that was used.

    $ openssl dgst -sha256 -verify public.pem -signature data.sig data
    Verified OK

A failure looks like this

    $ openssl dgst -sha256 -verify public.pem -signature data.sig modified-data
    Verification Failure

[crypto-hash]: https://en.wikipedia.org/wiki/Cryptographic_hash_function
[digital-sig]: https://en.wikipedia.org/wiki/Digital_signature
[pub-key-crypto]: https://en.wikipedia.org/wiki/Public-key_cryptography
[openssl]: https://www.openssl.org/ 