# SDK Library module for Grove Vision AI V2
# Ported from library/library.mk
#
# This module provides interface libraries for SDK components.
# Most libraries are header-only with prebuilt .a files.
# Only libcommon.a is built from source (xprintf.c).
#
# Libraries provided:
# - sdk_common: xprintf (built from source)
# - sdk_pwrmgmt: Power management (prebuilt)
# - sdk_hxevent: Event handling (prebuilt)
# - sdk_sensordp: Sensor datapath (prebuilt)
# - sdk_spi_ptl: SPI protocol (prebuilt)
# - sdk_spi_eeprom: SPI EEPROM (prebuilt)
# - sdk_extdevice: External device (prebuilt)
# - sdk_driver: Core driver (prebuilt)

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including library.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Library root directory
set(SDK_LIBRARY_ROOT ${SDK_ROOT}/library)
set(SDK_PREBUILT_DIR ${SDK_ROOT}/prebuilt_libs/gnu)

# =============================================================================
# Common Library (libcommon.a) - Built from source
# From: library/common/common.mk
# Contains: xprintf (formatted printing)
# =============================================================================

set(SDK_LIB_COMMON_DIR ${SDK_LIBRARY_ROOT}/common)
set(SDK_LIB_COMMON_SOURCES
    ${SDK_LIB_COMMON_DIR}/xprintf.c
)
set(SDK_LIB_COMMON_INCLUDE_DIRS
    ${SDK_LIB_COMMON_DIR}
)

function(sdk_add_common_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_LIB_COMMON_SOURCES})
    sdk_apply_common_settings(${TARGET_NAME})
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_LIB_COMMON_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} PUBLIC LIB_COMMON)
endfunction()

# =============================================================================
# Power Management Library (libpwrmgmt.a) - Prebuilt
# From: library/pwrmgmt/pwrmgmt.mk
# Contains: Power mode control, sleep/wake management
# =============================================================================

set(SDK_LIB_PWRMGMT_DIR ${SDK_LIBRARY_ROOT}/pwrmgmt)
set(SDK_LIB_PWRMGMT_INCLUDE_DIRS
    ${SDK_LIB_PWRMGMT_DIR}
    ${SDK_LIB_PWRMGMT_DIR}/seconly_inc
)
set(SDK_LIB_PWRMGMT_PREBUILT ${SDK_PREBUILT_DIR}/libpwrmgmt.a)

function(sdk_add_pwrmgmt_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_PWRMGMT_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_PWRMGMT)
    # Note: Use SDK_LIB_PWRMGMT_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# HX Event Library (libhxevent.a) - Prebuilt
# From: library/hxevent/hxevent.mk
# Contains: Event handling framework
# =============================================================================

set(SDK_LIB_HXEVENT_DIR ${SDK_LIBRARY_ROOT}/hxevent)
set(SDK_LIB_HXEVENT_INCLUDE_DIRS
    ${SDK_LIB_HXEVENT_DIR}
)
set(SDK_LIB_HXEVENT_PREBUILT ${SDK_PREBUILT_DIR}/libhxevent.a)

function(sdk_add_hxevent_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_HXEVENT_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_EVENT)
    # Note: Use SDK_LIB_HXEVENT_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# Sensor Datapath Library (libsensordp.a) - Prebuilt
# From: library/sensordp/sensordp.mk
# Contains: Camera sensor datapath control
# =============================================================================

set(SDK_LIB_SENSORDP_DIR ${SDK_LIBRARY_ROOT}/sensordp)
set(SDK_LIB_SENSORDP_INCLUDE_DIRS
    ${SDK_LIB_SENSORDP_DIR}/inc
    ${SDK_LIB_SENSORDP_DIR}/internal_inc
)
set(SDK_LIB_SENSORDP_PREBUILT ${SDK_PREBUILT_DIR}/libsensordp.a)

function(sdk_add_sensordp_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_SENSORDP_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_SENSORDP)
    # Note: Use SDK_LIB_SENSORDP_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# SPI Protocol Library (lib_spi_ptl.a) - Prebuilt
# From: library/spi_ptl/spi_ptl.mk
# Contains: SPI master/slave protocol
# =============================================================================

set(SDK_LIB_SPI_PTL_DIR ${SDK_LIBRARY_ROOT}/spi_ptl)
set(SDK_LIB_SPI_PTL_INCLUDE_DIRS
    ${SDK_LIB_SPI_PTL_DIR}
)
set(SDK_LIB_SPI_PTL_PREBUILT ${SDK_PREBUILT_DIR}/lib_spi_ptl.a)

function(sdk_add_spi_ptl_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_SPI_PTL_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_SPI_PTL)
    # Note: Use SDK_LIB_SPI_PTL_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# SPI EEPROM Library (lib_spi_eeprom.a) - Prebuilt
# From: library/spi_eeprom/spi_eeprom.mk
# Contains: SPI flash/EEPROM interface
# Configuration: Flash model selection (default: WB_25Q128JW)
# =============================================================================

