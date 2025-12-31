# CMSIS Core module for Grove Vision AI V2 SDK
# Provides CMSIS core headers and fundamental compiler defines
#
# This is the base module that most other SDK modules depend on.
# It creates an INTERFACE library that propagates includes and defines
# to any target that links against it.

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including cmsis_core.cmake")
endif()

# ARM core configuration
set(SDK_ARM_CORE "CM55" CACHE STRING "ARM Cortex-M core type")
set(SDK_CORTEX_M "55" CACHE STRING "Cortex-M version number")

# Create CMSIS core interface library (only once)
if(NOT TARGET cmsis_core)
    add_library(cmsis_core INTERFACE)

    # CMSIS core include directories
    target_include_directories(cmsis_core INTERFACE
        ${SDK_ROOT}/CMSIS
        ${SDK_ROOT}/CMSIS/Driver/Include
    )

    # Fundamental compiler defines that almost everything needs
    target_compile_definitions(cmsis_core INTERFACE
        # Compiler identification
        __GNU__
        __NEWLIB__
        # ARM core identification
        ARMCM${SDK_CORTEX_M}
        CM55_BIG
    )

    message(STATUS "CMSIS Core: ARM Cortex-M${SDK_CORTEX_M}")
endif()
