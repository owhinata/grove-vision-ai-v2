# Board module for Grove Vision AI V2 SDK
# Provides board-specific initialization code
#
# This module creates a library with PUBLIC includes/defines that
# automatically propagate to any target that links against it.
# Depends on: device

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including board.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/device.cmake)

# Board directory
set(SDK_BOARD_DIR ${SDK_ROOT}/board/${SDK_BOARD})

# Board include directories (PUBLIC - propagate to dependents)
set(SDK_BOARD_INCLUDE_DIRS
    ${SDK_ROOT}/board
    ${SDK_BOARD_DIR}
    ${SDK_BOARD_DIR}/config
    ${SDK_ROOT}/customer/sec_inc/seeed
)

# Board compile definitions (PUBLIC - propagate to dependents)
set(SDK_BOARD_DEFINITIONS
    seeed
)
if(SDK_BOARD STREQUAL "epii_evb")
    list(APPEND SDK_BOARD_DEFINITIONS EPII_EVB)
endif()

# Board sources
set(SDK_BOARD_SOURCES
    ${SDK_BOARD_DIR}/board.c
    ${SDK_BOARD_DIR}/pinmux_init.c
    ${SDK_BOARD_DIR}/platform_driver_init.c
)

# Create board library target
function(sdk_add_board_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_BOARD_SOURCES})

    # Apply SDK common settings (temporary - will be removed as we modularize)
    sdk_apply_common_settings(${TARGET_NAME})

    # Link against device (inherits device includes and defines)
    target_link_libraries(${TARGET_NAME} PUBLIC device)

    # Board-specific includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC
        ${SDK_BOARD_INCLUDE_DIRS}
    )

    # Board-specific defines (PUBLIC - propagate to dependents)
    target_compile_definitions(${TARGET_NAME} PUBLIC
        ${SDK_BOARD_DEFINITIONS}
    )

    # LIB_COMMON enables xprintf support in board.c (PRIVATE - only for this target)
    target_compile_definitions(${TARGET_NAME} PRIVATE LIB_COMMON)
endfunction()
