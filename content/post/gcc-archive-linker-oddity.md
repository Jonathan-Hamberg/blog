---
title: GCC Archive Linker Oddity
subtitle:
date: 2020-11-25
tags: ["gcc", "embedded"]
draft: false
---

# Problem Setup

I've recently been trying to compile a simple hello world program on a STM32F466 Nucleo development.  The STM32 MCU development kit comes with a excellent HAL.  I've been trying to get this HAL integrated well with the CMake build system.  I didn't want to specify all the HAL source files for every executable that I was going to add to the project.  So I naively decided to create a static library containing all of the 

```cmake
cmake_minimum_required(VERSION 3.11)
project(hello C CXX ASM)

# Create library called hal that contains the compiled STM32 HAL sources.
add_library(hal
        Core/Src/system_stm32f4xx.c
        startup_stm32f446xx.s
        Core/Src/stm32f4xx_hal_msp.c
        Core/Src/stm32f4xx_it.c
        Core/Src/syscalls.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_tim_ex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_uart.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_rcc_ex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_flash_ramfunc.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_gpio.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma_ex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_dma.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_pwr_ex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal.c
        Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_exti.c
        )
        
# Add CPU configuration compiler options.
target_compile_options(hal PUBLIC
        -mcpu=cortex-m4
        -mthumb
        -mfpu=fpv4-sp-d16
        -mfloat-abi=hard
        -fdata-sections
        -ffunction-sections
        $<IF:$<CONFIG:Release>,-Os,-Og>)
# Add linker options.
target_link_options(hal PUBLIC
        -mcpu=cortex-m4
        -mthumb-mfpu=fpv4-sp-d16
        -mfloat-abi=hard
        -T${CMAKE_SOURCE_DIR}/STM32F446RETx_FLASH.ld
        --specs=nano.specs
        -Wl,--gc-sections
        )
# Add compiler define options.
target_compile_definitions(hal PUBLIC -DUSE_HAL_DRIVER -DSTM32F446xx)

# Add include directorys necessary to compile the HAL.
target_include_directories(hal PUBLIC
        Core/Inc
        Drivers/STM32F4xx_HAL_Driver/Inc
        Drivers/STM32F4xx_HAL_Driver/Inc/Legacy
        Drivers/CMSIS/Device/ST/STM32F4xx/Include
        Drivers/CMSIS/Include
        Drivers/CMSIS/Include)

# Create sample application.
add_executable(hello
        Core/Src/main.c
        )
# Link the HAL agains the sample application.
target_link_libraries(hello hal)

```

Ideally we would have a successful compilation with the following commands.  To my suprise I get these errors thrown in my face instead.

```sh
FAILED: hello
: && /home/jhamberg/src/companion-firmware/toolchain/gcc-arm-none-eabi-9-2019-q4-major/bin/arm-none-eabi-gcc -O3 -DNDEBUG -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -T/home/jhamberg/src/embedded-cmake-course/04-08-library-dependencies/STM32F446RETx_FLASH.ld --specs=nano.specs -Wl,--gc-sections CMakeFiles/hello.dir/Core/Src/main.c.obj -o hello  libhal.a && :
/home/jhamberg/src/companion-firmware/toolchain/gcc-arm-none-eabi-9-2019-q4-major/bin/../lib/gcc/arm-none-eabi/9.2.1/../../../../arm-none-eabi/bin/ld: /home/jhamberg/src/companion-firmware/toolchain/gcc-arm-none-eabi-9-2019-q4-major/bin/../lib/gcc/arm-none-eabi/9.2.1/../../../../arm-none-eabi/lib/thumb/v7e-m+fp/hard/libc_nano.a(lib_a-sbrkr.o): in function `_sbrk_r':
sbrkr.c:(.text._sbrk_r+0xc): undefined reference to `_sbrk'
...
```

Normally linker errors are no big deal.  You just find the undefined reference and make sure that it's included in the build and properly linked in with the end result.  So I know that I'm defining the _sbrk function in the syscalls.c file.  This file should define all of functions required by the C lib to run on an embedded system.  In this case most of them are stub functions, other than the _write, and _sbrk functions which write to the console and update the heap respectivly.  If we take a look at the syscalls.c file we can see indeed that the _sbrk() function is implemented.

