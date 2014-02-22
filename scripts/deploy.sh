#!/bin/bash

sudo /etc/init.d/nginx stop
sudo rm -r /var/www/*
sudo cp -r ../_site/* /var/www
sudo /etc/init.d/nginx start

