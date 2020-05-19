---
title: Dotfile Managment using dotdrop 
subtitle: There has to be an easier way
date: 2020-03-25
tags: ["dotfiles", "python", "c"]
draft: false

---



Every developer has a customized system that they are familiar with to make coding easier.  For a Linux system this involves modifying the dotfiles for all the software being used on their system.  One of the dis-advantages of all these dotfiles is that they take a long time to get setup on a system.  So switching between different PC's can be a bit of a time sync to get everything setup to your liking.

There are several options available to sharing these files between PC's, but they are often cumbersome and finicky and still require a lot of work to get set up.  My previous method was to include all my dot files in a git repository.  This worked fairly well, but felt a bit hacky since my home directory was now a git repository and every once in a while conflicted with the normal operation of my system.

The solution I've ended up moving to is a program called dotdrop.  Dotdrop is a program used to save your dotfiles once, and deploy them everywhere.  It allows for customization per system.  In my case I can distribute the required dotfiles on my Windows PC, without cluttering my home directory with all the dotfiles for programs I'm not using.

Setup is really easy now as well.  Dotdrop is written in python and is available from the pip repository which allows for easy setup.  All that is required is cloning my git repository with all my dotdrop configuration and run the following commands.

```sh
pip3 install dotdrop
cd ~/.config
git clone https://gitlab.com/jhamberg/dotdrop.git
dotdrop install -p linux
```

