# Allon Sensor TFLM with CMSIS-NN Application (No OS)
# Camera sensor with TensorFlow Lite Micro inference using event-driven model
# Uses TFLM version tflmtag2412_u55tag2411 with CMSIS-NN optimized kernels
cmake_minimum_required(VERSION 3.16)

# Setup development environment (submodules, toolchain, venv)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/setup.cmake)
grove_setup_all()

# Set toolchain before project()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/arm-none-eabi-gcc.cmake")

project(allon_sensor_tflm_cmsis_nn LANGUAGES C CXX ASM)

# SDK root path
set(SDK_ROOT "${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S")

# =============================================================================
# SDK configuration (from allon_sensor_tflm.mk)
# =============================================================================
set(SDK_BOARD "epii_evb")
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)  # Security Only
set(SDK_SEMIHOST OFF)
set(SDK_USE_FREERTOS OFF)  # No FreeRTOS - uses event handler

# Event handler configuration
set(SDK_EVT_DATAPATH ON CACHE BOOL "Enable datapath event handling" FORCE)

# TFLM configuration - use tflmtag2412_u55tag2411 version
set(SDK_TFLM_VERSION "tflmtag2412_u55tag2411" CACHE STRING "TFLM version" FORCE)

# =============================================================================
# Library build options
# =============================================================================
option(SDK_TFLM_FORCE_PREBUILT "Use prebuilt TFLM library" OFF)
option(SDK_CMSIS_NN_FORCE_PREBUILT "Use prebuilt CMSIS-NN library" OFF)
option(SDK_TFLM_USE_CMSIS_NN "Use CMSIS-NN optimized TFLM kernels" ON)

# CIS sensor model selection
set(CIS_SENSOR_MODEL "cis_imx219" CACHE STRING "Camera sensor model")
set_property(CACHE CIS_SENSOR_MODEL PROPERTY STRINGS
    cis_hm0360
    cis_ov5647
    cis_imx219
    cis_imx477
    cis_imx708
)

# =============================================================================
# Include SDK modules
# =============================================================================
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/device.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/board.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/interface.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/common.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/trustzone.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/library.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/event_handler.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_nn.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/tflm.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/linker.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/image.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/flash.cmake)

# =============================================================================
# Create SDK libraries
# =============================================================================

# Always built from source
sdk_add_device_library(device)
sdk_add_board_library(board)
sdk_add_interface_library(interface)
sdk_add_common_library(common)
sdk_add_trustzone_cfg_library(trustzone_cfg)
sdk_add_event_handler_library(event_handler)

# Interface libraries (for includes/defines, link prebuilt)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_sensordp_library(sensordp)
sdk_add_spi_ptl_library(spi_ptl)
sdk_add_spi_eeprom_library(spi_eeprom)
sdk_add_extdevice_library(extdevice)
sdk_add_driver_library(driver)

# Libraries with source build support
sdk_add_tflm_library(tflm_lib)

# CMSIS-NN library (built from source when SDK_TFLM_USE_CMSIS_NN=ON)
if(SDK_TFLM_USE_CMSIS_NN AND NOT SDK_CMSIS_NN_FORCE_PREBUILT)
    sdk_add_cmsis_nn_library(cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

# =============================================================================
# Application configuration
# =============================================================================

# SDK scenario app source directory
set(SDK_APP_DIR ${SDK_ROOT}/app/scenario_app/allon_sensor_tflm_cmsis_nn)

# CIS sensor source directory (from SDK)
set(CIS_SENSOR_DIR ${SDK_APP_DIR}/cis_sensor/${CIS_SENSOR_MODEL})

# Application sources (from allon_sensor_tflm.mk)
set(APP_SOURCES
    ${SDK_ROOT}/app/main.c
    ${SDK_APP_DIR}/allon_sensor_tflm.c
    ${SDK_APP_DIR}/hardfault_handler.c
    ${SDK_APP_DIR}/cvapp.cpp
    ${SDK_APP_DIR}/person_detect_model_data.cc
    # CIS sensor sources (from SDK)
    ${CIS_SENSOR_DIR}/cisdp_sensor.c
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK common settings to application
sdk_apply_common_settings(${PROJECT_NAME})

# Application specific definitions (from allon_sensor_tflm.mk)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    ALLON_SENSOR_TFLM
    DBG_MORE
    HM_COMMON
    LIB_EVENT
)

# Add CIS_IMX define for IMX sensors
if(CIS_SENSOR_MODEL MATCHES "cis_imx.*")
    target_compile_definitions(${PROJECT_NAME} PRIVATE CIS_IMX)
endif()

# Application include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SDK_APP_DIR}
    ${CIS_SENSOR_DIR}
    ${SDK_ROOT}/app
    ${SDK_ROOT}/app/scenario_app
    # External device support (CIS)
    ${SDK_ROOT}/external
    ${SDK_ROOT}/external/cis
    ${SDK_ROOT}/external/cis/hm_common
    # hxevent library
    ${SDK_ROOT}/library/hxevent
)

