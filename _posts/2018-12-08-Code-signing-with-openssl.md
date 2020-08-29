---
layout: post
title: Signing code with OpenSSL
description: "Digital signing with OpenSSL"
date: 2020-08-29 10:35:00
categories: security
tags: [openssl, signing]
---

Providing a [cryptographic hash][crypto-hash] like an **md5** or **sha256** checksum for a file you distribute only gives the receiver **integrity** verification, proof that a file has not been corrupted or tampered with.

Including a [digital signature][digital-sig] adds **authentication** and **non-repuditation**.

[Public key cryptography][pub-key-crypto] is used to generate digital signatures.

In software development this is also called [code signing][code-signing].

The general algorithm:

**To Sign**

1. Generate a hash of the data file
2. Encrypt the hash with a private key producing a signature file
3. Distribute the data and signature files

**To Verify**

1. Generate a hash of the data file
2. Use the public key to unencrypt the signature file
3. Check that the two values match

Obviously the crypto hash algorithm has to be the same in both signing and verification.

So why not just sign the original file?

Public key cryptography is slow and the size of the file you can encrypt with an algorithm like RSA is limited. By hashing the data first and only **signing** the hash, we only need to encrypt a small file.

The [OpenSSL][openssl] command line utility provides all the tools we need to digitally sign files.

    $ openssl version
    OpenSSL 1.1.1f  31 Mar 2020

I am using **OpenSSL 1.1.1f** on an Ubuntu 20.04 machine for these examples.

### Create an elliptic-curve public/private key pair with genpkey

Generate a private key using one of the standard NIST curves **P-384**

    $ openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:P-384 -out ec-private.pem

And now a public key based on the private key

    $ openssl pkey -in ec-private.pem -pubout -out ec-public.pem

The key sizes are relatively small

    $ ls -l ec-*
    -rw------- 1 scott scott 306 Aug 29 09:50 ec-private.pem
    -rw-rw-r-- 1 scott scott 215 Aug 29 09:50 ec-public.pem


The private key **ec-private.pem** should be kept secret.

The public key **ec-public.pem** is meant to be shared.

### Signing

Openssl can do the signing, both hashing and encrypting, in one command.

Create a signature file like this

    $ openssl dgst -sign ec-private.pem -out data.sig data

The signature file is small 

    $ ls -l data*
    -rw-r--r-- 1 scott scott 415867 Aug 29 10:38 data
    -rw-rw-r-- 1 scott scott    103 Aug 29 10:40 data.sig

It should be distributed with the **data** file.

### Hash algorithm

The default hashing (digest) algorithm is **sha256**.

You can change this by adding another argument to the signing command.

For instance to use **sha3-512**

    $ openssl dgst -sha3-512 -sign ec-private.pem -out data.sig data

The available hash algorithms are 

    $ openssl list --digest-commands
    blake2b512        blake2s256        gost              md4               
    md5               rmd160            sha1              sha224            
    sha256            sha3-224          sha3-256          sha3-384          
    sha3-512          sha384            sha512            sha512-224        
    sha512-256        shake128          shake256          sm3         


### Verifying

Verification requires the public key and knowledge of the hashing algorithm that was used.

If the default **sha256** was used 

    $ openssl dgst -verify ec-public.pem -signature data.sig data
    Verified OK

A failure looks like this

    $ openssl dgst -verify ec-public.pem -signature data.sig modified-data
    Verification Failure


If a different hash algorithm was used, this needs to be specified or the check will fail. 

    $ openssl dgst -sha3-512 -sign ec-private.pem -out data.sig data

    $ openssl dgst -verify ec-public.pem -signature data.sig data
    Verification Failure

    $ openssl dgst -sha3-512 -verify ec-public.pem -signature data.sig data
    Verified OK

The shell variable **$?** is set to zero (success) or one (failure) as you would expect.

### Encrypting the Private Key

For additional protection of the private key, you can encrypt it with a password.

