# Board module for Grove Vision AI V2 SDK
# Provides board-specific initialization code

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including board.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Board directory
set(SDK_BOARD_DIR ${SDK_ROOT}/board/${SDK_BOARD})

# Board sources
set(SDK_BOARD_SOURCES
    ${SDK_BOARD_DIR}/board.c
    ${SDK_BOARD_DIR}/pinmux_init.c
    ${SDK_BOARD_DIR}/platform_driver_init.c
)

# Board include directories
set(SDK_BOARD_INCLUDE_DIRS
    ${SDK_ROOT}/board
    ${SDK_BOARD_DIR}
    ${SDK_BOARD_DIR}/config
)

# Board-specific definitions
set(SDK_BOARD_DEFINITIONS "")
if(SDK_BOARD STREQUAL "epii_evb")
    list(APPEND SDK_BOARD_DEFINITIONS EPII_EVB)
endif()

# LIB_COMMON enables xprintf support in board.c
list(APPEND SDK_BOARD_DEFINITIONS LIB_COMMON)

# Create board library target
function(sdk_add_board_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_BOARD_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add board-specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_BOARD_INCLUDE_DIRS})

    # Add board-specific definitions
    target_compile_definitions(${TARGET_NAME} PRIVATE ${SDK_BOARD_DEFINITIONS})
endfunction()
