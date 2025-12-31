# CMSIS Drivers module for Grove Vision AI V2 SDK
# Ported from cmsis_drivers/cmsis_drivers.mk
#
# This module provides CMSIS-compliant drivers (SPI, I2C, etc.)
# Set SDK_CMSIS_DRIVERS_LIST to select drivers (e.g., "SPI")

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including cmsis_drivers.cmake")
endif()

# Include drivers module for IP_INST_* definitions (required by SPI driver)
include(${CMAKE_CURRENT_LIST_DIR}/drivers.cmake)

# Directory paths
set(SDK_CMSIS_DRIVERS_ROOT ${SDK_ROOT}/cmsis_drivers)

# Driver selection
set(SDK_CMSIS_DRIVERS_LIST "" CACHE STRING "CMSIS Drivers list (semicolon-separated, e.g., SPI)")

# Include directories
set(SDK_CMSIS_DRIVERS_INCLUDE_DIRS
    ${SDK_ROOT}/CMSIS/Driver/Include
)

# Collect driver sources
set(SDK_CMSIS_DRIVERS_SOURCES "")
set(SDK_CMSIS_DRIVERS_DEFINITIONS "")

foreach(DRIVER ${SDK_CMSIS_DRIVERS_LIST})
    set(DRIVER_DIR ${SDK_CMSIS_DRIVERS_ROOT}/${DRIVER})
    if(EXISTS ${DRIVER_DIR})
        # Add driver include directory
        list(APPEND SDK_CMSIS_DRIVERS_INCLUDE_DIRS ${DRIVER_DIR})

        # Add driver source files
        file(GLOB DRIVER_SOURCES "${DRIVER_DIR}/*.c")
        list(APPEND SDK_CMSIS_DRIVERS_SOURCES ${DRIVER_SOURCES})

        # Add driver definition (CMSIS_DRIVERS_SPI, etc.)
        list(APPEND SDK_CMSIS_DRIVERS_DEFINITIONS CMSIS_DRIVERS_${DRIVER})
    else()
        message(WARNING "CMSIS Driver '${DRIVER}' not found at ${DRIVER_DIR}")
    endif()
endforeach()

# Function to create CMSIS Drivers library
function(sdk_add_cmsis_drivers_library TARGET_NAME)
    if(NOT SDK_CMSIS_DRIVERS_SOURCES)
        message(STATUS "CMSIS Drivers: No drivers selected, creating interface library")
        add_library(${TARGET_NAME} INTERFACE)
        target_include_directories(${TARGET_NAME} INTERFACE ${SDK_CMSIS_DRIVERS_INCLUDE_DIRS})
        return()
    endif()

    add_library(${TARGET_NAME} STATIC ${SDK_CMSIS_DRIVERS_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Link to drivers_interface for IP_INST_* definitions (required by SPI driver)
    target_link_libraries(${TARGET_NAME} PRIVATE drivers_interface)

    # CMSIS Drivers includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_CMSIS_DRIVERS_INCLUDE_DIRS})

    # CMSIS Drivers definitions (PUBLIC - propagate to dependents)
    foreach(DEF ${SDK_CMSIS_DRIVERS_DEFINITIONS})
        target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
    endforeach()

    # Suppress warnings for CMSIS Drivers code
    target_compile_options(${TARGET_NAME} PRIVATE
        -Wno-unused-parameter
    )

    list(LENGTH SDK_CMSIS_DRIVERS_SOURCES NUM_SOURCES)
    message(STATUS "CMSIS Drivers: Building from source (${NUM_SOURCES} files, drivers: ${SDK_CMSIS_DRIVERS_LIST})")
endfunction()

message(STATUS "CMSIS Drivers module loaded (drivers: ${SDK_CMSIS_DRIVERS_LIST})")