The extra **-aes256** argument will encrypt the private key using the [AES][aes] algorithm.

    $ openssl genpkey -aes256 -algorithm EC -pkeyopt ec_paramgen_curve:P-384 -out ec-private.pem
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:

Now whenever you use the private key, you will need the password

    $ openssl pkey -in ec-private.pem -pubout -out ec-public.pem
    Enter pass phrase for ec-private.pem:

    $ openssl dgst -sign ec-private.pem -out data.sig data
    Enter pass phrase for ec-private.pem:

The private key is slightly larger

    $ ls -l ec-*
    -rw------- 1 scott scott 464 Aug 29 10:59 ec-private.pem
    -rw-rw-r-- 1 scott scott 215 Aug 29 11:00 ec-public.pem

Prompting for pass phrase is the default, but you can provide the password using other methods with the **-passin** argument

Directly in the command

    $ openssl dgst -sign ec-private.pem -passin pass:the-password -out data.sig data

Using an environment variable

    $ SECRET=the-password
    $ openssl dgst -sign ec-private.pem -passin env:SECRET -out data.sig data

Using a **pathname** where the argument can be a file

    $ echo the-password > secret
    $ openssl dgst -sign private.pem -passin file:secret -out data.sig data

There are other options to provide the password. See the **Pass Phrase** section of the [openssl(1)][openssl-man] man page.

A password on the private key does not affect how the public key is used.

### Using RSA keys

RSA public key cryptography uses larger keys and is more CPU intensive, but can be used in a similar fashion.

Generating a 4096-bit RSA private key

    $ openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out rsa-private.pem
    ..........................................++++
    ...................................................++++

Generating a public key from the private key is the same

    $ openssl pkey -in rsa-private.pem -pubout -out rsa-public.pem

The keys are larger

    $ ls -l rsa*
    -rw------- 1 scott scott 3272 Aug 29 11:10 rsa-private.pem
    -rw-rw-r-- 1 scott scott  800 Aug 29 11:11 rsa-public.pem

Using the RSA keys for signing and verification are the same

    $ openssl dgst -sign rsa-private.pem -out data.sig data

    $ openssl dgst -verify rsa-public.pem -signature data.sig data

The signature is also larger with RSA keys

    $ ls -l data*
    -rw-r--r-- 1 scott scott 415867 Aug 29 10:38 data
    -rw-rw-r-- 1 scott scott    512 Aug 29 11:25 data.sig

The commands for using different hash algorithms and encrypting the private key are the same. 

### Base64 encoding the Signature File

The signature file is a binary file. If you want to look at signature files, for example with a web browser, you could [base64][base64] encode the file.

Openssl provides a utility.

    $ openssl base64 -in data.sig -out data.sig.b64

    $ file data.sig.b64
    data.b64: ASCII text

Before using for verification the signature file needs to be decoded into binary again.

    $ openssl base64 -d -in data.sig.b64 -out data.sig

You could also use the standard [base64(1)][base64-man] utility from the **coreutils** package for the encoding and decoding.

### Additional Reading

* [signify - sign and verify][tedu-signify]

* [signify: Securing OpenBSD From Us To You][bsdcan-signify]


[crypto-hash]: https://en.wikipedia.org/wiki/Cryptographic_hash_function
[digital-sig]: https://en.wikipedia.org/wiki/Digital_signature
[pub-key-crypto]: https://en.wikipedia.org/wiki/Public-key_cryptography
[openssl]: https://www.openssl.org/
[genrsa]: https://www.openssl.org/docs/manmaster/man1/genrsa.html
[aes]: https://en.wikipedia.org/wiki/Advanced_Encryption_Standard
[base64]: https://en.wikipedia.org/wiki/Base64
[base64-man]: https://linux.die.net/man/1/base64
[openssl-man]: https://linux.die.net/man/1/openssl
[code-signing]: https://en.wikipedia.org/wiki/Code_signing
[tedu-signify]: https://flak.tedunangst.com/post/signify
[bsdcan-signify]: http://www.openbsd.org/papers/bsdcan-signify.html
