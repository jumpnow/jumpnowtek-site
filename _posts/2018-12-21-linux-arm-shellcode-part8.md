---
layout: post
title: Linux ARM Shellcode - Part 8 - Exploiting the Stack
description: "Linux ARM Shellcode"
date: 2018-12-19 12:12:00
categories: shellcode
tags: [linux, arm, shellcode, assembly]
---

The last example had a small stack, too small to fit our shellcode, so we will look at an example with a slightly larger stack.

	#include <stdio.h>
	#include <string.h>

	int main(int argc, char **argv)
	{
		int a, b;
		char buff[32];

		a = 3;
		b = 5;

		if (argc > 1)
			strcpy(buff, argv[1]);

		printf("%08X %08X\n", a, b);

		return 0;
	}

From the previous post, we might guess that the stack of this new program is going to look like this

           ADDRESS   
          0xffffffff
          ...
          ...        
    fp => 0x????????   [fp]       lr, return location
          0x????????   [fp, #-4]  caller's fp
          0x????????   [fp, #-8]  int a
          0x????????   [fp, #-12] int b
		  0x????????   [fp, #-16] char buff[28-31]
		  0x????????   [fp, #-20] char buff[24-27]
		  0x????????   [fp, #-24] char buff[20-23]
		  0x????????   [fp, #-28] char buff[16-19]
		  0x????????   [fp, #-32] char buff[12-15]
		  0x????????   [fp, #-36] char buff[8-11]
          0x????????   [fp, #-40] char buff[4-7]
          0x????????   [fp, #-44] char buff[0-3]
          0x????????   [fp, #-48] argc
    sp => 0x????????   [fp, #-52] argv, *0xbefffd24 = argv[0], *0xbefffd28 = argv[1]
          ...   
          0x00000000

Let's see if some tests validate this.

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGG
	00000003 00000005

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHH
	00000003 00000000

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIII
	00000000 49494949

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJ
	4A4A4A4A 49494949

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJKKKK
	4A4A4A4A 49494949

	$ ./main AAAABBBBCCCCDDDDEEEEFFFFGGGGHHHHIIIIJJJJKKKKLLLL
	4A4A4A4A 49494949
	Segmentation fault

Okay, as expected.
		  
We know that whatever sits in **[$fp]** will get treated as **lr** and get popped into **pc** at the end of **main()** and executed.

And we know that we can control this value by overwriting the stack variable **buff**.

### Summarizing

Because we can control **lr** on the stack, we have control of the next instruction that will execute when the function whose stack we corrupted returns.
In this case the function happens to be **main()**, but that is not important.

The strategy.

The memory we have control of is the stack and so that is where we will be loading our shellcode.

At the same time we will need to set **lr** to point to the start of our shellcode.

... in work ...

	(gdb) x/14x $sp
	0xbefffb80:     0xbefffd04      0x00000002      0xb6fcd130      0xb6fca000
	0xbefffb90:     0xb6fcbb84      0x00400640      0x00400620      0x00000000
	0xbefffba0:     0x0040042c      0x00000000      0x00000005      0x00000003
	0xbefffbb0:     0x00000000      0xb6ea3700


	Breakpoint 3, 0x004005f4 in main ()
	(gdb) x/14x $sp
	0xbefffb80:     0xbefffd04      0x00000002      0x41414141      0x42424242
	0xbefffb90:     0x43434343      0x44444444      0x45454545      0x46464646
	0xbefffba0:     0x47474747      0x48484848      0x49494949      0x4a4a4a4a
	0xbefffbb0:     0x4b4b4b4b      0x4c4c4c4c



