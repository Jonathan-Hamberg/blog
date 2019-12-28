---
title: Automatic CMake Header Dependency
subtitle: Download dependencies
date: 2019-12-27
tags: ["cmake", "c++"]
---

Often times 3rd party dependencies can be the hardest part of setting up a C++ project.  CMake has eased this pain, but it is still often quite difficult to deal with with the numerous different types of build system.  CMake includes the FetchContent library call which allows a dependency to either be cloned from a git repository or tar.gz archive to be included into the project.  This is a very convenient feature which allows your projects dependencies to be neatly downloaded without having to include the source in your project.  This has the disadvantage of having to clone the whole git repository which can take a long time and sometimes requires a large amount of disk space.

In my case the JSON for Modern C++ was taking 8 seconds to clone and took up 439 MB of space on my hard drive.  JSON for Modern C++ is known to be a heavyweight for a JSON library, but it seemed like just too much for a library that hasto parse a little JSON.  Fortunately JSON for C++ provides a link to the header only version of the library on their GitHub releases page.

CMake has a feature to download files from the Internet as part of the generation process.  So basically we are going to use CMake to automatically download the single header file to satisfy the JSON for Modern C++ dependency instead of having to clone the entire repository.

the file(DOWNLOAD) CMake command can be used to download files from a URL to a directory.  I've chosen the ${CMAKE_CURRENT_BINARY_DIR} since the header is a dependency and not actually considered part of the source of this project.  A interface library can be added which allows the library to be recognized by CMake.  The interface part is required because the library is a header only library and does not contain any source files.  The target_include_directories() command is used to specify the include path for the library that has just been downloaded.  Once this is done then the target_link_libraries can be used to "link" the header only library to whatever CMake targets that are available.

In this example I choose to download Catch2 unit testing framework and the JSON for Modern C++ framework in a minimal example.  The CMakeLists.txt comes in at a 16 lines of code which is pretty short for automatically downloading the project dependencies and  making them available to the rest of the CMake project.



```cmake
# Project preamble
cmake_minimum_required(VERSION 3.15)
project(main)

# Install catch dependency.
file(DOWNLOAD https://github.com/catchorg/Catch2/releases/download/v2.11.0/catch.hpp ${CMAKE_CURRENT_BINARY_DIR}/catch.hpp)
add_library(catch INTERFACE)
target_include_directories(catch INTERFACE ${CMAKE_CURRENT_BINARY_DIR})

# Install json dependency.
file(DOWNLOAD https://github.com/nlohmann/json/releases/download/v3.7.3/json.hpp ${CMAKE_CURRENT_BINARY_DIR}/json.hpp)
add_library(json INTERFACE)
target_include_directories(json INTERFACE ${CMAKE_CURRENT_BINARY_DIR})

# Add main executable.
add_executable(main main.cpp)

# Link 3rd party dependencies.
target_link_libraries(main json catch)

```

```c++
#define CATCH_CONFIG_MAIN
#include <catch.hpp>
#include <json.hpp>

TEST_CASE("Factorials are computed", "[factorial]") {
    nlohmann::json j = "{ \"happy\": true, \"pi\": 3.141 }"_json;
    CHECK(j["happy"].get<bool>());
}

```

