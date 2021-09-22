---
title: Embedding Git Hash with CMake
subtitle:
date: 2020-11-27
tags: ["cmake", "git"]
draft: false
---

# Using Git Commit Hash in CMake Project

Often times it's very useful to include the version number into the software that you are building.  Even better than a version number is the git hash of the commit that was used to build the software release.  In this article I'm going to describe my function that I came up with to do just that.

Let's start with the code to read the git hash from the current source directory.  This command reads the current git commit hash and stores the result in the variable GIT_HASH.

```cmake
    # Get the latest abbreviated commit hash of the working branch
    execute_process(
        COMMAND git log -1 --format=%h
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
        OUTPUT_VARIABLE GIT_HASH
        OUTPUT_STRIP_TRAILING_WHITESPACE
        )
```

This commit hash can then be passed on to the rest of the CMake project.  It seems like we this should be all we need.  Unfortunately there are several issues with using just this method alone.  This command is only run during the CMake configuration stage.  So if the user configure the CMake project, then commits some changes, and then builds again the GIT_HASH variable will not be updated because the CMake project was not re-configured.  This will lead to the wrong hash being used in building the project.

So lets talk about how we are going to expose the git commit hash to the build code.  The first option would be to pass the git hash as a define statement to the project being build.  The down-side of this is that if the git commit hash changes then the whole project has to be rebuilt, because the command line arguments have changed.  The second option would be be put the git hash in a header file that could be accessed by the rest of the project.  This is better, because the whole project would not have to be recompiled, but only the files that included the header that contained the git commit hash.  Another option would to be to have a header file that contains a external reference to the git commit hash.  The git commit hash would then be written to a source .c or .cpp file.  this has the advantage of only having to re-compile one file when the git commit has has changed.  This is the approach I have chosen for this function.

Here is the source of the git_version.h.

```c
#ifndef GIT_VERSION_H
#define GIT_VERSION_H

extern const char *kGitHash;

#endif // GIT_VERSION_H
```

Here is the source of the git_version.cpp.in

```c
#include "git_version.h"
const char *kGitHash = "@GIT_HASH@";
```

This is not the file that will actually be compiled.  First it must be configured by CMake to include the actual git commit hash that should be used.  CMake includes a function called configure_file that can be used to configure a file and update all of the CMake variables that are referenced in the configuration file.

```cmake
configure_file(git_version.cpp.in git_version.cpp @ONLY)
```

Okay now we have a way to access the git commit hash, but we still have the problem of the hash not being updated unless the project is re-configured.  So let's add a custom target that is run every time the project is build.  this custom target will determine if the git commit hash has changed and update it if necessary.  Here's how to add a custom target that runs a CMake command.

```cmake
add_custom_target(AlwaysCheckGit COMMAND ${CMAKE_COMMAND}
    -DRUN_CHECK_GIT_VERSION=1
    -Dpre_configure_dir=${pre_configure_dir}
    -Dpost_configure_file=${post_configure_dir}
    -DGIT_HASH_CACHE=${GIT_HASH_CACHE}
    -P ${CURRENT_LIST_DIR}/CheckGit.cmake
    BYPRODUCTS ${post_configure_file}
    )
```
We are adding a target called AlwaysCheckGit.  The COMMAND ${CMAKE_COMMAND} indicates that we should run the cmake executable for this command.  The -P indicates that we should run cmake in a script mode which means that it will run the cmake file, not modify the cache at all.  We must also pass any variables we want the script to have access through the -D arguments.  the -DRUN_CHECK_GIT_VERSION=1 tells the script that we should run the CheckGitVersion function.  The -Dpre_configure_file and -Dpost_configure_file include the directories that the configuration files are from and the generated data should go.  These must be passed along since a CMake script file does not have access to the cache so we must pass these values along.  We also have to specify the BYPRODUCTS of the command.  This allows the byproducts to be used in other parts of the CMake script otherwise there would be an error indicating that the file is missing, but in reality the file has just not been generated yet, which isn't a problem.

We almost have all of the pieces together.  The only thing left is that we want to reduce the amount of work done.  We only want to regenerate the git_version.cpp if the git hash has actually changed. Since we don't have access to the CMake cache when running in CMake's script mode, we have to save this information into an external file called git-state.txt.

We can write the git commit hash using the file(WRITE) command and then we can file(STRINGS) command to read the content of the file back into CMake.  This method of saving the state between between runs of the CMake command comes from the CMake-git-version-tracking [repository](https://github.com/andrew-hardin/cmake-git-version-tracking/).

```cmake
# This command is used to save git commit hash.
file(WRITE ${CMAKE_BINARY_DIR}/git-state.txt ${git_hash})
# This following command is used to retreive the git commit hash from the file.
if (EXISTS ${CMAKE_BINARY_DIR}/git-state.txt)
    file(STRINGS ${CMAKE_BINARY_DIR}/git-state.txt CONTENT)
    LIST(GET CONTENT 0 var)
    set(${git_hash} ${var} PARENT_SCOPE)
endif ()

```

Here is how the the command is expected to be used in a normal CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.11)
project(git-hash)

include(../cmake/CheckGit.cmake)
CheckGitSetup()

add_executable(main main.cpp)
target_link_libraries(main git_version)

```

Here's a example cpp file that uses the git commit hash and prints it to the console.  This file will update with the new git hash every time a new git commit is mode.

```c++
#include <iostream>
#include "git_version.h"

int main()
{
    std::cout << "Git Hash: " << kGitHash << "\n";
    return 0;
}
```

In review, I believe this is one of the best methods of including a git commit hash in a CMake project.  It is able to update the git commit hash without re-configuring the project.  It only updates the git commit hash when it changes reducing the amount of source files that have to be recompiled between git commits.

Here's a [link](https://gitlab.com/jhamberg/cmake-examples/-/blob/master/cmake/CheckGit.cmake) to the complete version of the code.  I've glossed over some of the finer implementation details since some of them are not super important and is just fighting with CMake paths.
