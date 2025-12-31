# I2C Communication Library module for Grove Vision AI V2 SDK
# Ported from library/i2c_comm/i2c_comm.mk
#
# This module provides I2C communication functionality.
# Uses prebuilt library since source is not available.

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including i2c_comm.cmake")
endif()

# Directory paths
set(SDK_I2C_COMM_ROOT ${SDK_ROOT}/library/i2c_comm)

# Include directories
set(SDK_I2C_COMM_INCLUDE_DIRS
    ${SDK_I2C_COMM_ROOT}
)

# Prebuilt library path
set(SDK_I2C_COMM_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/lib_i2c_comm.a)

# Compile definitions
set(SDK_I2C_COMM_DEFINITIONS LIB_I2C_COMM)

# Function to create I2C communication library (interface, links prebuilt)
function(sdk_add_i2c_comm_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)

    # I2C Comm includes (INTERFACE - propagate to dependents)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_I2C_COMM_INCLUDE_DIRS})

    # I2C Comm definitions (INTERFACE - propagate to dependents)
    foreach(DEF ${SDK_I2C_COMM_DEFINITIONS})
        target_compile_definitions(${TARGET_NAME} INTERFACE ${DEF})
    endforeach()

    message(STATUS "I2C Comm: Using prebuilt library")
endfunction()

message(STATUS "I2C Comm module loaded")
