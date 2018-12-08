---
layout: post
title: Speeding up initialization of the Linux RNG
description: "Updating the entropy count when seeding the Linux random number generator"
date: 2018-12-08 18:12:00
categories: linux
tags: [linux, embedded, random, urandom, entropy, rng, seeding]
---

Linux systems can seed the random number system at startup with a previously generated seed-file.

Something like this

    *      echo "Initializing random number generator..."
    *      random_seed=/var/run/random-seed
    *      # Carry a random seed from start-up to start-up
    *      # Load and then save the whole entropy pool
    *      if [ -f $random_seed ]; then
    *              cat $random_seed >/dev/urandom
    *      else
    *              touch $random_seed
    *      fi
    *      chmod 600 $random_seed
    *      dd if=/dev/urandom of=$random_seed count=1 bs=512

On shutdown code like the following is run again

    *      # Carry a random seed from shut-down to start-up
    *      # Save the whole entropy pool
    *      echo "Saving random seed..."
    *      random_seed=/var/run/random-seed
    *      touch $random_seed
    *      chmod 600 $random_seed
    *      dd if=/dev/urandom of=$random_seed count=1 bs=512

Those excerpts come right out of the kernel source: [drivers/char/random.c][random_c]

Or the man page for urandom: [man urandom][urandom-man].

Unfortunately, just writing to **/dev/urandom** like this does not tell Linux how much new entropy was added and so the system still waits for entropy to be added from other sources before coming up fully.

On workstations or servers with lots of entropy sources or if you have a hardware RNG this is not a big deal and the system gets its entropy pretty quickly from other sources.

But on entropy starved embedded systems without a hardware RNG, this can massively delay startup of processes like web servers using SSL/TLS, sometimes by several minutes.

There is an API for updating the entropy count when seeding the random system.

There are two ioctls for **/dev/urandom** to do this

* RNDADDENTROPY

* RNDADDTOENTCNT

The RNDADDTOENTROPY ioctl uses a struct object to update both the entropy count and the seed data at the same time.

The RNDADDTOENTCNT ioctl just updates the entropy count.

If we trust the random-seed file that we generated on the last shutdown, we may as well use it.

To minimize changes to existing systems, I am calling RNDADDTOENTCNT ioctl right after the existing startup script loads the seed file.

Here is some code: [rndaddtoentcnt][rndaddtoentcnt]

I modified the existing **/etc/init.d/urandom** startup script like this

    ...
        date +%s.%N > /dev/urandom

        if [ -f "$RANDOM_SEED_FILE" ]; then
            cat "$RANDOM_SEED_FILE" > /dev/urandom

    +       if [ -x /usr/bin/rndaddtoentcnt ]; then
    +           /usr/bin/rndaddtoentcnt 1024
    +       fi
        fi
   ...

Being overly conservative I am claiming only 1024 bits of new entropy even though we added 4096 (512 bytes * 8). 

This is still enough to reduce the startup time for a Python flask web app running on a BeagleBone Black from 155 seconds to 25 seconds. 

Here is an [lkml.org thread][lkml-thread] discussing the issue.


[random_c]: https://elixir.bootlin.com/linux/latest/source/drivers/char/random.c
[rndaddtoentcnt]: https://github.com/jumpnow/rndaddtoentcnt
[lkml-thread]: https://lkml.org/lkml/2018/10/30/172
[urandom-man]: http://man7.org/linux/man-pages/man4/random.4.html