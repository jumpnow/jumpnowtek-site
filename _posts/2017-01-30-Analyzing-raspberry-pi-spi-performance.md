---
layout: post
title: Analyzing SPI driver performance on the Raspberry Pi
date: 2017-02-15 15:40:00
categories: rpi
tags: [linux, rpi, spi, mcp3008, adc]
---

These are notes from some performance tests I was doing with a Raspberry Pi 3 and a SPI connected MCP3008 ADC.

The MCP3008 is an 8-channel, 10-bit ADC chip.

The MCP3008 does not do simultaneous reads, so for these tests I am only reading from one channel. Reading from multiple channels scales linearly as expected.

From the [datasheet][mcp3008-datasheet], the maximum SPI clock rate is 3.6 MHz when running at 5V which is what I'll be doing. If you power the device at 3.3V, you are limited to a clock rate of 1 MHz.

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

For use later

    1 transaction = 1 / 138.5k = ~7.2 us

There is also a measurable time between CS selection and the first SPI clock and again a delay between the last SPI clock and CS deselected.

I am measuring 1.6 us for the start and 0.4 us for the end so a total of 2.0 us.

So transactions are really 9.2 us.

There is system processing time between transactions, time when there is nothing happening on the SPI bus.

There are two parts to this which I'm giving names

1) **Context Switching Delay** between userland ioctl() calls

2) **Transaction Delay** between multiple reads in a single spidev transaction


**Context Switching Delay**

There is a delay between CS deselected from the last read to CS selection of the next read.

This the cost for making each spidev ioctl() call.

Here I am accounting for the context switching from userland to kernel, any copying of memory from user to kernel buffs, activation of the driver thread that does the actual work and any processing of the data by the user.

I eliminated the part that's fully under user control by not looking at the data returned.

For example, the transaction buffers are prepared once before the loop starts with setup code like this

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

And the read loop goes like this, never looking at the data  

    ...
    while (!abort_read) {
        if (ioctl(fd, SPI_IOC_MESSAGE(blocks), tr) < 0) {
            perror("ioctl");
            break;
        }

        count += blocks;
    }
    ...

