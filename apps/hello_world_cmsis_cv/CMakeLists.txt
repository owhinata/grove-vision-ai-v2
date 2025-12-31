# Hello World CMSIS-CV Application
# Based on SDK's hello_world_cmsis_cv scenario app
cmake_minimum_required(VERSION 3.16)

# Setup development environment (submodules, toolchain, venv)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/setup.cmake)
grove_setup_all()

# Set toolchain before project()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/arm-none-eabi-gcc.cmake")

project(hello_world_cmsis_cv LANGUAGES C CXX ASM)

# SDK root path
set(SDK_ROOT "${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S")

# =============================================================================
# SDK configuration (from hello_world_cmsis_cv.mk)
# =============================================================================
set(SDK_BOARD "epii_evb")
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)  # Security Only
set(SDK_SEMIHOST OFF)
set(SDK_USE_FREERTOS OFF)

# Event handler configuration (from hello_world_cmsis_cv.mk)
set(SDK_EVT_DATAPATH ON)

# Camera sensor configuration
set(CIS_SENSOR_MODEL "cis_imx219" CACHE STRING "Camera sensor model")
set_property(CACHE CIS_SENSOR_MODEL PROPERTY STRINGS
    "cis_imx219" "cis_imx477" "cis_imx708" "cis_ov5647" "cis_hm0360")

# =============================================================================
# Include SDK modules
# =============================================================================
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/device.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/board.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/interface.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/common.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/trustzone.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/event_handler.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/library.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_dsp.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_nn.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_cv.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/jpegenc.cmake)
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
sdk_add_event_handler_library(event_handler)

# CMSIS libraries from source
sdk_add_cmsis_dsp_library(cmsis_dsp)
sdk_add_cmsis_nn_library(cmsis_nn)
sdk_add_cmsis_cv_library(cmsis_cv)

# JPEGENC from source
sdk_add_jpegenc_library(jpegenc)

# Interface libraries (for includes/defines, link prebuilt)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_sensordp_library(sensordp)
sdk_add_spi_ptl_library(spi_ptl)
sdk_add_spi_eeprom_library(spi_eeprom)
sdk_add_hxevent_library(hxevent)
sdk_add_img_proc_library(img_proc)
sdk_add_driver_library(driver)

# =============================================================================
# Application configuration
# =============================================================================

# SDK scenario app source directory
set(SDK_APP_DIR ${SDK_ROOT}/app/scenario_app/hello_world_cmsis_cv)

# Camera sensor source directory
set(CIS_SENSOR_DIR ${SDK_APP_DIR}/cis_sensor/${CIS_SENSOR_MODEL})

# Application sources
set(APP_SOURCES
    ${SDK_ROOT}/app/main.c
    ${SDK_APP_DIR}/hello_world_cmsis_cv.c
    ${SDK_APP_DIR}/cvapp_hello_world_cmsis_cv.cpp
    ${SDK_APP_DIR}/send_result.cpp
    ${SDK_APP_DIR}/memory_manage.c
    ${SDK_APP_DIR}/hardfault_handler.c
    ${CIS_SENSOR_DIR}/cisdp_sensor.c
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK common settings to application
sdk_apply_common_settings(${PROJECT_NAME})

# Application specific definitions (from hello_world_cmsis_cv.mk)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    HELLO_WORLD_CMSIS_CV
    TF_LITE_STATIC_MEMORY
    audvidpre_ret_pll400_timer1
    UART_SEND_ALOGO_RESEULT
    DBG_MORE
    HM_COMMON
)

# Application include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SDK_APP_DIR}
    ${SDK_ROOT}/app
    ${SDK_ROOT}/app/scenario_app
    ${CIS_SENSOR_DIR}
    # External device support (CIS - Camera Image Sensor)
    ${SDK_ROOT}/external
    ${SDK_ROOT}/external/cis
    ${SDK_ROOT}/external/cis/hm_common
)

# =============================================================================
# Link libraries
# =============================================================================
# Use --start-group/--end-group to resolve circular dependencies

target_link_libraries(${PROJECT_NAME} PRIVATE
    # Interface libraries (for includes/defines propagation)
    pwrmgmt
    sensordp
    spi_ptl
    spi_eeprom
    hxevent
    img_proc
    cmsis_dsp
    cmsis_nn
    cmsis_cv
    jpegenc
    event_handler
    # Actual link group
    -Wl,--start-group
    board
    device
    interface
    common
    trustzone_cfg
    event_handler
    cmsis_dsp
    cmsis_nn
    cmsis_cv
    jpegenc
    ${SDK_LIB_DRIVER_PREBUILT}
    ${SDK_LIB_PWRMGMT_PREBUILT}
    ${SDK_LIB_SENSORDP_PREBUILT}
    ${SDK_LIB_SPI_PTL_PREBUILT}
    ${SDK_LIB_SPI_EEPROM_PREBUILT}
    ${SDK_LIB_HXEVENT_PREBUILT}
    ${SDK_LIB_IMG_PROC_PREBUILT}
    ${SDK_ROOT}/prebuilt_libs/gnu/libextdevice.a
    -lm -lc_nano -lgcc -lstdc++_nano
    -Wl,--end-group
)

# =============================================================================
# Build artifacts
# =============================================================================

# Apply linker settings (custom linker script for this app)
sdk_apply_linker_settings(${PROJECT_NAME}
    LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/TFLM_cmsis_cv_S_only.ld
)

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
message(STATUS "Camera Sensor: ${CIS_SENSOR_MODEL}")
message(STATUS "CMSIS-DSP: Building from source")
message(STATUS "CMSIS-NN: Building from source")
message(STATUS "CMSIS-CV: Building from source")
message(STATUS "JPEGENC: Building from source")
message(STATUS "TrustZone: ${SDK_TRUSTZONE_TYPE} (FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
message(STATUS "")
