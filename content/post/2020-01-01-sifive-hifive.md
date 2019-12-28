---
title: PC / Desk Setup
subtitle:
date: 2019-12-12
tags: ["pc", "desk"]
draft: true
---

git clone https://github.com/sifive/freedom-e-sdk
git submodule init
git submodule update

https://sifive.github.io/freedom-e-sdk-docs/userguide/buildingdevboard.html

make TARGET=sifive-hifive1-revb PROGRAM=hello


make TARGET=sifive-hifive1-revb PROGRAM=
sudo picocom -b 115200 /dev/ttyACM0

Bench Clock Reset Complete

ATE0-->ATE0
OK
AT+BLEINIT=0-->OK
AT+CWMODE=0-->OK



                  SIFIVE, INC.

           5555555555555555555555555
          5555                   5555
         5555                     5555
        5555                       5555
       5555       5555555555555555555555
      5555       555555555555555555555555
     5555                             5555
    5555                               5555
   5555                                 5555
  5555555555555555555555555555          55555
   55555           555555555           55555
     55555           55555           55555
       55555           5           55555
         55555                   55555
           55555               55555
             55555           55555
               55555       55555
                 55555   55555
                   555555555
                     55555
                       5


               Welcome to SiFive!

```
# Make standalone project
make standalone PROGRAM=example-spi TARGET=sifive-hifive1-revb INCLUDE_METAL_SOURCES=1 STANDALONE_DEST=/home/jhamberg/src/hifive-esp32solo
```

```
# Put in Makefile.oeu
upload:
	echo -e "loadfile src/debug/example-spi.hex\nrnh\nexit" | JLinkExe -device FE310 -if JTAG -speed 4000 -jtagconf -1,-1 -autoconnect 1

```