set(SDK_LIB_SPI_EEPROM_DIR ${SDK_LIBRARY_ROOT}/spi_eeprom)
set(SDK_LIB_SPI_EEPROM_INCLUDE_DIRS
    ${SDK_LIB_SPI_EEPROM_DIR}
    ${SDK_LIB_SPI_EEPROM_DIR}/eeprom_param
)
set(SDK_LIB_SPI_EEPROM_PREBUILT ${SDK_PREBUILT_DIR}/lib_spi_eeprom.a)

# Flash model selection (from spi_eeprom.mk)
set(SDK_FLASH_MODEL "WB_25Q128JW" CACHE STRING "SPI Flash model")
set_property(CACHE SDK_FLASH_MODEL PROPERTY STRINGS
    WB_25Q128JW WB_25Q64JW WB_25Q32JW WB_25Q16JW
    MX_25U12843 MX_25U6432 MX_25U3232 MX_25U1632
    GD_25LQ128 GD_25LQ64 GD_25LQ32 GD_25LQ16
    USER_DEFINE
)

function(sdk_add_spi_eeprom_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_SPI_EEPROM_INCLUDE_DIRS})
    target_compile_definitions(${TARGET_NAME} INTERFACE
        LIB_SPI_EEPROM
        LIB_QSPI_EEPROM
        SPI_EEPROM_USE_${SDK_FLASH_MODEL}_INST_
    )
    # Note: Use SDK_LIB_SPI_EEPROM_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# External Device Library (libextdevice.a) - Prebuilt
# Contains: External device drivers (CIS sensors, etc.)
# =============================================================================

set(SDK_LIB_EXTDEVICE_PREBUILT ${SDK_PREBUILT_DIR}/libextdevice.a)
set(SDK_LIB_EXTDEVICE_INCLUDE_DIRS
    ${SDK_ROOT}/external
    ${SDK_ROOT}/external/cis
    ${SDK_ROOT}/external/cis/hm_common
    ${SDK_ROOT}/external/inc
)

function(sdk_add_extdevice_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_EXTDEVICE_INCLUDE_DIRS})
    # Note: Use SDK_LIB_EXTDEVICE_PREBUILT directly in --start-group link block
endfunction()

# =============================================================================
# Core Driver Library (libdriver.a) - Prebuilt
# Contains: Low-level peripheral drivers
# =============================================================================

set(SDK_LIB_DRIVER_PREBUILT ${SDK_PREBUILT_DIR}/libdriver.a)

function(sdk_add_driver_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    # Note: Don't link here - use SDK_LIB_DRIVER_PREBUILT directly in link group
endfunction()

# =============================================================================
# I2C Communication Library (lib_i2c_comm.a) - Prebuilt
# From: library/i2c_comm/i2c_comm.mk
# =============================================================================

set(SDK_LIB_I2C_COMM_DIR ${SDK_LIBRARY_ROOT}/i2c_comm)
set(SDK_LIB_I2C_COMM_PREBUILT ${SDK_PREBUILT_DIR}/lib_i2c_comm.a)

function(sdk_add_i2c_comm_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_I2C_COMM_DIR})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_I2C_COMM)
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_I2C_COMM_PREBUILT})
endfunction()

# =============================================================================
# Audio Library (libaudio.a) - Prebuilt
# =============================================================================

set(SDK_LIB_AUDIO_DIR ${SDK_LIBRARY_ROOT}/audio)
set(SDK_LIB_AUDIO_PREBUILT ${SDK_PREBUILT_DIR}/libaudio.a)

function(sdk_add_audio_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_AUDIO_DIR})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_AUDIO)
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_AUDIO_PREBUILT})
endfunction()

# =============================================================================
# HX Mailbox Library (libhxmb.a) - Prebuilt
# =============================================================================

set(SDK_LIB_HXMB_DIR ${SDK_LIBRARY_ROOT}/hxmb)
set(SDK_LIB_HXMB_PREBUILT ${SDK_PREBUILT_DIR}/libhxmb.a)

function(sdk_add_hxmb_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_HXMB_DIR})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_HXMB)
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_HXMB_PREBUILT})
endfunction()

# =============================================================================
# TPGDP Library (libtpgdp.a) - Prebuilt
# =============================================================================

set(SDK_LIB_TPGDP_DIR ${SDK_LIBRARY_ROOT}/tpgdp)
set(SDK_LIB_TPGDP_PREBUILT ${SDK_PREBUILT_DIR}/libtpgdp.a)

function(sdk_add_tpgdp_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_TPGDP_DIR})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_TPGDP)
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_TPGDP_PREBUILT})
endfunction()

# =============================================================================
# Image Processing Library (lib_img_proc.a) - Prebuilt
# =============================================================================

set(SDK_LIB_IMG_PROC_DIR ${SDK_LIBRARY_ROOT}/img_proc)
set(SDK_LIB_IMG_PROC_PREBUILT ${SDK_PREBUILT_DIR}/lib_img_proc.a)

