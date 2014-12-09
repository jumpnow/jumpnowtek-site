#!/bin/bash

cd ..
jekyll build
sudo /etc/init.d/nginx stop
sudo rm -rf /var/www/*
sudo cp -r _site/* /var/www
sudo /etc/init.d/nginx start
cd $OLDPWD  

