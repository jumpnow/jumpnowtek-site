---
layout: post
title: Signing code with OpenSSL
description: "Digital signing with OpenSSL"
date: 2019-09-29 17:04:00
categories: security
tags: [openssl, signing]
---

Including a [cryptographic hash][crypto-hash] like an **md5** or **sha256** checksum for a file you distribute provides **integrity** verification, proof the file is not corrupt.

In order to provide **authentication**, to prove the file came from you, requires a [digital signature][digital-sig].

Using [public key cryptography][pub-key-crypto] a digital signature can give us **authentication**, **integrity** and **non-repudiation**.

In software development this is called [code signing][code-signing].

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

Public key cryptography is slow and the size of the file you can encrypt with an algorithm like RSA is limited. By hashing the data first, we only need to encrypt a small file.

The [OpenSSL][openssl] command line utility provides all the tools we need to digitally sign files.

    $ openssl version
    OpenSSL 1.1.1b  26 Feb 2019

I am using **OpenSSL 1.1.1b** on an Ubuntu 19.04 machine for these examples.

### Create an RSA public/private key pair with genrsa

Generate a private key with key size of 4096 bits.

    $ openssl genrsa -out private.pem 4096
    Generating RSA private key, 4096 bit long modulus (2 primes)
    ...++++
    ..............................++++
    e is 65537 (0x010001)

Generate a public key from the private key.

    $ openssl rsa -in private.pem -pubout -out public.pem
    writing RSA key

The files

    $ ls -l
    total 8
    -rw------- 1 scott scott 3243 Sep 28 10:41 private.pem
    -rw-r--r-- 1 scott scott  800 Sep 28 10:42 public.pem

The private key **private.pem** should be kept secret.

The public key **public.pem** is meant to be shared.

### Signing

Openssl can do the signing in a single command, combining the hashing and encryption in one step.

This example uses **sha512** as the hashing (digest) algorithm. 

Assume the **data** file is some big binary blob, for example a compressed tarball.

This command creates the signature file (**data.sig** in this example).

    $ openssl dgst -sha512 -sign private.pem -out data.sig data

The signature file **data.sig** is not big. 

    $ ls -l data*
    -rw-r--r-- 1 scott scott 155385 Sep 28 10:45 data
    -rw-r--r-- 1 scott scott    512 Sep 28 10:45 data.sig

**data.sig** should be distributed with the **data** file.

### Verifying

Verification requires the public key and knowledge of the hashing algorithm that was used.

    $ openssl dgst -sha512 -verify public.pem -signature data.sig data
    Verified OK

A failure looks like this

    $ openssl dgst -sha512 -verify public.pem -signature data.sig modified-data
    Verification Failure


If shell scripting the verification, the **$?** variable is set to zero on (success) or one on (failure) as you would expect.

### Encrypting the Private Key

For additional protection of the private key, you can encrypt it with a password.

The extra **-aes256** argument will encrypt the private key using the [AES][aes] algorithm.

    $ openssl genrsa -aes256 -out private.pem 4096
    Generating RSA private key, 4096 bit long modulus (2 primes)
    ..++++
    ..............++++
    e is 65537 (0x010001)
    Enter pass phrase for private.pem:
    Verifying - Enter pass phrase for private.pem:

See the help for encryption algorithm options [genrsa(1)][genrsa]
 
Now whenever you use the private key, you will need the password

    $ openssl rsa -in private.pem -pubout -out public.pem
    Enter pass phrase for private.pem:
    writing RSA key

    $ openssl dgst -sha512 -sign private.pem -out data.sig data
    Enter pass phrase for private.pem:

Prompting for pass phrase is the default, but you can provide the password using other methods with the **-passin** argument

Directly in the command

    $ openssl dgst -sha512 -sign private.pem -passin pass:the-password -out data.sig data

Using an environment variable

    $ SECRET=the-password
    $ openssl dgst -sha512 -sign private.pem -passin env:SECRET -out data.sig data

Using a **pathname** where the argument can be a file 

    $ echo the-password > secret 
    $ openssl dgst -sha512 -sign private.pem -passin file:secret -out data.sig data

There are other options to provide the password. See the **Pass Phrase** section of the [openssl(1)][openssl-man] man page.


A password on the private key does not affect how the public key is used.

### Using elliptic curve keys

Elliptic curve (EC) keys are an alternative to RSA keys.

The keys are smaller and operations are less CPU intensive, often important for embedded systems.

The following command will generate a private key

    $ openssl genpkey -algorithm EC \
        -pkeyopt ec_paramgen_curve:P-256 \
        -pkeyopt ec_param_enc:named_curve \
        -out private.pem

And this will generate a public key from the private key

    $ openssl pkey -pubout -inform pem -outform pem -in private.pem -out public.pem


Here you can see the keys are smaller than RSA keys 

    $ ls -l *.pem
    -rw------- 1 scott scott 241 Sep 29 06:56 private.pem
    -rw-r--r-- 1 scott scott 178 Sep 29 06:56 public.pem


Signing operations using openssl are the same.

This creates a signature for a **data** file using the private key

    $ openssl dgst -sha512 -sign private.pem -out data.sig data

Here is a check of the signature using the public key

    $ openssl dgst -sha512 -verify public.pem -signature data.sig data
    Verified OK

And this shows a failed check

    $ openssl dgst -sha512 -verify public.pem -signature data.sig modified-data
    Verification Failure


As with RSA keys you can have openssl password protect the private key (here **-aes256**)

    $ openssl genpkey -aes256 -algorithm EC \
        -pkeyopt ec_paramgen_curve:P-256 
        -pkeyopt ec_param_enc:named_curve \
        -out private.pem
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:

And now whenever you use the private key you will have to provide the password

    $ openssl pkey -pubout -inform pem -outform pem -in private.pem -out public.pem
    Enter pass phrase for private.pem:

    $ openssl dgst -sha512 -sign private.pem -out data.sig data
    Enter pass phrase for private.pem:


Operations using the public key are unchanged.

### Base64 encoding the Signature File

The signature file is a binary file. If you want to look at signature files, for example with a web browser, you could [base64][base64] encode the file. 

Openssl provides a utility.

    $ openssl base64 -in data.sig -out data.sig.b64

    $ file data.sig.b64
    data.b64: ASCII text

Before using for verification the signature file needs to be decoded into binary again.

    $ openssl base64 -d -in data.sig.b64 -out data.sig

You could also use the standard [base64(1)][base64-man] utility from the **coreutils** package for the encoding and decoding. 

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
