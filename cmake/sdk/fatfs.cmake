# FatFS Middleware module for Grove Vision AI V2 SDK
# Ported from middleware/fatfs/fatfs.mk
#
# This module provides FatFS file system middleware with configurable ports.
# Set SDK_FATFS_PORT_LIST to select ports (default: mmc_spi)
# Set SDK_FATFS_FFCONF_DIR to specify directory containing ffconf.h
#
# Available ports: mmc_spi, mmc_sdio, flash, ram

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including fatfs.cmake")
endif()

# Directory paths
set(SDK_FATFS_ROOT ${SDK_ROOT}/middleware/fatfs)

# Port selection (default: mmc_spi)
set(SDK_FATFS_PORT_LIST "mmc_spi" CACHE STRING "FatFS port list (semicolon-separated)")

# ffconf.h directory (app-specific configuration file)
set(SDK_FATFS_FFCONF_DIR "" CACHE PATH "Directory containing ffconf.h")

# Include directories
set(SDK_FATFS_INCLUDE_DIRS
    ${SDK_FATFS_ROOT}/source
)

# Add ffconf.h directory if specified
if(SDK_FATFS_FFCONF_DIR AND EXISTS "${SDK_FATFS_FFCONF_DIR}")
    list(APPEND SDK_FATFS_INCLUDE_DIRS ${SDK_FATFS_FFCONF_DIR})
endif()

# Core FatFS sources (from fatfs.mk lines 23-26)
set(SDK_FATFS_SOURCES
    ${SDK_FATFS_ROOT}/source/ff.c
    ${SDK_FATFS_ROOT}/source/ffsystem.c
    ${SDK_FATFS_ROOT}/source/ffunicode.c
    ${SDK_FATFS_ROOT}/source/diskio.c
)

# Base definitions
set(SDK_FATFS_DEFINITIONS MID_FATFS)

# Add port sources and definitions
foreach(PORT ${SDK_FATFS_PORT_LIST})
    set(PORT_DIR ${SDK_FATFS_ROOT}/port/${PORT})
    if(EXISTS ${PORT_DIR})
        # Add port include directory
        list(APPEND SDK_FATFS_INCLUDE_DIRS ${PORT_DIR})

        # Add port source files
        file(GLOB PORT_SOURCES "${PORT_DIR}/*.c")
        list(APPEND SDK_FATFS_SOURCES ${PORT_SOURCES})

        # Add port definition (FATFS_PORT_mmc_spi, etc.)
        list(APPEND SDK_FATFS_DEFINITIONS FATFS_PORT_${PORT})
    else()
        message(WARNING "FatFS port '${PORT}' not found at ${PORT_DIR}")
    endif()
endforeach()

# Function to create FatFS library
function(sdk_add_fatfs_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_FATFS_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # FatFS includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_FATFS_INCLUDE_DIRS})

    # FatFS definitions (PUBLIC - propagate to dependents)
    foreach(DEF ${SDK_FATFS_DEFINITIONS})
        target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
    endforeach()

    # Suppress warnings for FatFS code
    target_compile_options(${TARGET_NAME} PRIVATE
        -Wno-unused-parameter
    )

    list(LENGTH SDK_FATFS_SOURCES NUM_SOURCES)
    message(STATUS "FatFS: Building from source (${NUM_SOURCES} files, ports: ${SDK_FATFS_PORT_LIST})")
endfunction()

message(STATUS "FatFS module loaded (ports: ${SDK_FATFS_PORT_LIST})")
