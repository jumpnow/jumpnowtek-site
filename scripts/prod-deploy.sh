#!/bin/bash

sudo systemctl stop nginx
sudo rm -rf /var/www/*
sudo tar -C /var/www --strip 1 -xzf site.tgz
sudo chown -R www-data:www-data /var/www
sudo systemctl start nginx
