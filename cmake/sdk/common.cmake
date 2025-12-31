# Common library module for Grove Vision AI V2 SDK
# Builds libcommon.a containing xprintf

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including common.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Common library directory
set(SDK_COMMON_LIB_DIR ${SDK_ROOT}/library/common)

# Common library sources
set(SDK_COMMON_LIB_SOURCES
    ${SDK_COMMON_LIB_DIR}/xprintf.c
)

# Common library include directories
set(SDK_COMMON_LIB_INCLUDE_DIRS
    ${SDK_COMMON_LIB_DIR}
)

# Function to create common library target
function(sdk_add_common_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_COMMON_LIB_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add common library specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_COMMON_LIB_INCLUDE_DIRS})

    # Add common library specific definitions
    target_compile_definitions(${TARGET_NAME} PRIVATE LIB_COMMON)
endfunction()

message(STATUS "Common library module loaded")
