---
layout: post
title: Adding some security to your MQTT project
date: 2017-05-03 15:28:00
categories: iot
tags: [iot, mqtt, openssl, rpi]
---

# Generate a CA root certificate

This CA root certificate will get installed on every client. Clients will trust certificates from brokers that are signed by this CA.

### Generate a CA signing key

    openssl genrsa -out ca.key 2048

Example

    scott@fractal:~/mqtt/ssl$ openssl genrsa -out ca.key 2048
    Generating RSA private key, 2048 bit long modulus
    ............................+++
    ...........................................................................................+++
    e is 65537 (0x10001)

    scott@fractal:~/mqtt/ssl$ ls -l
    total 4
    -rw-rw-r-- 1 scott scott 1679 May  3 11:48 ca.key


### Generate the CA certficate signed with the CA key

    openssl req -new -x509 -days 180 -key ca.key -out ca.crt

Example

    scott@fractal:~/mqtt/ssl$ openssl req -new -x509 -days 180 -key ca.key -out ca.crt
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:ME
    Locality Name (eg, city) []:
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:Jumpnow Technologies,  LLC
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:
    Email Address []:


    scott@fractal:~/mqtt/ssl$ ls -l
    total 8
    -rw-rw-r-- 1 scott scott 1208 May  3 12:02 ca.crt
    -rw-rw-r-- 1 scott scott 1679 May  3 11:48 ca.key


# Generate a certificate for the MQTT broker

This is the certificate the MQTT broker will present to clients.

It will be used to authenticate the broker and enable ssl encrypted communication between the broker and clients.

### Generate a signing key for the broker

    openssl genrsa -out broker.key 2048

Example

    scott@fractal:~/mqtt/ssl$ openssl genrsa -out broker.key 2048
    Generating RSA private key, 2048 bit long modulus
    .............+++
    .....+++
    e is 65537 (0x10001)


    scott@fractal:~/mqtt/ssl$ ls -l
    total 12
    -rw-rw-r-- 1 scott scott 1675 May  3 12:04 broker.key
    -rw-rw-r-- 1 scott scott 1208 May  3 12:02 ca.crt
    -rw-rw-r-- 1 scott scott 1679 May  3 11:48 ca.key


### Generate a certificate request for the broker

    openssl req -new -out broker.csr -key broker.key

Example

    scott@fractal:~/mqtt/ssl$ openssl req -new -out broker.csr -key broker.key
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [AU]:US
    State or Province Name (full name) [Some-State]:ME
    Locality Name (eg, city) []:
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:Jumpnow Technologies, LLC
    Organizational Unit Name (eg, section) []:
    Common Name (e.g. server FQDN or YOUR name) []:mqtt-broker
    Email Address []:

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:


    scott@fractal:~/mqtt/ssl$ ls -l
    total 16
    -rw-rw-r-- 1 scott scott  976 May  3 12:07 broker.csr
    -rw-rw-r-- 1 scott scott 1675 May  3 12:04 broker.key
    -rw-rw-r-- 1 scott scott 1208 May  3 12:02 ca.crt
    -rw-rw-r-- 1 scott scott 1679 May  3 11:48 ca.key


### Sign the broker certificate with the CA key

    openssl x509 -req -in broker.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out broker.crt -days 180

Example

    scott@fractal:~/mqtt/ssl$ openssl x509 -req -CA ca.crt -CAkey ca.key -CAcreateserial -in broker.csr -out broker.crt -days 180
    Signature ok
    subject=/C=US/ST=ME/O=Jumpnow Technologies, LLC/CN=mqtt-broker
    Getting CA Private Key


    scott@fractal:~/mqtt/ssl$ ls -l
    total 24
    -rw-rw-r-- 1 scott scott 1119 May  3 13:10 broker.crt
    -rw-rw-r-- 1 scott scott  976 May  3 13:08 broker.csr
    -rw-rw-r-- 1 scott scott 1675 May  3 13:08 broker.key
    -rw-rw-r-- 1 scott scott 1208 May  3 12:02 ca.crt
    -rw-rw-r-- 1 scott scott 1679 May  3 11:48 ca.key
    -rw-rw-r-- 1 scott scott   17 May  3 13:10 ca.srl


# Enabling 

I'm using some Yocto built Raspberry Pi systems for this test. 

That's not too important.

What matters is that I have mosquitto and the python paho-mqtt packages installed.

Only the RPi running the broker needs mosquitto, but I'm using the same iot-image for both.


### MQTT broker setup

