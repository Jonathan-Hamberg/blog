---
title: Meson Python Modules
subtitle:
date: 2020-02-24
tags: ["meson", "python", "c"]
draft: false

---

The meson build system is very versatile and can be integrated with a wide variety of technology.  Meson can be used to build C modules that link in as a python module.  Sometimes this is required to allow Python to integrate with a system library written in C. Let start by creating a Python module called mymath which implements a function called add written in C.  This library contains all the definitions for the methods to interface with the extension module.  You can see how it looks exactly like regular python code, except the mymath.add() function is implemented in C.  Here is how the module would be used in Python.  You can see that it looks exactly like any other regular Python code.

```python
#!/usr/bin/env python3
import mymath
import sys

result = mymath.add(5, 3)
print('5 + 3 =', result)
```

Now lets look at the C file required to define the Python module.  All the function that are required to interface with Python are included from a system header file called "Python.h"

```c
// This includes all the requried Python definitions.
#include <Python.h>

// Definition of the add function in the external module interface.
static PyObject* add(PyObject *self, PyObject *args) {
    long long a, b, result;
    // PyArg_ParseTuple is a var args type function that behaves
    // similarlly to scanf by passing in a format string and the
    // pointers to the variables that are requsted.
    if(!PyArg_ParseTuple(args, "LL", &a, &b))
        return NULL;

    // Calculate the result of the add function.
    result = a + b;
    
    // Use Python's helper function to convert long long to
    // python return type.
    return PyLong_FromLong(result);
}

// Array that contains all the methods defined by this externel module.
static PyMethodDef MymathMethods[] = {
    {"add",  add, METH_VARARGS,
     "Add two numbers."},
    {NULL, NULL, 0, NULL}
};

// Structure that contains the definition of the external module.
static struct PyModuleDef mymathmodule = {
   PyModuleDef_HEAD_INIT,
   "mymath",
   NULL,
   -1,
   MymathMethods
};

// Function that gets called on load.  This creates a module with
// the PyModule_Create function.
PyMODINIT_FUNC PyInit_mymath(void) {
    return PyModule_Create(&mymathmodule);
}

```

Now all we need is the meson.build project to build the C extension module.

```python
# Create normal meson project.
project('Mymath python extension', 'c',
  default_options : ['buildtype=release'])

# Import python3 meson module which is used to find the Python dependencies.
py3_mod = import('python3')
# Locate the python executable.
py3 = py3_mod.find_python()
# Create the Meson python3 dependency from the python3 module.
py3_dep = dependency('python3', required : false)

if py3_dep.found()
  # Create the external C module using the python3 module helper function.
  pylib = py3_mod.extension_module('mymath',
    'mymath_module.c',
    dependencies : py3_dep,
  )

  # Pathdir contains the dynamic library module.
  pypathdir = meson.current_build_dir()

  # Create a test script that runs a python script that uses
  # the C external module.  Must populate PYTHONPATH to include
  # a path that includes the mymath.so dynamic library.
  test('extmod',
    py3,
    args : files('mymath_test.py'),
    env : ['PYTHONPATH=' + pypathdir])

  # Check we can apply a version constraint
  # dependency('python3', version: '>=@0@'.format(py3_dep.version()))
else
  error('MESON_SKIP_TEST: Python3 libraries not found, skipping test.')
endif

```

Let's try out building the external python module using meson.  This should start looking familiar by now if you've worked with Meson at all.  Meson can be used to run unit tests defined for the project.  By default the output of the unit test is not visible on the command line.  If the -v argument is passed to the meson test command then the output of the unit test will be visible on the console.

```sh

$ meson build
$ ninja -C build
$ cd build
$ meson test -v
...
5 + 3 = 8
...

$ env PYTHONPATH=build python3 mymath_test.py
5 + 3 = 8

```

If you don't mind writing a bit of C code, extending Python can be a useful way to integrate existing C code in a very Pythonic way.  Meson does a great job of finding all the dependencies and linking them together in a easy to use way.