# =============================================================================
# Link libraries
# =============================================================================
# Use --start-group/--end-group to resolve circular dependencies

# Prebuilt hxevent library path
set(SDK_LIB_HXEVENT_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/libhxevent.a)

# Build list of libraries for --start-group block
set(LINK_LIBS_GROUP
    # Built from source
    board
    device
    interface
    common
    trustzone_cfg
    event_handler
    # Prebuilt libraries
    ${SDK_LIB_DRIVER_PREBUILT}
    ${SDK_LIB_PWRMGMT_PREBUILT}
    ${SDK_LIB_SENSORDP_PREBUILT}
    ${SDK_LIB_EXTDEVICE_PREBUILT}
    ${SDK_LIB_SPI_PTL_PREBUILT}
    ${SDK_LIB_SPI_EEPROM_PREBUILT}
    ${SDK_LIB_HXEVENT_PREBUILT}
    ${SDK_ROOT}/prebuilt_libs/gnu/libcustomer.a
)

# Add TFLM and CMSIS-NN libraries
if(SDK_TFLM_FORCE_PREBUILT)
    list(APPEND LINK_LIBS_GROUP ${SDK_TFLM_PREBUILT})
    if(SDK_TFLM_USE_CMSIS_NN AND SDK_CMSIS_NN_FORCE_PREBUILT)
        list(APPEND LINK_LIBS_GROUP ${SDK_CMSIS_NN_PREBUILT})
    endif()
else()
    list(APPEND LINK_LIBS_GROUP tflm_lib)
    if(SDK_TFLM_USE_CMSIS_NN)
        if(SDK_CMSIS_NN_FORCE_PREBUILT)
            list(APPEND LINK_LIBS_GROUP ${SDK_CMSIS_NN_PREBUILT})
        else()
            list(APPEND LINK_LIBS_GROUP cmsis_nn_${SDK_CMSIS_NN_VERSION})
        endif()
    endif()
endif()

# Interface library list for includes/defines propagation
set(INTERFACE_LIBS
    pwrmgmt
    sensordp
    spi_ptl
    spi_eeprom
    extdevice
    event_handler
    tflm_lib
)
if(SDK_TFLM_USE_CMSIS_NN AND NOT SDK_CMSIS_NN_FORCE_PREBUILT AND NOT SDK_TFLM_FORCE_PREBUILT)
    list(APPEND INTERFACE_LIBS cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
    # Interface libraries (for includes/defines propagation)
    ${INTERFACE_LIBS}
    # Actual link group
    -Wl,--start-group
    ${LINK_LIBS_GROUP}
    -lm -lc_nano -lgcc -lstdc++_nano
    -Wl,--end-group
)

# =============================================================================
# Build artifacts
# =============================================================================

# Apply linker settings (custom linker script for this app)
sdk_apply_linker_settings(${PROJECT_NAME}
    LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/allon_sensor_tflm.ld
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
message(STATUS "CIS Sensor: ${CIS_SENSOR_MODEL}")
message(STATUS "Event Handler: datapath=${SDK_EVT_DATAPATH}")
message(STATUS "TFLM: ${SDK_TFLM_VERSION} (prebuilt: ${SDK_TFLM_FORCE_PREBUILT})")
message(STATUS "CMSIS-NN: ${SDK_TFLM_USE_CMSIS_NN} (prebuilt: ${SDK_CMSIS_NN_FORCE_PREBUILT})")
message(STATUS "TrustZone: ${SDK_TRUSTZONE_TYPE} (FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
message(STATUS "")