(I did verify that the data is correct with another using another switch to this program. I just didn't use that during the timing tests.)

With that code running, the **Context Switching Delay** measured with a scope is around 5 us.

**Transaction Delay**.

The MCP3008 device requires a CS line transition to initiate a new conversion.

If you bunch multiple transactions into one batch sent to spidev, then you have to set the `cs_change` property to 1 or the CS line won't transition and the ADC won't run for the subsequent reads. You'll just get zeros for all but the first read.

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

**Transaction Delay** is ~10 us.

So now each transaction is going to take at least 

    9.2 + 10 = 19.2 us

And this brings the theoretical maximum sample rate for batched transactions down to 

    1 / 19.2 us = 52.1k transactions per second

Which is less then single transactions.

So for the different block sizes here is the estimated max transfer speed and the actual measured results when I run my code on the Raspbian system

blocks = 1

    1 transfer = 9.2 + 5 = 14.2 us
    theoretical transfer rate = 1 / 14.2 us = 70.4k
    measured transfer rate = 69.8k

blocks = 10 

    10 transfers = (19.2 * 9) + 9.2 + 5 = 187 us = 18.7 us per transfer
    theoretical transfer rate = 1 / 18.7 us = 53.5k
    measured transfer rate = 52.5k

blocks = 100

    100 transfers = (19.2 * 99) + 9.2 + 5 = 1915 us = 19.15 us per transfer
    theoretical transfer rate = 1 / 19.15 us = 52.22k
    measured transfer rate = 51.2k

blocks = 500

    500 transfers = (19.2 * 499) + 9.2 + 5 = 9595 us = 19.19 us per transfer
    theoretical transfer rate = 1 / 19.19 us = 52.11k
    measured transfer rate = 51.1k


From those results I'm pretty confident of my calculations.

The big, obvious optimization is to reduce that `cs_change` delay in the kernel spi driver so we can take advantage of batched transactions. 

Here is the original commit that added that 10 us delay

    commit 0b73aa63c193006c3d503d4903dd4792a26e1d50
    Author: Mark Brown <broonie@linaro.org>
    Date:   Sat Mar 29 23:48:07 2014 +0000

        spi: Fix handling of cs_change in core implementation
    
        The core implementation of cs_change didn't follow the documentation
        which says that cs_change in the middle of the transfer means to briefly
        deassert chip select, instead it followed buggy drivers which change the
        polarity of chip select.  Use a delay of 10us between deassert and
        reassert simply from pulling numbers out of a hat.

        Reported-by: Gerhard Sittig <gsi@denx.de>
        Signed-off-by: Mark Brown <broonie@linaro.org>

    diff --git a/drivers/spi/spi.c b/drivers/spi/spi.c
    --- a/drivers/spi/spi.c
    +++ b/drivers/spi/spi.c
    @@ -629,3 +628,4 @@
                            } else {
    -                               cur_cs = !cur_cs;
    -                               spi_set_cs(msg->spi, cur_cs);
    +                               spi_set_cs(msg->spi, false);
    +                               udelay(10);
    +                               spi_set_cs(msg->spi, true);


Definitely not a careful engineering decision on the choice of 10 us.

So I tried removed the delay entirely.

Because nothing happens immediately, the cs line still toggles for about 0.25 us which is more then the required 1 clock cycle the device requires, but that's much less then the 10 us from before.

This works fine running the MCP3008 at 3.6 MHz. I haven't tested, but running at 1 MHz a small delay might still be necessary. It just needs to be long enough for the MCP3008 to recognize it and it's easy to tell when it doesn't.

Here are the same observations and calculations using the patched spi driver on the [Buildroot system][buildroot-rpi].

blocks = 1 (expect no change)

    1 transfer = 9.2 + 5 = 14.2 us
    theoretical transfer rate = 1 / 14.2 us = 70.4k
    measured transfer rate = 69.6k

blocks = 10 

    10 transfers = (9.45 * 9) + 9.2 + 5 = 99.25 us = 9.925 us per transfer
    theoretical transfer rate = 1 / 9.925 us = 100.8k
    measured transfer rate = 98.3k

blocks = 100

    100 transfers = (9.45 * 99) + 9.2 + 5 = 949.75 us = 9.5 us per transfer
    theoretical transfer rate = 1 / 9.5 us = 105.3k
    measured transfer rate = 105.2k

blocks = 500

    500 transfers = (9.45 * 499) + 9.2 + 5 = 4279,75 us = 9.46 us per transfer
    theoretical transfer rate = 1 / 9.46 us = 105.7k
    measured transfer rate = 105.5k

That's a pretty good improvement for a one line change.

The test program I'm using is here [mcp3008-speedtest][mcp3008-speedtest]. It is only for testing system throughput.

The sweet spot seems to be around a block size of 100. Userland still gets data updates pretty quickly at roughly every 100 us.

I did uncover a problem with context switching times in my [Yocto built][yocto-rpi] RPi systems. The results are signicantly slower with blocks=1 where context switching times are most prominent, less so with higher block sizes.

The [Buildroot systems][buildroot-rpi] match the Raspbian system performance on blocks=1 tests. 

This is all just an exercise at this point.

On the only two projects I've worked on that use the MCP3008 ADC, we poll the device at roughly 10 Hz. Not much optimization is needed and we just use the [built-in kernel driver][using-mcp3008] for the MCP3008. It's a simpler solution.

For reference, here are the clock speeds for both the Raspbian and Buildroot systems as shown by 
**vcgencmd**


The Raspbian systems are running a 4.4.34 kernel. The systems are up to date with no optimizations selected.

These are the default clock settings from Raspbian

    pi@raspberrypi:~/mcp3008-speedtest $ vcgencmd get_config int
    arm_freq=1200
    audio_pwm_mode=1
    config_hdmi_boost=5
    core_freq=400
    desired_osc_freq=0x36ee80
    disable_commandline_tags=2
    disable_l2cache=1
    enable_uart=1
    force_eeprom_read=1
    force_pwm_open=1
    framebuffer_ignore_alpha=1
    framebuffer_swap=1
    gpu_freq=300
    hdmi_force_cec_address=65535
    init_uart_clock=0x2dc6c00
    lcd_framerate=60
    over_voltage_avs=0x1e848
    overscan_bottom=48
    overscan_left=48
    overscan_right=48
    overscan_top=48
    pause_burst_frames=1
    program_serial_random=1
    sdram_freq=450
    temp_limit=85

The [Buildroot][buildroot-rpi] systems are running a standard `4.4.45` kernel from the RPi kernel source on github.

These are the clock settings from the [Buildroot][buildroot-rpi] system where I did customize the default config.txt.

Note I had to add the **force_turbo=1**

    # vcgencmd get_config int
    arm_freq=1200
    audio_pwm_mode=1
    config_hdmi_boost=5
    core_freq=400
    desired_osc_freq=0x36ee80
    disable_commandline_tags=2
    disable_l2cache=1
    enable_uart=1
    force_eeprom_read=1
    force_pwm_open=1
    force_turbo=1
    framebuffer_ignore_alpha=1
    framebuffer_swap=1
    gpu_freq=300
    hdmi_force_cec_address=65535
    init_uart_clock=0x2dc6c00
    lcd_framerate=60
    over_voltage_avs=0x1e848
    over_voltage_avs_boost=0x1e848
    overscan_bottom=48
    overscan_left=48
    overscan_right=48
    overscan_top=48
    pause_burst_frames=1
    program_serial_random=1
    sdram_freq=450
    temp_limit=85


[mcp3008-datasheet]: https://cdn-shop.adafruit.com/datasheets/MCP3008.pdf
[using-mcp3008]: http://www.jumpnowtek.com/rpi/Using-mcp3008-ADCs-with-Raspberry-Pis.html
[buildroot-rpi]: http://www.jumpnowtek.com/
[yocto-rpi]: http://www.jumpnowtek.com/rpi/Raspberry-Pi-Systems-with-Yocto.html
[mcp3008-speedtest]: https://github.com/scottellis/mcp3008-speedtest