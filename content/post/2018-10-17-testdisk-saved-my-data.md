---
title: TestDisk Saved My Data
subtitle: Using Testdisk to Recover a Formatted Partition
date: 2018-10-17
tags: ["linux", "data recovery"]

---

It started a couple days ago when I was trying to format a flash drive on Linux.

I ran the following commands to format the flash drive to exfat so that I could use it to take some files to work that I needed.

```sh
mkfs.exfat /dev/sdc1
```

The only problem was that I didn't double check the device I was formatting.  This is something that you should always check, when you are running a destructive command.  It took me a couple minutes to realize that I did anything wrong.  But when I realized that I accidentally formatted my 1 TB hard-drive filled with Movies, TV Shows, Personal Pictures, and Games.  I had to take a minute to relax.

I spent the next two evenings researching how to recover data that has been lost.  One fortunate thing that happened was is that the format operation I performed was a quick format operation.  This means that it just rewrote the meta-data and didn't necessarily overwrite all my data like a complete format would have.

After my research it seemed that a program called [TestDisk](https://www.cgsecurity.org/) would be promising.  TestDisk works by scanning every single sector on the hard drive partition in question.  This is a time consuming process for my 1 TB hard drive, because every single sector had to be scanned to look for old file system meta data which could be used to recover the files from the formatted partition.  After the process was done the TestDisk program was able to locate all the files left on the disk.  No all that was left to do was copy them to a secondary hard drive that I had installed in my system.

The following images show TestDisk exhaustively scanning my hard drive for files that were referenced by the old file system.

![TestDisk Scan](/img/testdisk-scan.png)

In the end I was able to recover almost all my data.  I was able to recover my personal pictures, movies, and Games, but for some reason I was not able to recover my TV Show folder.  All in all I'm glad that I was able to get most of my data back.  Now i know that there is software out there that can help you recever deleted data as long as a full format was not performed on the partition.

The moral of the story is that you should always double and even triple check the parameters to a destructive disk operation.  It would have saved my a lot of time and lots of stress.  Now I just need to look into a good solution for backing up large amount of data that don't fit on my OneDrive.
