# Interface module for Grove Vision AI V2 SDK
# Provides driver interface abstraction

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including interface.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Interface source directory
set(SDK_INTERFACE_DIR ${SDK_ROOT}/interface)

# Interface sources
set(SDK_INTERFACE_SOURCES
    ${SDK_INTERFACE_DIR}/driver_interface.c
    ${SDK_INTERFACE_DIR}/timer_interface.c
)

# Interface include directories
set(SDK_INTERFACE_INCLUDE_DIRS
    ${SDK_INTERFACE_DIR}
)

# Create interface library target
function(sdk_add_interface_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_INTERFACE_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add interface-specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_INTERFACE_INCLUDE_DIRS})
endfunction()
