---
title: Decreasing Elf Size
subtitle: max-page-size
date: 2018-10-04
tags: ["gcc", "arm", "embedded"]
---
Recently I had a problem of reducing the size of an ARM executable that was being loaded onto a embedded platform with only 640K of flash storage.  I ran into an issue where the executable was much larger than it should have been.

For this post I'll create an example empty c file to demonstrate what is happening.

```c
// main.c
int main() {};
```

I'll go ahead and compile the simple program using the arm cross compile.  I must specify the specs because otherwise the newlib library expects an processor specific implementation of the _exit() function.  I'll also strip the executable to remove extra debugging information from the executable.

```sh
# Compile the simple main.c file
arm-none-eabi-gcc --specs=nosys.specs main.c -o executable

# Get the size of the executable.
ls -lh executable 
-rwxr-xr-x 1 jhamberg jhamberg 59K Oct  3 21:43 executable*

# Strip the ELF file.
arm-none-eabi-strip executable

# Get the size of the stripped executable.
ls -lh executable 
-rwxr-xr-x 1 jhamberg jhamberg 36K Oct  3 21:44 executable*

```

Right off the bat 36K for the stripped executable seems very large for a program that only returns zero from the main function.  There is a fair amount of overhead in the ELF file format to be expected, but not 36KB in overhead.  I'll go ahead and use the handy program called [bloaty](https://github.com/google/bloaty) that is provided by Google on GitHub to help diagnose what is going on.  This tool is used to view the file and memory sizes of ELF executable files.

```sh
bloaty executable
     VM SIZE                       FILE SIZE
 --------------                 --------------
  91.4%  31.9Ki [LOAD [RX]]      31.9Ki  89.5%
   4.8%  1.67Ki .text            1.67Ki   4.7%
   3.0%  1.05Ki .data            1.05Ki   3.0%
   0.4%     148 [ELF Headers]       748   2.1%
   0.0%       0 .shstrtab           123   0.3%
   0.0%       0 .ARM.attributes      44   0.1%
   0.0%       0 .comment             43   0.1%
   0.1%      28 .bss                  0   0.0%
   0.1%      24 .fini                24   0.1%
   0.1%      24 .init                24   0.1%
   0.0%       8 .ARM.exidx            8   0.0%
   0.0%       8 .init_array           8   0.0%
   0.0%       8 .rodata               8   0.0%
   0.0%       4 .eh_frame             4   0.0%
   0.0%       4 .fini_array           4   0.0%
   0.0%       4 .jcr                  4   0.0%
   0.0%       4 [LOAD [RW]]           4   0.0%
   0.0%       0 [Unmapped]            2   0.0%
 100.0%  34.8Ki TOTAL            35.6Ki 100.0%
```

Here you can see what sections are taking the most amount of space in the ELF executable.  Bloaty also shows a comparison of what takes up memory in the file and what takes up memory in the memory space of the application.  For example the .bss section will take very little space in the executable file, but a large amount of space in the executable memory.

We can see that there is this [LOAD [RX]] section that is taking 31.9Ki of space in the executable.  It doesn't seem to corrispond to anything in particular.  Lets use the arm-none-eabi-readelf program to see if we can find any extra information about the executable.

```sh
# Read the section headers from the ELF executable.
arm-none-eabi-readelf -S executable
There are 15 section headers, starting at offset 0x8c14:

Section Headers:
  [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
  [ 0]                   NULL            00000000 000000 000000 00      0   0  0
  [ 1] .init             PROGBITS        00008000 008000 000018 00  AX  0   0  4
  [ 2] .text             PROGBITS        00008018 008018 0006b0 00  AX  0   0  4
  [ 3] .fini             PROGBITS        000086c8 0086c8 000018 00  AX  0   0  4
  [ 4] .rodata           PROGBITS        000086e0 0086e0 000008 00   A  0   0  4
  [ 5] .ARM.exidx        ARM_EXIDX       000086e8 0086e8 000008 00  AL  2   0  4
  [ 6] .eh_frame         PROGBITS        000086f0 0086f0 000004 00   A  0   0  4
  [ 7] .init_array       INIT_ARRAY      000186f4 0086f4 000008 04  WA  0   0  4
  [ 8] .fini_array       FINI_ARRAY      000186fc 0086fc 000004 04  WA  0   0  4
  [ 9] .jcr              PROGBITS        00018700 008700 000004 00  WA  0   0  4
  [10] .data             PROGBITS        00018708 008708 000438 00  WA  0   0  8
  [11] .bss              NOBITS          00018b40 008b40 00001c 00  WA  0   0  4
  [12] .comment          PROGBITS        00000000 008b40 00002b 01  MS  0   0  1
  [13] .ARM.attributes   ARM_ATTRIBUTES  00000000 008b6b 00002c 00      0   0  1
  [14] .shstrtab         STRTAB          00000000 008b97 00007b 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  y (purecode), p (processor specific)
```

Here we can see all the individual sections that are included in the simple executable.  For example the .text section contains the actual executable code.  The .rodata contains read only constant that are used the the executable.  The .data contains pre-initialized variables that contain values that are not zero.  All of these seem all right.  Non of the sizes are very large, at least nowhere near the 36K of the executable.  First I'll explain some of the fied meanings.  The Type field is the type of the section and what it will be sued for.  The Addr field is the destination address in the virtual memory space.  Off is the offset in the actual executable file it's self.  And Size is the size of the section.

This seems to be all normal, except after some close examination you will notice that the .init section which is the first section starts at a file offset of 0x8000 which is 32K.  This means that the first section in the ELF executable is located 32K into the file.  There is some header information, but certainly not 32K of header information.  This seems to be the problem.

The solution to this is to tell the linker what the page size of the sections should be.  By default the linker assumes that the user want's a page size of 32K which means that the sections must me aligned to 32K which causes much empty space at the beginning of the program.  This can be specified to the linker by using the -max-page-size linker flag.

```sh
# Compile with the max-page-size information.
arm-none-eabi-gcc --specs=nosys.specs -z max-page-size=0x04 main.c -o executable

# Print the size of the new executable.
 ls -lh executable :Q
-rwxr-xr-x 1 jhamberg jhamberg 28K Oct  3 22:00 executable*

# Print the size of the new stripped executable.
ls -lh executable 
-rwxr-xr-x 1 jhamberg jhamberg 3.8K Oct  3 22:00 executable*

```

Here you can see that the size of executable is 3.8K which is much closer to what one would expect for such a simple program.  I assume the linker defaults to such a large page file for performance reasons.  When loading the executable into memory, presumably it would be faster to read data from the disk on page aligned memory offsets.  This is fine for a host system, but when space is at a premium on a embedded system this can be detrimental.




