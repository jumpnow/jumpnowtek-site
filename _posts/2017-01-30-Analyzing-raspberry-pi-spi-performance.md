---
layout: post
title: Analyzing SPI driver performance on the Raspberry Pi
date: 2017-01-30 05:46:00
categories: rpi
tags: [linux, rpi, spi, mcp3008, adc]
---

These are notes from some performance tests I was doing with the Raspberry PI and a SPI connected ADC.

I was using a Raspberry Pi 3 board running a standard `4.4.45` kernel from the RPi kernel source on github.

The target device for these experiments is an MCP3008 8-channel, 10-bit ADC.

The MCP3008 does not do simultaneous reads, so I am only reading from one channel for the tests.

From the [datasheet][mcp3008-datasheet], the maximum SPI clock rate is 3.6 MHz when running at 5v which is what I'll be doing.

The device requires 18 clocks per data sample 8 clocks for addressing and setup and 10 clocks for the data.

This gives us the maximum theoretical sample rate from the datasheet 

    3.6 MHz / 18 = 200k samples per second


But that's not realistic in practice using a Raspberry Pi running Linux.

The RPi SPI driver only works on 8 bit bytes.

From `drivers/spi/spi-bcm2835.c`

    719         master->mode_bits = BCM2835_SPI_MODE_BITS;
    720         master->bits_per_word_mask = SPI_BPW_MASK(8);
    721         master->num_chipselect = 3;

That means the minimum clocks for a read of the device is going to be 24 not 18.

This brings theoretical maximum down to

    3.6 MHz / 24 = 150k samples per second

There is a fixed one clock delay between bytes in the RPi SPI driver.

It's noted here in `drivers/spi/spi-bcm2835.c`

    576         /* calculate the estimated time in us the transfer runs */
    577         xfer_time_us = (unsigned long long)tfr->len
    578                 * 9 /* clocks/byte - SPI-HW waits 1 clock after each byte */
    579                 * 1000000;
    580         do_div(xfer_time_us, spi_used_hz);

And it's obvious when you view the transactions with an oscilloscope.

I'm not sure if this applies to the last byte in a transfer, so not sure if I should adjust by 26 or 27, but I'll go with the lower.

This is the new theoretical maximum sample rate

    3.6 MHz / 26 = 138.5K samples per second

And for use later

    1 transaction = 1 / 138.5k = ~7.2 us


There is system processing time between transactions, time when there is nothing happening on the SPI bus.

There are two parts to this which I'm giving names

1) **Transaction Delay** between multiple reads in a single spidev transaction

2) **Context Switching Delay** between userland ioctl() calls


Starting with the **Transaction Delay**.

The MCP3008 device requires a CS line transition to initiate a new conversion.

If you bunch multiple transactions into one batch sent to spidev, then you have to set the `cs_change` property to 1 or the CS line won't transition and the ADC won't run for the subsequent reads. You'll just get zeros.

With the default SPI driver that CS line toggling costs at least 10 us for each toggle, because of this code in the kernel `spi.c`

    diff --git a/drivers/spi/spi.c b/drivers/spi/spi.c
    index dee1cb8..6e40f2e 100644
    --- a/drivers/spi/spi.c
    +++ b/drivers/spi/spi.c
    @@ -989,7 +989,6 @@ static int spi_transfer_one_message(struct spi_master *master,
                                    keep_cs = true;
                            } else {
                                    spi_set_cs(msg->spi, false);
    -                               udelay(10);
                                    spi_set_cs(msg->spi, true);
                            }
                    }


The removal of that **udelay(10)** is my optimization explained later.

The CS line is toggled high between transactions for ~10us as you would expect, but there is an additional ~3us delay between the last clock of the current transaction and the first clock of the next. This looks like it is setup time in the RPi spi driver and I haven't looked into that yet.

**Transaction Delay** is ~13 us.

So now each transaction is going to take at least 

    7.2 + 13 = 20.2 us

And this brings the theoretical maximum sample rate down to 

    1 / 20.2 us = 49.5k transactions per second

**Context Switching Delay**

SPI transactions are limited in size and we have to get the data back to the user program at some point.

So now we have to account for the delay going from userland to the kernel and back. 

This delay probably comes from several sources, but I think these are the main ones

* The tx and rx buffers from the userland code have to be copied to/from kernel buffers.

* There is the general context switching penalty and getting a kernel thread to run the actual transaction.

