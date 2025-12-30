# Device module for Grove Vision AI V2 SDK
# Provides core device initialization and startup code

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including device.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Device source directory
set(SDK_DEVICE_DIR ${SDK_ROOT}/device)

# Device sources (always included)
set(SDK_DEVICE_SOURCES
    ${SDK_DEVICE_DIR}/WE2_core.c
    ${SDK_DEVICE_DIR}/system_WE2_ARMCM55.c
    ${SDK_DEVICE_DIR}/startup_WE2_ARMCM55.cc
)

# C library support (non-semihosting)
if(NOT SDK_SEMIHOST)
    list(APPEND SDK_DEVICE_SOURCES
        ${SDK_DEVICE_DIR}/clib/console_io.c
        ${SDK_DEVICE_DIR}/clib/retarget.c
        ${SDK_DEVICE_DIR}/clib/gnu/retarget_io.c
    )

    # FreeRTOS support
    if(SDK_USE_FREERTOS AND (NOT SDK_TRUSTZONE OR SDK_TRUSTZONE_FW_TYPE EQUAL 1))
        list(APPEND SDK_DEVICE_SOURCES
            ${SDK_DEVICE_DIR}/clib/gnu/os/freertos/retarget_newlib.c
        )
    endif()

    # RTX support
    if(SDK_USE_RTX AND (NOT SDK_TRUSTZONE OR SDK_TRUSTZONE_FW_TYPE EQUAL 1))
        list(APPEND SDK_DEVICE_SOURCES
            ${SDK_DEVICE_DIR}/clib/gnu/os/rtx/retarget_newlib.c
        )
    endif()
endif()

# Device-specific include directories (in addition to SDK common includes)
set(SDK_DEVICE_INCLUDE_DIRS
    ${SDK_DEVICE_DIR}
    ${SDK_DEVICE_DIR}/inc
    ${SDK_DEVICE_DIR}/clib
)

# Create device library target
function(sdk_add_device_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_DEVICE_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add device-specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_DEVICE_INCLUDE_DIRS})
endfunction()