function(sdk_add_img_proc_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_IMG_PROC_DIR})
    target_compile_definitions(${TARGET_NAME} INTERFACE LIB_IMG_PROC)
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_IMG_PROC_PREBUILT})
endfunction()

# =============================================================================
# CMSIS-NN Library (lib_cmsis_nn.a) - Prebuilt
# From: library/cmsis_nn/cmsis_nn.mk
# =============================================================================

set(SDK_LIB_CMSIS_NN_DIR ${SDK_LIBRARY_ROOT}/cmsis_nn)
set(SDK_LIB_CMSIS_NN_PREBUILT ${SDK_PREBUILT_DIR}/lib_cmsis_nn.a)
set(SDK_LIB_CMSIS_NN_7_0_0_PREBUILT ${SDK_PREBUILT_DIR}/lib_cmsis_nn_7_0_0.a)

function(sdk_add_cmsis_nn_library TARGET_NAME)
    cmake_parse_arguments(ARG "" "VERSION" "" ${ARGN})
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_CMSIS_NN_DIR})
    if(ARG_VERSION STREQUAL "7_0_0")
        target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_CMSIS_NN_7_0_0_PREBUILT})
    else()
        target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_CMSIS_NN_PREBUILT})
    endif()
endfunction()

# =============================================================================
# CMSIS-DSP Library (lib_cmsis_dsp.a) - Prebuilt
# =============================================================================

set(SDK_LIB_CMSIS_DSP_DIR ${SDK_LIBRARY_ROOT}/cmsis_dsp)
set(SDK_LIB_CMSIS_DSP_PREBUILT ${SDK_PREBUILT_DIR}/lib_cmsis_dsp.a)

function(sdk_add_cmsis_dsp_library TARGET_NAME)
    add_library(${TARGET_NAME} INTERFACE)
    target_include_directories(${TARGET_NAME} INTERFACE ${SDK_LIB_CMSIS_DSP_DIR})
    target_link_libraries(${TARGET_NAME} INTERFACE ${SDK_LIB_CMSIS_DSP_PREBUILT})
endfunction()

# =============================================================================
# TensorFlow Lite Micro Library - Prebuilt
# From: library/inference/tflmtag2209_u55tag2205/
# =============================================================================

# TFLM versions available
set(SDK_TFLM_VERSION "tflmtag2209_u55tag2205" CACHE STRING "TFLM library version")
set_property(CACHE SDK_TFLM_VERSION PROPERTY STRINGS
    tflmtag2209_u55tag2205
    tflmtag2412_u55tag2411
)

# TFLM with or without CMSIS-NN
option(SDK_TFLM_USE_CMSIS_NN "Use CMSIS-NN optimized TFLM" OFF)

function(sdk_add_tflm_library TARGET_NAME)
    set(TFLM_DIR ${SDK_LIBRARY_ROOT}/inference/${SDK_TFLM_VERSION})

    add_library(${TARGET_NAME} INTERFACE)

    target_include_directories(${TARGET_NAME} INTERFACE
        ${TFLM_DIR}
        ${TFLM_DIR}/third_party/ethos_u_core_driver/include
        ${TFLM_DIR}/third_party/flatbuffers/include
        ${TFLM_DIR}/third_party/gemmlowp
        ${TFLM_DIR}/third_party/ruy
    )

    # Note: Link the prebuilt library directly in --start-group link block
    # Use SDK_PREBUILT_DIR/lib${SDK_TFLM_VERSION}_gnu.a or _cmsisnn_gnu.a
endfunction()

# =============================================================================
# Convenience function to create all standard SDK libraries
# =============================================================================

function(sdk_create_all_libraries)
    # Always required
    sdk_add_common_library(sdk_common)
    sdk_add_driver_library(sdk_driver)

    # Optional libraries (created on demand)
    sdk_add_pwrmgmt_library(sdk_pwrmgmt)
    sdk_add_hxevent_library(sdk_hxevent)
    sdk_add_sensordp_library(sdk_sensordp)
    sdk_add_spi_ptl_library(sdk_spi_ptl)
    sdk_add_spi_eeprom_library(sdk_spi_eeprom)
    sdk_add_extdevice_library(sdk_extdevice)
    sdk_add_i2c_comm_library(sdk_i2c_comm)
    sdk_add_audio_library(sdk_audio)
    sdk_add_hxmb_library(sdk_hxmb)
    sdk_add_tpgdp_library(sdk_tpgdp)
    sdk_add_img_proc_library(sdk_img_proc)
    sdk_add_cmsis_nn_library(sdk_cmsis_nn)
    sdk_add_cmsis_dsp_library(sdk_cmsis_dsp)
    sdk_add_tflm_library(sdk_tflm)
endfunction()

message(STATUS "SDK Library module loaded")
message(STATUS "  Library root: ${SDK_LIBRARY_ROOT}")
message(STATUS "  Prebuilt dir: ${SDK_PREBUILT_DIR}")