In the userland code, I'm running a pretty tight loop.

The transaction buffers are prepared once before the loop starts and I'm not even looking at the returned data.

Here is the relevant setup code

    ...
    for (i = 0; i < blocks; i++) {
        tx[i*4] = 0x60 | (ch << 2);
        tr[i].tx_buf = (unsigned long) &tx[i * 4];
        tr[i].rx_buf = (unsigned long) &rx[i * 4];
        tr[i].len = 3;
        tr[i].speed_hz = 5760000;
        tr[i].cs_change = 1;
    }

    // unset cs_change for last transfer in block or we lose
    // the first read of the next block
    tr[blocks-1].cs_change = 0;
    ...

And the read loop   

    ...
    while (!abort_read) {
        if (ioctl(fd, SPI_IOC_MESSAGE(blocks), tr) < 0) {
            perror("ioctl");
            break;
        }

        count += blocks;
    }
    ...

There is not a lot to optimize in that loop.

With that code running, the **Context Switching Delay** measured with a scope varies depending on the block size.

Here's what I see

    blocks=1  delay is ~13 us

    blocks=10 delay is ~25us.

    blocks=100 delay is ~72us

    blocks=500 delay is ~280us


So for the different block sizes here is the estimated max transfer speed and the actual measured results when I run my code

blocks = 1

    1 transfer = 7.2 + 13 = 20.2 us
    theoretical transfer rate = 1 / 20.2 us = 49.5k
    measured transfer rate = 48.0k

blocks = 10 

    10 transfers = (10 * 20.2) + 25 = 227 us = 22.7 us per transfer
    theoretical transfer rate = 1 / 23.2 us = 44.05k
    measured transfer rate = 45.1k

blocks = 100

    100 transfers = (100 * 20.2) + 72 = 2092 us = 20.92 us per transfer
    theoretical transfer rate = 1 / 20.92 us = 47.80k
    measured transfer rate = 46.3k

blocks = 500

    500 transfers = (500 * 20.2) + 280 = 10380 us = 20.76 us per transfer
    theoretical transfer rate = 1 / 20.76 us = 48.17k samples per second
    measured transfer rate = 46.29k


From those results I'm pretty confident of my calculations.

The big, obvious optimization is to reduce that `cs_change` delay in the kernel spi driver. As the patch above showed, I removed the delay entirely.

Because nothing happens immediately, the cs line still toggles for about 0.5 us which is far more then the required 1 clock cycle the device requires.

With that change the delay between reads goes from 13 us to ~3.6 us.

Now each transaction is 

    7.2 + 3.6 = 10.8 us

Here are the same observations and calculations using the patched spi driver.

blocks = 1, no change expected

    1 transfer = 7.2 + 13 = 20.2 us
    theoretical transfer rate = 1 / 20.2 us = ~49.5k samples per second
    measured transfer rate = 48.0k

blocks = 10

    10 transfers = (10 * 10.8) + 25 = 133 us = 13.3 us per transfer
    theoretical transfer rate = 1 / 13.3 us = 75.19k
    measured transfer rate = 74.0k

blocks = 100

    100 transfers = (100 * 10.8) + 72 = 1152 us = 11.52 us per transfer
    theoretical transfer rate = 1 / 11.52 us = 86.81k
    measured transfer rate = 86.1k

blocks = 500

    500 transfers = (500 * 10.8) + 280 = 5680 us = 11.36 us per transfer
    theoretical transfer rate = 1 / 11.36 us = 88.03k
    measured transfer rate = 87.1k

That's a pretty good improvement for one small change.

The sweet spot seems to be around block sizes of 100. Userland still gets data updates pretty quickly.

If I had a project that actually needed this I would start digging deeper into the ~3 us delay between transactions in the RPi SPI driver and then maybe look into replacing spidev with a custom kernel driver optimized for this use case.

On the only two projects I've worked on that use the MCP3008 ADC, we poll the device at roughly 10 Hz.

Not much optimization is needed and instead of spidev we just use the [built-in kernel driver][using-mcp3008] for the MCP3008, a simpler solution.

But maybe this helps someone else with their project.

[mcp3008-datasheet]: https://cdn-shop.adafruit.com/datasheets/MCP3008.pdf
[using-mcp3008]: http://www.jumpnowtek.com/rpi/Using-mcp3008-ADCs-with-Raspberry-Pis.html