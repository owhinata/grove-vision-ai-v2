# UART Hello World Application
cmake_minimum_required(VERSION 3.16)

# Setup development environment (submodules, toolchain, venv)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/setup.cmake)
grove_setup_all()

# Set toolchain before project()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/arm-none-eabi-gcc.cmake")

project(hello_world LANGUAGES C CXX ASM)

# SDK root path
set(SDK_ROOT "${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S")

# SDK configuration
set(SDK_BOARD "epii_evb")
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)
set(SDK_SEMIHOST OFF)
set(SDK_USE_FREERTOS OFF)

# Include SDK modules
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/device.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/board.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/interface.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/common.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/trustzone.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/library.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/linker.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/image.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/flash.cmake)

# =============================================================================
# Create SDK libraries
# =============================================================================

# Built from source
sdk_add_device_library(device)
sdk_add_board_library(board)
sdk_add_interface_library(interface)
sdk_add_common_library(common)
sdk_add_trustzone_cfg_library(trustzone_cfg)

# Interface libraries (for includes/defines, link prebuilt)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_driver_library(driver)

# =============================================================================
# Application
# =============================================================================

# Application sources
set(APP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/main.c
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK common settings to application
sdk_apply_common_settings(${PROJECT_NAME})

# =============================================================================
# Link libraries
# =============================================================================
# Use --start-group/--end-group to resolve circular dependencies

target_link_libraries(${PROJECT_NAME} PRIVATE
    # Interface libraries (for includes/defines propagation)
    pwrmgmt
    # Actual link group
    -Wl,--start-group
    board
    device
    interface
    common
    trustzone_cfg
    ${SDK_LIB_DRIVER_PREBUILT}
    ${SDK_LIB_PWRMGMT_PREBUILT}
    -lm -lc_nano -lgcc
    -Wl,--end-group
)

# =============================================================================
# Build artifacts
# =============================================================================

# Apply linker settings
sdk_apply_linker_settings(${PROJECT_NAME})

# Add image generation
sdk_add_image_generation(${PROJECT_NAME})

# Add flash target
sdk_add_flash_target(${PROJECT_NAME})

# =============================================================================
# Print configuration
# =============================================================================
message(STATUS "")
message(STATUS "=== Application Configuration ===")
message(STATUS "Application: ${PROJECT_NAME}")
message(STATUS "SDK Root: ${SDK_ROOT}")
message(STATUS "")
