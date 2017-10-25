---
layout: post
title: Using MQTT and the Raspberry Pi for an IOT project
date: 2017-05-03 15:28:00
categories: iot
tags: [iot, mqtt, rpi]
---

The Raspberry Pis make a great platform for experimenting with [MQTT][mqtt] to build an IOT project.

I am using [Yocto built systems][rpi-yocto] on the RPis for this example, in particular the [iot-image here][iot-image].

The packages of interest are mosquitto and python paho-mqtt.



  
[mqtt]: http://mqtt.org/
[rpi-yocto]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[iot-image]: https://github.com/jumpnow/meta-rpi/blob/morty/images/iot-image.bb
[mosquitto]:
[paho-mqtt]: 