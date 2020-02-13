---
title: Meson Polyglot - Rust and C
subtitle:
date: 2020-02-12
tags: ["meson", "rust", "c"]
draft: false



---

The definition of polyglot is "knowing or using several languages."  With that definition Meson could be considered a polyglot.  Meson is able to work with multiple languages.  Currently  `c`, `cpp`, `d`, `objc`, `objcpp`, `fortran`, `java`, `cs`, `vala` and `rust` are supported by Meson.

Rust is a language that emphasize on memory safety and speed at the same time.  Let's start with Rust's version of Hello World! and see about compiling it using meson.

```rust
fn main() {
    println!("Hello from Rust!");
}
```

Let's setup meson to compile this rust file.  The only different between the rust meson.build and a c meson.build is that rust is listed as one of the project supported languages and the executable source is a .rs file instead of a .c file.  Meson is able to handle the rest.

```python
project('rust_project', 'rust',
       version : '0.1',
       default_options : ['warning_level=3'])

executable('rust_exe', 'main.rs')
```

Now let's go ahead and create the build files just like we normally would.

```sh
$ meson build
$ ninja -C build
$ ./build/rust_exe
Hello from Rust!
```

Sometimes if you are using C code it can be helpful to use code that was written in Rust.  We can do this by linking a rust library into a c project.

Lets say we have a library that defines some math functions.  Like the add function which takes in two parameters and returns the sum of the two parameters.  Here is the Rust file that implements this math function.

```rust
// This is required to prevent name mangling which exporting symbols.
#[no_mangle]

// Extern is required to make the symbol visibly from the library
pub extern fn add(a: i32, b: i32) -> i32 {
    a + b
}
```

Now lets create a c file that uses the add function that is defined in the Rust lib.rs file.

```c
// Used for printf()
#include <stdio.h>

// Function prototype, so the compiler doesn't complain.
int add(int a, int b);

int main() {
    // Print the result of 5 + 3 calculated in Rust
    printf("5 + 3 = %d\n", add(5, 3));
}
```

Here's the meson.build file that is used to link the two languages together.

```python
# Notice that both c and rust are listed as project languages.
project('rust_project', ['c', 'rust'],
  version : '0.1',
  default_options : ['warning_level=3'])

# Create a rust static library.
# Must specify rust_crate_type otherwise the generated output
# won't be compatibily with the c linker.
rust_add_lib = static_library('add_rust', 'lib.rs', rust_crate_type : 'staticlib')

# Create a list of dependencies required by Rust.
# The dl library is required by Rust to link the library.
deps = [
  meson.get_compiler('c').find_library('dl', required: false),
  dependency('threads'),
]

# Create a c executable that links with a rust library.
# Specify the link dependency as you would with any other library.
executable('link_with_rust', 'link_with_rust.c', link_with: rust_add_lib, dependencies: deps)

```

Let's run the newly compiled program.

```sh
# Here's the output of the program.
$ ./build/
5 + 3 = 8
```

Now Lets see if we can do the reverse operation and call c code from rust.  Sometimes it can be useful to call code that is written in C from a Rust program.  This can be used to gradually convert a program to Rust by converting small sections of code to Rust at a time.  Lets compile the same example of a math library.  Here is the add function, but written in the C language this time.  The function is very simple.  It just adds a and b and returns the result.  Because C is used as the standard for external symbol names there is nothing special that needs to be done to allow the c code to be called from an external program.

```c
// A dirt simple function to add two numbers in C.
int add(int a, int b)
{
    return a + b;
}
```

Here is the rust code that can be used to call the C library function.

```rust
// The name of the library is required to find the external function.
#[link(name = "add_c")]

// Provides the function prototype to the rust program.
extern {
    fn add(a: i32, b: i32) -> i32;
}

// Use the math library from the main function of the Rust program.
fn main() {
    // Unsafe keyword is required because C is not gaurenteed
    // to follow all the memory safty rules that Rust does.
    unsafe {
        println!("5 + 3 = {}", add(5, 3))
    }
}
```

Here is the meson.build glue that is required to build the following code.

```python
# Create a project that uses the C and rust languages.
project('rust_project', ['c', 'rust'],
  version : '0.1',
  default_options : ['warning_level=3'])

# Create a c static library.
c_add_lib = static_library('add_c', 'lib.c')

# Create a rust executable that links with a c library.
executable('link_with_c', 'link_with_c.rs', link_with: c_add_lib)
```

These are the basics of linking Rust with C and C with Rust.  All of these examples have been found from `test cases` directory of the Meson source code.  They have been very valuable in understanding all the features of the meson build system.

