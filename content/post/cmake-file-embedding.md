---
title: Embedding Binary Data in Executable with CMake
subtitle:
date: 2020-11-30
tags: ["cmake"]
draft: false
---

# Embedding Arbitrary Data in Executable with CMake

Sometimes you need to include some binary data into an executable.  It's a lot easier to distribute 1 executable than it is to distribute an executable with supporting files.  There are many times that embedding files into an executable would be useful.  For example you could embed some simple image files into the executable, or any resource you would like to use in the executable.  Also sometimes a target that you are compiling for doesn't have file system support like an embedded target for example.  In this article I'm going to show how to embed arbitrary binary data into an executable.

There are a couple requirements to this system that I would like to discuss before we get starting.  This method should be cross platform.  There are several ways of embedding binary data into an executable using the linker, but that would not be cross platform across the many C++ compilers like GCC, Clang, and MSVC and others.  Also the embedded files should take advantage of CMake's features and automatically keep the binary data up to date if the source file changes.

# Getting Started in CMake

The first thing we are interested in is figuring out how to get the data from an arbitrary file into CMake.  This is where the `file(READ)` function comes in.  The `file(READ)` takes in a file as an argument and a variable that the content of the file should be stored in.  It also has a HEX command which converts the file into HEX which allows us to work with binary data.

We'll be working with a file called `message.txt` which contains the following text.

```text
This mesage is from message.txt
```

Let's try out the `file(READ)` function.

```cmake
file(READ message.txt content HEX)
message(${content})
```

This file outputs the following message `54686973206d6573736167652069732066726f6d206d6573736167652e747874`  This is the content from the message.txt file that has been encoded using HEX.  Every 2 hex characters corresponds to 1 byte of the source file.  We now have the raw data of the file that we want to embed into the executable. Now we want to be able to store each byte as a separate element in a CMake list so that we can work with the data easier.  We can do that using the `string(REGEX)` function to separate each of the bytes.  Here's the syntax: `string(REGEX MATCHALL "([A-Fa-f0-9][A-Fa-f0-9])" SEPARATED_HEX ${content})`  This uses the regex of 2 hex digits and matches all occurrences of the matched regex into a list called SEPARATED_HEX.

Now that we have all of the data in accessible in CMake we just need a way to store that data in an executable. The method I am going to use is to create a .c file that corresponds to the binary data that we want to embed.  Once the source file has been created we are going to create an array and initialize that array to contain the contents from the file that we would like to embed in the executable.  Here's the code to do just that.

```cmake
# Create a counter so that we only have 16 hex bytes per line
set(counter 0)
# Iterate through each of the bytes from the source file
foreach (hex IN LISTS SEPARATED_HEX)
	# Write the hex string to the line with an 0x prefix
	# and a , postfix to seperate the bytes of the file.
    string(APPEND output_c "0x${hex},")
    # Increment the element counter before the newline.
    math(EXPR counter "${counter}+1")
    if (counter GREATER 16)
    	# Write a newline so that all of the array initializer
    	# gets spread across multiple lines.
        string(APPEND output_c "\n    ")
        set(counter 0)
    endif ()
endforeach ()

# Generate the contents that will be contained in the source file.
set(output_c "
#include \"${c_name}.h\"
uint8_t ${c_name}_data[] = {
    ${output_c}
}\;
unsigned ${c_name}_size = sizeof(${c_name}_data)\;
")

# Generate the contents that will be contained in the header file.
set(output_h "
#ifndef ${c_name}_H
#define ${c_name}_H
#include \"stdint.h\"
extern uint8_t ${c_name}_data[]\;
extern unsigned ${c_name}_size\;
#endif // ${c_name}_H
    ")

```

After the code from above executes here will be the contents of the .h/.c file.

message_txt.h

```c
#ifndef message_txt_H
#define message_txt_H
#include "stdint.h"
extern uint8_t message_txt_data[];
extern unsigned message_txt_size;
#endif // message_txt_H
```

message_txt.c

