# Allon JPEG Encode Application (No OS)
# Camera sensor with JPEG encoding and SPI output using event-driven model
cmake_minimum_required(VERSION 3.16)

# Setup development environment (submodules, toolchain, venv)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/setup.cmake)
grove_setup_all()

# Set toolchain before project()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/arm-none-eabi-gcc.cmake")

project(allon_jpeg_encode LANGUAGES C CXX ASM)

# SDK root path
set(SDK_ROOT "${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S")

# =============================================================================
# SDK configuration (from allon_jpeg_encode.mk)
# =============================================================================
set(SDK_BOARD "epii_evb")
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)  # Security Only
set(SDK_SEMIHOST OFF)
set(SDK_USE_FREERTOS OFF)  # No FreeRTOS - uses event handler

# FatFS configuration - use CACHE FORCE to override module defaults
set(SDK_FATFS_PORT_LIST "mmc_spi" CACHE STRING "FatFS port list" FORCE)
# ffconf.h is in the SDK app directory
set(SDK_FATFS_FFCONF_DIR "${SDK_ROOT}/app/scenario_app/allon_jpeg_encode" CACHE PATH "FatFS ffconf.h directory" FORCE)

# CMSIS Drivers configuration - use CACHE FORCE to override module defaults
set(SDK_CMSIS_DRIVERS_LIST "SPI" CACHE STRING "CMSIS Drivers list" FORCE)

# Event handler configuration
set(SDK_EVT_DATAPATH ON CACHE BOOL "Enable datapath event handling" FORCE)

# =============================================================================
# Library build options
# =============================================================================
option(SDK_CMSIS_NN_FORCE_PREBUILT "Use prebuilt CMSIS-NN library" OFF)

# CIS sensor model selection (default: cis_ov5647)
set(CIS_SENSOR_MODEL "cis_ov5647" CACHE STRING "Camera sensor model")
set_property(CACHE CIS_SENSOR_MODEL PROPERTY STRINGS
    cis_ov5647
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
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/fatfs.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_drivers.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_nn.cmake)
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
sdk_add_fatfs_library(fatfs)
sdk_add_cmsis_drivers_library(cmsis_drivers)

# Interface libraries (for includes/defines, link prebuilt)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_sensordp_library(sensordp)
sdk_add_spi_ptl_library(spi_ptl)
sdk_add_spi_eeprom_library(spi_eeprom)
sdk_add_extdevice_library(extdevice)
sdk_add_driver_library(driver)
sdk_add_tpgdp_library(tpgdp)

# CMSIS-NN library
if(NOT SDK_CMSIS_NN_FORCE_PREBUILT)
    sdk_add_cmsis_nn_library(cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

# =============================================================================
# Application configuration
# =============================================================================

# SDK scenario app source directory
set(SDK_APP_DIR ${SDK_ROOT}/app/scenario_app/allon_jpeg_encode)

# CIS sensor source directory (from SDK)
set(CIS_SENSOR_DIR ${SDK_APP_DIR}/cis_sensor/${CIS_SENSOR_MODEL})

# Application sources (from allon_jpeg_encode.mk)
set(APP_SOURCES
    ${SDK_ROOT}/app/main.c
    ${CMAKE_CURRENT_SOURCE_DIR}/allon_jpeg_encode.c  # Modified copy with SEND_IMAGE_SPI=1
    ${SDK_APP_DIR}/hardfault_handler.c
    ${SDK_APP_DIR}/spi_fatfs.c
    # CIS sensor sources (from SDK)
    ${CIS_SENSOR_DIR}/cisdp_sensor.c
    ${CIS_SENSOR_DIR}/buffer.c
    ${CIS_SENSOR_DIR}/jpegfilesize.c
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK common settings to application
sdk_apply_common_settings(${PROJECT_NAME})

# Application specific definitions (from allon_jpeg_encode.mk)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    ALLON_JPEG_ENCODE
    DBG_LESS
    HM_COMMON
    LIB_EVENT
    LIB_TPGDP
    LIB_QSPI_EEPROM
    SPI_EEPROM_USE_WB_25Q128JW_INST_
)

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
    # tpgdp library
    ${SDK_ROOT}/library/tpgdp
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
    fatfs
    cmsis_drivers
    # Prebuilt libraries
    ${SDK_LIB_DRIVER_PREBUILT}
    ${SDK_LIB_PWRMGMT_PREBUILT}
    ${SDK_LIB_SENSORDP_PREBUILT}
    ${SDK_LIB_EXTDEVICE_PREBUILT}
    ${SDK_LIB_SPI_PTL_PREBUILT}
    ${SDK_LIB_SPI_EEPROM_PREBUILT}
    ${SDK_LIB_TPGDP_PREBUILT}
    ${SDK_LIB_HXEVENT_PREBUILT}
    ${SDK_ROOT}/prebuilt_libs/gnu/libcustomer.a
)

# Add CMSIS-NN library
if(SDK_CMSIS_NN_FORCE_PREBUILT)
    list(APPEND LINK_LIBS_GROUP ${SDK_CMSIS_NN_PREBUILT})
else()
    list(APPEND LINK_LIBS_GROUP cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

# Interface library list for includes/defines propagation
set(INTERFACE_LIBS
    pwrmgmt
    sensordp
    spi_ptl
    spi_eeprom
    extdevice
    tpgdp
    event_handler
    fatfs
    cmsis_drivers
)
if(NOT SDK_CMSIS_NN_FORCE_PREBUILT)
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
    LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/allon_jpeg_encode.ld
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
message(STATUS "FatFS Ports: ${SDK_FATFS_PORT_LIST}")
message(STATUS "CMSIS Drivers: ${SDK_CMSIS_DRIVERS_LIST}")
message(STATUS "Event Handler: datapath=${SDK_EVT_DATAPATH}")
message(STATUS "CMSIS-NN: enabled (prebuilt: ${SDK_CMSIS_NN_FORCE_PREBUILT})")
message(STATUS "TrustZone: ${SDK_TRUSTZONE_TYPE} (FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
message(STATUS "")
