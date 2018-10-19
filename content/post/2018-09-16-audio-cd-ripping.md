---
title: Audiobook Ripping on Linux
subtitle: cdparanoia, sox, and lltag
date: 2018-09-15
tags: ["shell", "audio"]
---
In this blog post I would like to share my process for ripping audio-books for listening to on my commute to work.  I will also talk about some of the challenges of ripping audio in a reliable way without many defects.  I am also going to describe how to use some of the programs that I use to produce the output of the cdripping script.

# CDPARANOIA

At the center of the audio CD ripping process is a program called cdparanoia.  Cdparanoia extracts audio from compact discs directly as data, with no analog step between, and writes the data to a file in an uncompressed format.  In  addition  to simple reading, cdparanoia adds extra-robust data verification, synchronization, error handling and scratch reconstruction capability.

Because of these additional error checking features, the ripping time can take a fair amount of time.  It takes anywhere from 5 minutes to an hour to rip one audio CD depending on the number of errors on the disk.  On average it takes about 10 - 15 minutes.

```sh
# RIP a cd by specifier the first track to the last track and the output file format.
cdparanoia 1- output.wav
cdparanoia III release 10.2 (September 11, 2008)
 
Ripping from sector       0 (track  1 [0:00.00])
	  to sector  298786 (track 11 [7:41.43])

outputting to cdda.wav

 (== PROGRESS == [+++ ++++++++  ++++++++++++>   | 260405 00 ] == :-P O ==)
```

Below is the legend for the symbols in the progress bar from cdparanoia.  All of the errors should not affect the output unless specifically specified by the V symbol which means there was an uncorrected error/skip.  All the other symbols were able to successfully be corrected

```text
PROGRESS BAR SYMBOLS:
<space> No corrections needed
   -    Jitter correction required
   +    Unreported loss of streaming/other error in read
   !    Errors are getting through stage 1 but corrected in stage2
   e    SCSI/ATAPI transport error (corrected)
   V    Uncorrected error/skip
```



# SOX

SoX is a program that is used to read, write, edit, and splice popular audio formats.  It has a simple syntax to convert audio formats.  Files can simply be converted to another format by specifying the source file and specifying the destination file with the appropriate file extension.  Audio files can be combined into one file by specifying a list of files and the desired output file.  this is useful if you want to combine multiple track of a disk back into one file for the disk.  This swiss army knife of a tool can be used for many more things, but I simply use to transcode the resulting audio to compressed lossy and lossless formats.  When cdparanoia is finished the result is a .wav file that is approximately 700 MB.  SoX is used to convert the result .wav file to a lossless .flac file which is approximately 150 MB and then also a compressed Vorbis ogg file is produced which is approximately 50 MB large.  The smaller compressed audio format is good for playing on a mobile phone to save space.

```sh
# Convert an uncompressed audio file into a compressed ogg vorbise file.
sox output.wav output.ogg

# Convert uncompressed audio file into a lossless flac file.
sox output.wav output.flac

# Concatinate many files into one.
sox part01.wav part02.wav part03.wav output.flac

# Support for new formats can be added by simply instaling the right packages.
sudo apt install libsox-fmt-mp3
sox output.wav output.mp3
```



# SCRIPT USAGE

I wrote a simple shell script to expedite the process of ripping audio books to by desktop.  The script is currently only around 150 lines of code with comments.  Once on my desktop I can just copy the compressed output files to my phone to listen to on the bus.  My script is available on [GitHub](https://raw.githubusercontent.com/Jonathan-Hamberg/dotfiles/master/.local/bin/cdripper) for reference.

The goals of the script were to automate the ripping process.  Desired features

1. Automatic in order disk numbering.
2. Automatic output directory management.
3. Automatic audio transcoding of the audio disk.

Below is a sample invocation of the script.  You must specify the album that is being ripped.  This is used as the output directory of the script where audio end up.  The first thing the script does is to search the output directory to see what disks are already present.  It picks the next available disk and uses that as the filename for the output.  This satisfies requirement one of the cdripper script.  The file are automatically moved to the Ender_in_Exile directory when finished which satisfies requirement number two.  After the audio disk has finished ripping the audio is automatically transcoded to Disk05.flac and Disk05.ogg.  The flac file is for the lossless audio which can be used to transcode into any other format.  The Vorbis ogg file is used to copy to my phone to listen to on the bus.

```sh
cdripper --album Ender_in_Exile
Ender_in_Exile/Disk05
cdparanoia III release 10.2 (September 11, 2008)
 
Ripping from sector       0 (track  1 [0:00.00])
	  to sector  298786 (track 11 [7:41.43])
	  
outputting to Disk05.wav

 (== PROGRESS == [+++ +++  + +  ++++++++++++V+++| 298786 00 ] == :^D * ==)   

Done.

Rip Time: 30:05m
Transcode Time: 59s
```
