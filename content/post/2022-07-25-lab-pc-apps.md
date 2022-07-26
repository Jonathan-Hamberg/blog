---
title: Creating Programs for Lab Machines with No Internet
subtitle:
date: 2022-07-25
tags: ["docker"]
draft: false
---

# Introduction
At the office I work with a lot of remote lab machines.  There are different types of these machines.  Some running an old version of ubunt.  Some running an old version of CentOS.  Some have no admin permissions to install packages.  So have no internet which makes it hard to install packages.

There are several programs that make my development life easier like fish, rg, fd which I use everyday.  If I have to use old outdated tools that really gets in the way of my flow.  So in this article I'm going to describe how I got around the issue of running my software on a lab machine that doesn't have internet or admin privledges using Docker.

# Getting Started
Basically a lab machine does not have the ability to install new packages.  This means you cannot just install the desired package using apt or dnf because you don't have admin privledges.  Sometimes building the application from source is an option, but the machine may be missing build dependencies that you cannot just install with apt or dnf.
You also cannot just build the applications on your local machine because it has different GLIBC dependencies which make it a mess when moving binaries to a different system.

So in this article I'm going to describe how to compile these applications for the target system using docker.  Docker allows the user to specify distro that is used to run all of the commands in.  So to get this to work, docker just has to specify the base system to have the same system image as the remote target system.  If this is done the docker image can install all the build dependencies it wants and can just install every package it wants without needing admin or an internet connection on the target machine.

## Docker Script


```docker
FROM ubuntu
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
WORKDIR /home

# Update base system, then install packages that are available in the package
# manager
RUN apt-get update && \
        apt-get -y upgrade && \
        apt-get install -y build-essential curl libpcre2-32-0 python3 man-db gettext-base cargo direnv neovim picocom python3-sphinx cmake git ncurses5-dev pkg-config

# Create .local directory that will contain all the desired applications
# that will be moved to the remote target system.
RUN mkdir /home/jonathanhamberg && mkdir /home/jonathanhamberg/.local
# Install my desired rust programs.
RUN cargo install exa du-dust fd-find ripgrep bat tokei
# Clone and build fish-shell
RUN git clone https://github.com/fish-shell/fish-shell.git
RUN cd fish-shell && cmake -DCMAKE_INSTALL_PREFIX=/home/jonathanhamberg/.local/ . -DBUILD_DOCS=True && make -j32 && make install
# Move all binaries to the .local folder which is going to be copied
# to the remote target system.
RUN cp /root/.cargo/bin/* /home/jonathanhamberg/.local/bin/
RUN cp $(which nvim) /home/jonathanhamberg/.local/bin/
RUN cp $(which picocom) /home/jonathanhamberg/.local/bin/
RUN cp $(which direnv) /home/jonathanhamberg/.local/bin/
```

```sh
sudo docker build . -t myubuntu
```
Once the image has been build just copy the .local directory out of the docker image.
Then copy the .local image to the remote target server.
```sh
# Copy folder from docker image to the current directory.
sudo docker  run -v(pwd):/data -it myubuntu cp -r /home/jonathanhamberg/.local/ /data/.local/
# Copy the local .local to the remote target.
rsync -a .local/ remote_system:~/.local/
```

Now that this is done you can run all your modern applications that make you development environment feel like home.  You don't need admin or internet to make this work.  And whenever there is a different version of a lab machine you just need to modify the docker file to specify a different base image.
