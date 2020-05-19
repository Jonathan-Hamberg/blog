---
title: Added STM32F families to stm32-meson
subtitle:
date: 2020-03-30
tags: ["meson", "stm32", "c"]
draft: false
---

The [stm32-meson](https://gitlab.com/jhamberg/stm32-meson) project now supports more STM32 chips.  Previously the the project only supported STM32G0 family of ST microprocessors.  I've gone through and added support for STM32F0, STM32F1, STM32F2, STM32F3, and STM32F4 families.  In total 321 ST chips have been added in this update.

To build the stm32-blinky project run the following syntax.  The cross file must be specified which includes the proper arguments to supply to the Arm GCC compiler.  The cross file also contains a list of all the supported STM32 chips in the selected ST family.  The Cube directory must also be specified in order for stm32-meson to find all the HAL libraries.

```
cd stm32-meson
meson build --cross-file stm32-meson/stm32f1.build -Dstm32_chip=STM32F100RE -Dstm32_cube_dir=$HOME/STM32Cube/Repository/STM32Cube_FW_F1_V1.8.0
ninja -C build
```

I've also added tests to all the ST chips that have been added. This way it can be easily determined if any of the individual ST chip are broken with any of the other additions to the stm32-meson project.  The STM32 Cube HAL libraries have been hard coded to the default location used by STM32CubeMX software.

```sh
cd stm32-meson
sh scripts/test_all.sh
```

There is a slight disclaimer that the stm32-blink project may not work on all development boards.  I have not verified that the output GPIO and timer are connected to a LED on all the development boards.  The project in it's current state is more meant to be a boiler plate project to build upon for another project.

This project is meant to expedite STM32 development by being able to start from a preexisting project.

