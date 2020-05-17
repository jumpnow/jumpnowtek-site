#!/bin/bash

sudo systemctl stop nginx
sudo chmod 755 /var/www
sudo rm -rf /var/www/*
sudo tar -C /var/www --strip 1 -xzf site.tgz
sudo chown -R www-data:www-data /var/www
sudo find /var/www -type d -print -exec chmod 555 {} \;
sudo find /var/www -type f -print -exec chmod 444 {} \;
sudo chmod 555 /var/www
sudo systemctl start nginx
