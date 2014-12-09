---
layout: post
title: Website Setup
description: "Configure and deploy jumpnowtek on an Ubuntu server"
date: 2014-01-01 00:01:00
categories: miscellaneous 
tags: [linux, ubuntu, jekyll]
---

Notes for me ;-)

Install the following Ubuntu packages

    scott@host:~$ sudo apt-get install build-essential git nginx ruby2.0 ruby2.0-dev

Install jekyll

    scott@host:~$ sudo gem install jekyll

Clone the website

    scott@host:~$ clone git://github.com/jumpnow/jumpnowtek-site

Optional build the site (the deploy script below will also do a build)

    scott@host:~$ cd jumpnowtek-site
    scott@host:~/jumpnowtek-site$ jekyll build

Setup nginx

    scott@host:~/jumpnowtek-site$ sudo cp nginx/jumpnowtek /etc/nginx/sites-available
    scott@host:~/jumpnowtek-site$ cd /etc/nginx/sites-enabled
    scott@host:/etc/nginx/sites-enabled$ sudo ln -s ../sites-available/jumpnowtek jumpnowtek
    scott@host:/etc/nginx/sites-enabled$ cd ~/jumpnowtek-site

Restart nginx

    scott@host:~/jumpnowtek-site$ sudo /etc/init.d/nginx restart

Deploy the site

    scott@host:~/jumpnowtek-site$ cd scripts
    scott@host:~/jumpnowtek-site/scripts$ ./deploy.sh


