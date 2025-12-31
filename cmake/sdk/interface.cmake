# Interface module for Grove Vision AI V2 SDK
# Provides driver interface abstraction
#
# This module creates a library with PUBLIC includes that
# automatically propagate to any target that links against it.
# Depends on: device

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including interface.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/device.cmake)

# Interface source directory
set(SDK_INTERFACE_DIR ${SDK_ROOT}/interface)

# Interface include directories (PUBLIC - propagate to dependents)
set(SDK_INTERFACE_INCLUDE_DIRS
    ${SDK_INTERFACE_DIR}
)

# Interface sources
set(SDK_INTERFACE_SOURCES
    ${SDK_INTERFACE_DIR}/driver_interface.c
    ${SDK_INTERFACE_DIR}/timer_interface.c
)

# Create interface library target
function(sdk_add_interface_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_INTERFACE_SOURCES})

    # Apply SDK common settings (temporary - will be removed as we modularize)
    sdk_apply_common_settings(${TARGET_NAME})

    # Link against device (inherits device includes and defines)
    target_link_libraries(${TARGET_NAME} PUBLIC device)

    # Interface-specific includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC
        ${SDK_INTERFACE_INCLUDE_DIRS}
    )
endfunction()
