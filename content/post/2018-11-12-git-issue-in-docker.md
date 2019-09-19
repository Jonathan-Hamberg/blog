---
title: Git Issue in Docker
subtitle: Failed to Initialize Git Repository in Docker
date: 2018-11-12
tags: ["git", "docker", "wsl"]

---

# Failed to Initialize Git Repo in Docker

http://blog.johngoulah.com/2016/03/running-strace-in-docker/

While working with Docker I was trying to automate the build of a project.  The project automatically downloaded the source code for several dependencies using Git.  When running this command on Linux everything worked flawlessly as expected.  When I tested the same build setup on Docker for Windows on my PC things worked as expected there were no build issues.

Then as other people started to use the build script they ran into a weird error that I have never seen before that is shown below.  The error message seems to indicate that somehow the git config file was incorrect suggesting that the core.filemode was unable to be set to false.  I originally thought that there must be a file permission issue but the permissions were the same on both computers where one worked and the other didn't.  And I noticed that files could still be created and written too so it wasn't a permission error.  I thought the who point of docker and containers was to prevent issues like this and create a repeatable build environment.

```sh
error: invalid config file /data/wsl-directory/.git/config                                         
fatal: could not set 'core.filemode' to 'false' 
```

The first steps to debugging this was to find some way to reproduce the issue on my PC where everything worked as expected.  My co-worker pointed my in the correct direction by demonstrating that when running the git init command in Docker in a directory that was created by WSL the same error message appeared that was the same as before.  But if the folder was created in windows the git init command inside docker worked as expected.

To start debugging this issue I created a minimum reproducible example using the simple docker file below.

```dockerfile
# Using Debian because it is small to download.
FROM debian

# Install git and strace which will be used later.
RUN apt-get update && apt-get install -y git strace
```

I created the file directory listed below.

```
docker-git
	windows-directory
	wsl-directory
```



```sh
# Build the Docker image and then run an interactive shell.
docker build -t debian-git .
docker run -v "%cd%":/data --security-opt seccomp:unconfined -it debian-git

# Run git init in the windows-directory created in Explorer.exe
root@872cca3eefb1:/ cd /data/windows-directory/                           root@872cca3eefb1:/data/windows-directory git init
Initialized empty Git repository in /data/windows-directory/.git/

# Run git init in the wsl-directory created in WSL.
root@872cca3eefb1:/data/windows-directory cd /data/wsl-directory/                                   root@872cca3eefb1:/data/wsl-directory git init
error: invalid config file /data/wsl-directory/.git/config                                         
fatal: could not set 'core.filemode' to 'false'  
```

I was trying to figure out why this error message was happening.  All the Google search results seemed to be pointing to a different issue than I was having.  They would talk about why you should use core.filemode not why the error was happening when the Git repo was being initialized.  I needed to get a deeper understanding of what was causing the issue.  I decided to give [strace](https://strace.io/) a try.  strace is a utility that is used to log all the system calls that an executable is calling.  For example it logs all file access, read, and writes.  I ran the strace using the same commands as above and compared the differences between the two different log files.

First of all because strace is monitoring system calls which is potentially dangerous you must specifically tell docker to allow it with the --security-opt seccomp:unconfirmed command line argument to the Docker run command.  You must manually compare the output of the good version to the bad version because the file handles are not deterministic between runs in docker.  This means that I couldn't just use vimdiff to find the differences.

```sh
# This is the output from the git init that caused an error.
# Here we can see the code that writes the error message to the console.
# The system calls that preceded it are also included.
# The Correct output is included below.

open("/data/wsl-directory/.git/config", O_RDONLY) = 4
open("/data/wsl-directory/.git/config", O_RDONLY) = -1 ENOENT (No such file or directory)
fstat(2, {st_mode=S_IFREG|0755, st_size=20556, ...}) = 0
write(2, "error: invalid config file /data"..., 59error: invalid config file /data/wsl-directory/.git/config
) = 59
close(3)                                = 0
unlink("/data/wsl-directory/.git/config.lock") = 0
close(4)                                = 0
write(2, "fatal: could not set 'core.filem"..., 48fatal: could not set 'core.filemode' to 'false'
) = 48

# Here you can see that no error message haw been written.
open("/data/windows-directory/.git/config", O_RDONLY) = 4
open("/data/windows-directory/.git/config", O_RDONLY) = 5
fstat(5, {st_mode=S_IFREG|0755, st_size=36, ...}) = 0
read(5, "[core]\n\trepositoryformatversion "..., 16384) = 36
```

Here we can see that the first difference between the two versions happens on the third call to open().  Also one thing to note is that the second and third call to open are in reference to the same file.  In the git init with the error the second open() call fails with an error code where as the correct versions opens it without a problem.  The problem seems to be when the git init is run in the folder that is created by WSL it cannot open the same file twice without throwing an error.

After doing some more directed research on Google with the newly found informating using strace I was able to find the problem.