```c
caddr_t _sbrk(int incr)
{
	extern char end asm("end");
	static char *heap_end;
	char *prev_heap_end;

	if (heap_end == 0)
		heap_end = &end;

	prev_heap_end = heap_end;
	if (heap_end + incr > stack_ptr)
	{
//		write(1, "Heap and stack collision\n", 25);
//		abort();
		errno = ENOMEM;
		return (caddr_t) -1;
	}

	heap_end += incr;

	return (caddr_t) prev_heap_end;
}
```

Maybe the symbol didn't actually get compiled successfully into the hal library.  So let's search for the _sbrk() function in the libhal.a static library file.

```sh
nm -g libhal.a | rg sbrk
00000001 T _sbrk
```

Interesting we can see that the _sbrk() function is indeed present in the libhal.a library file.  So what is the issue then.  On the previous part of this project I didn't get a linker error when I compiled all of the source files in one executable.

In the previous step the linker command looked something like this.  Quite a few of the sources file were omitted for brevity.  The command below compiled and linked perfectly fine.

```sh
arm-none-eabi-gcc -g --specs=nosys.specs -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -T/home/jhamberg/src/embedded-cmake-course/04-07-programming-bin/STM32F446RETx_FLASH.ld -Wl,--gc-sections CMakeFiles/hello.dir/Core/Src/system_stm32f4xx.c.obj
...
CMakeFiles/hello.dir/Core/Src/syscalls.c.obj 
CMakeFiles/hello.dir/Drivers/STM32																																																																																																																														ffmpeg-rtmp-duplication (copy).md																																																																																																									F4xx_HAL_Driver/Src/stm32f4xx_hal.c.obj -o hello
```

Here was the linker command using the hal static library that didn't pass.

```sh
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -T/home/jhamberg/src/embedded-cmake-course/04-08-library-dependencies/STM32F446RETx_FLASH.ld --specs=nano.specs -Wl,--gc-sections CMakeFiles/hello.dir/Core/Src/main.c.obj -o hello  libhal.a 
```

But when we ran this command we still have the undefined reference to _sbrk() and others even though we clearly see libhal.a is being included, and that libhal.a has the _sbrk() function.  The answer to what is going on is located deep in the ld documentaion shown below.

```sh
-l namespec
--library=namespec
...
The linker will search an archive only once, at the location where it is specified on the command line.  If the
archive defines a symbol which was undefined in some object which appeared before the archive on the command
line, the linker will include the appropriate file(s) from the archive.  However, an undefined symbol in an
object appearing later on the command line will not cause the linker to search the archive again.
...
```

This says that the linker will only import symbols from the archive that are currently undefined.  The problem with the code is that our application was not using those functions defined in the syscalls.c.  This makes sense since those functions are provided for the C standard library to use during the final stage of the linker when we link against the nano specs implementation of the standard C library.  Again since our library never used those functions, there were no undefined references to _sbrk() so according to the ld documentation the functions were not imported into the next linker steps.  Whereas when we are linking object files individually, all of the symbols are imported by default regardless of if there the symbols are currently unresolved or simply missing.  This is the different between linking a bunch of object files together and linking against an archive of object files.

# Solution

The solution is to use a command that forces the linker to include all of the symbols from the archive, even if they are not currently used by the application.  This argument is called the --whole-archive and --no-whole-archive.  The whole-archive argument tells the linker that it should include all of the symbols in the remaining static library archives.  The no-whole-archive tells the linker to return to the default behavior for the remaining static library archives passed through the command line.

So in CMake we add the whole-archive and no-whole-archive into the link options like so.

```cmake
target_link_options(hal PUBLIC
        -mcpu=cortex-m4
        -mthumb -mfpu=fpv4-sp-d16
        -mfloat-abi=hard
        -T${CMAKE_SOURCE_DIR}/STM32F446RETx_FLASH.ld
        --specs=nano.specs
        -Wl,--whole-archive libhal.a -Wl,--no-whole-archive
        -Wl,--gc-sections
        )
```

This does result in adding the libhal.a twice during the linker step.  This is unavoidable at the moment because CMake does not provide a mechanism for setting individual static library link options.  The link options can only be specified at a global level. 

This problem caused me to rack my brains for days.  Because I could not figure out why it would not link against a function symbol that was obviously present in the static library I was trying to link against.  I'm glad someone hinted at this behavior in a StackOverflow post.  I would have struggled with this for many more days if they had not mentioned what was happening.

