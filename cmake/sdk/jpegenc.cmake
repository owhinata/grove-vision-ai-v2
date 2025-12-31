# JPEGENC Library module for Grove Vision AI V2 SDK
# Ported from library/JPEGENC/JPEGENC.mk
#
# This module provides JPEG encoding functionality.
#
# Depends on: cmsis_core (for basic definitions)

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including jpegenc.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)

# Directory paths
set(SDK_JPEGENC_ROOT ${SDK_ROOT}/library/JPEGENC)

# Include directories
set(SDK_JPEGENC_INCLUDE_DIRS
    ${SDK_JPEGENC_ROOT}
)

# Source files (from JPEGENC.mk)
set(SDK_JPEGENC_SOURCES
    ${SDK_JPEGENC_ROOT}/JPEGENC.cpp
)

# Compile definitions (from JPEGENC.mk line 24)
set(SDK_JPEGENC_DEFINITIONS
    LIB_JPEGENC
)

# Function to create JPEGENC library
function(sdk_add_jpegenc_library TARGET_NAME)
    # Build from source (C++ source)
    add_library(${TARGET_NAME} STATIC ${SDK_JPEGENC_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Link against cmsis_core (inherits CMSIS includes and defines)
    target_link_libraries(${TARGET_NAME} PUBLIC cmsis_core)

    # JPEGENC includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_JPEGENC_INCLUDE_DIRS})

    # JPEGENC definitions (PUBLIC - propagate to dependents)
    foreach(DEF ${SDK_JPEGENC_DEFINITIONS})
        target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
    endforeach()

    message(STATUS "JPEGENC: Building from source")
endfunction()

message(STATUS "JPEGENC module loaded")
