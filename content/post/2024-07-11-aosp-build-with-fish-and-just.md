---
title: AOSP builds from fish shell using just
subtitle: 
date: 2024-08-11
tags:
  - fish
  - aosp
draft: false
---

# Introduction
I like to use the fish shell.  It's easy to use, has most thingns I like to use configured with no issues.  The problem I've run into recently is that building AOSP is only supported by running bash.  This is because the build scripts define a bunch of bash functions that cannot be converted over to fish shell.

# Building on Android
```
cd android-14-gsi
source build/envsetup.sh
lunch aosp_cf_x86_64_phone-eng
# m is a bash function
m sync
```

I use [just](https://github.com/casey/just) on my development machines.  I'd like to be able to just specify `just aosp m sync` to run whatever command I'd like. Typically I'd just create a bash script runner command in just and source the commands from above.  But some android variant's can take a little while to run the `envsetup.sh` and `lunch` commands, so you wouldn't want to run them every time you run a command.

# Solution
The solution I came up with is to source the build enviroment for running AOSP commands, and then saving this state to file.  Then whenever I'd like to run a AOSP build command from just, I'll just source this saved state and run the command directly.

In bash this is how you'd save the state.
```
 declare -p > aosp-state.sh && declare -f >> aosp-state.sh
```
Here's the docs for `-p	display the attributes and value of each NAME`.  This is required.  Because by default the declare statement will only save bash variables, and will not distinguise between a regular bash variable and an environment variable.  These types are needed because the AOSP needs these environment variables.

The second part saves all functions declaration in a bash shell to the file so that they can be sourced later.

Now to run an AOSP build you'd source the saved state like so.
```
source aosp-state.sh
bash: declare: BASHOPTS: readonly variable
bash: BASH_VERSINFO: readonly variable
bash: declare: EUID: readonly variable
bash: declare: PPID: readonly variable
bash: declare: SHELLOPTS: readonly variable
bash: declare: UID: readonly variable
```

Only problem is that you get a bunch of warning about read only variables.  There are some variables that are not actually variables, but information provided directly by bash to the user.  If you don't want to see the warning every time you source this script you should manually delete these entries from aosp-state.sh

If you look in the file they are anything that is specified by the `declare -r` option before the variable name.  Make sure to ignore the - when searching for matches.  You only care about the r part of the declare specification.


Now to build you just need to 
```
source aosp-state.sh
m sync
```

This is much faster than having to run the setup steps.

# Justfile integration

.justfile
```
aosp target:
    #!/usr/bin/env bash
    source aosp-state.sh
    cd ~/android/android-14-gsi
    {{target}}
```

Now an just command can be run from wherever to start a AOSP build.
Like so
```
just aosp m sync
```

Because we are not actually running the `envsetup.sh` and `lunch` this command starts very quickly.  The only downside of this is that every time there is a change to the `envsetup.sh` or the `lunch` target the state will need to be saved again to aosp-state.sh because this is not automatically updated.  For now that's something that I'm willing to live with.  Hope this helps anybody who uses the fish shell, but would like to start AOSP builds without leaving the fish shell environment.