```c
#include "message_txt.h"
uint8_t message_txt_data[] = {
    0x54,0x68,0x69,0x73,0x20,0x6d,0x65,0x73,0x73,0x61,0x67,0x65,0x20,0x69,0x73,0x20,0x66,
    0x72,0x6f,0x6d,0x20,0x6d,0x65,0x73,0x73,0x61,0x67,0x65,0x2e,0x74,0x78,0x74,
};
unsigned message_txt_size = sizeof(message_txt_data);
```

Here you can see that the message_txt.h exposes the name of the data that has been embedded into the executable.  The name of the object is named after the source file name.  message.txt has been transformed into message_txt_data and message_txt_size.  The data is a uint8_t  point to the actual data that has been embedded.  The size is the size in bytes of the data that has been embedded.  Now that the source files have been generated in cmake we need to create a CMake target to build the generated source files.

```cmake
# This function is used to create the file_embed target which is used to build
# the generated source files from the imported binary file.
function(FileEmbedSetup)
	# Make sure the directory exists where the generated source files end up
    if (NOT EXISTS ${CMAKE_BINARY_DIR}/file_embed)
        file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}file_embed)
    endif ()
	# CMake does not allow libraries with no source files.
	# So create an empty source file if necessary to create the library with.
    if (NOT EXISTS ${CMAKE_BINARY_DIR}/file_embed/file_embed_empty.c)
        file(WRITE ${CMAKE_BINARY_DIR}/file_embed/file_embed_empty.c "")
    endif ()
	
	# Create the file_embed library which will be used to compile all the
	# generated source files.
    add_library(file_embed ${CMAKE_BINARY_DIR}/file_embed/file_embed_empty.c)
    # When linking against this library make sure the include directory is 
    # added to the library.
    target_include_directories(file_embed PUBLIC ${CMAKE_BINARY_DIR}/file_embed)
endfunction()

```

Now all that's left is to make CMake aware of the files that we would like to import into the project.  I've created a function `FileEmbedAdd(file)` that does just that which is defined below.

```cmake
function(FileEmbedAdd file)
	# Contains all the code from above to read in a file contents
	# and write the array to a generated .h/.c file.
    FileEmbedGenerate(${file} var)
    # target sources linkes a source file to the specified library.
    # the var varibale contains the name of the source file that
    # contains the generated array for the embedded data.
    target_sources(file_embed PUBLIC ${var})

	# This command adds a custom command that indicates that the 
	# generated source file is dependent on the source binary 
	# file.  THis means that if the source file changes then
	# the generated embedded file should also be updated.
    add_custom_command(
            OUTPUT ${var}
            COMMAND ${CMAKE_COMMAND}
            -DRUN_FILE_EMBED_GENERATE=1
            -DFILE_EMBED_GENERATE_PATH=${file}
            -P ${CMAKE_SOURCE_DIR}/cmake/FileEmbed.cmake
            MAIN_DEPENDENCY ${file}
    )
endfunction()

```

Here is what the user would see if they would use these CMake functions.  here's the user's CMakeLists.txt where the project is set up and the file is registered using the FileEmbedAdd function.

```cmake
cmake_minimum_required(VERSION 3.11)
project(file-embed)

add_executable(main main.cpp)

include(../cmake/FileEmbed.cmake)
FileEmbedSetup()
FileEmbedAdd(${CMAKE_SOURCE_DIR}/message.txt)

target_link_libraries(main file_embed)
```

```c++
// Include the generated file that is used to access the embedded data.
#include "message_txt.h"
#include <iostream>

int main() {
    // Iterate over each character of the imported embedded data.
    for(unsigned i = 0;i < message_txt_size;i++) {
        // Print the message to the console.
        std::cout << message_txt_data[i];
    }
    std::cout << "\n";
}

```

Here's the output of the example program.

```sh
make
./main
This message is from message.txt
```

# Conclusion

An example of this file embedding code is available on [GitHub](https://gitlab.com/jhamberg/cmake-examples/-/blob/master/cmake/FileEmbed.cmake).  Now you can embed files into an executable and access the data without needing to use a file.  This method also has the advantage of being compatible between multiple compilers.