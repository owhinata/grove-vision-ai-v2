# SDK Base Configuration for Grove Vision AI V2
# Sets up common SDK options and provides temporary compatibility layer
#
# This file is being minimized as includes/defines move to individual modules:
# - cmsis_core.cmake: CMSIS headers, __GNU__, __NEWLIB__, ARMCM55, CM55_BIG
# - device.cmake: device includes, IC_VERSION, IC_PACKAGE, COREV_0P9V
# - board.cmake: board includes, seeed, EPII_EVB, customer includes
# - drivers.cmake: driver includes, IP_*, IP_INST_*
# - interface.cmake: interface includes
# - common.cmake: common library includes
# - trustzone.cmake: TrustZone includes/defines, -mcmse

# SDK root directory (should be set before including this file)
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including sdk_base.cmake")
endif()

# =============================================================================
# SDK configuration options (cache variables used by modules)
# =============================================================================

set(SDK_BOARD "epii_evb" CACHE STRING "Board type")
set(SDK_IC_VER "30" CACHE STRING "IC version")
set(SDK_BD_VER "10" CACHE STRING "Board version")
set(SDK_CORTEX_M "55" CACHE STRING "Cortex-M version")

option(SDK_TRUSTZONE "Enable TrustZone" ON)
set(SDK_TRUSTZONE_TYPE "security" CACHE STRING "TrustZone type (security/non-security)")
set(SDK_TRUSTZONE_FW_TYPE 1 CACHE STRING "TrustZone firmware type (0=S+NS, 1=S only)")

option(SDK_USE_FREERTOS "Use FreeRTOS" OFF)
option(SDK_USE_RTX "Use RTX" OFF)
option(SDK_SEMIHOST "Use semihosting" OFF)
option(SDK_DEBUG "Debug build" ON)

# IC package type
set(SDK_IC_PACKAGE "WLCSP65" CACHE STRING "IC package type")

# =============================================================================
# Temporary compatibility - sdk_apply_common_settings()
# This function provides remaining settings not yet in individual modules.
# It will be removed once all modules are fully modularized.
# =============================================================================

# SDK_COMMON_INCLUDE_DIRS - still used by linker.cmake for linker script preprocessing
# Set after SDK_CROSS_MODULE_INCLUDE_DIRS is defined below

# Minimal common definitions (DEBUG/NDEBUG only - everything else is in modules)
set(SDK_COMMON_DEFINITIONS "")
if(SDK_DEBUG)
    list(APPEND SDK_COMMON_DEFINITIONS DEBUG)
else()
    list(APPEND SDK_COMMON_DEFINITIONS NDEBUG)
endif()

if(SDK_SEMIHOST)
    list(APPEND SDK_COMMON_DEFINITIONS SEMIHOST)
endif()

# FreeRTOS OS define (prevents device library from defining SysTick_Handler/SVC_Handler)
if(SDK_USE_FREERTOS)
    list(APPEND SDK_COMMON_DEFINITIONS ENABLE_OS)
endif()

# Cross-module include directories needed due to tight coupling in SDK code
# (e.g., device sources include board.h, board sources include timer_interface.h,
#  ethosu_driver.c includes WE2_core.h, xprintf.c includes WE2_device.h)
# These will remain until the SDK code itself is refactored for better separation
set(SDK_CROSS_MODULE_INCLUDE_DIRS
    # CMSIS core
    ${SDK_ROOT}/CMSIS
    ${SDK_ROOT}/CMSIS/Driver/Include
    # Device
    ${SDK_ROOT}/device
    ${SDK_ROOT}/device/inc
    ${SDK_ROOT}/device/clib
    # Drivers
    ${SDK_ROOT}/drivers
    ${SDK_ROOT}/drivers/inc
    # Board
    ${SDK_ROOT}/board
    ${SDK_ROOT}/board/${SDK_BOARD}
    ${SDK_ROOT}/board/${SDK_BOARD}/config
    # Interface
    ${SDK_ROOT}/interface
    # Common library
    ${SDK_ROOT}/library/common
    # Customer includes
    ${SDK_ROOT}/customer/sec_inc/seeed
)

# TrustZone security specific includes
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    list(APPEND SDK_CROSS_MODULE_INCLUDE_DIRS
        ${SDK_ROOT}/drivers/seconly_inc
        ${SDK_ROOT}/trustzone/tz_cfg
    )
endif()

# FreeRTOS includes (needed by device/clib when SDK_USE_FREERTOS is ON)
if(SDK_USE_FREERTOS)
    # Determine FreeRTOS variant
    if(SDK_TRUSTZONE AND SDK_TRUSTZONE_FW_TYPE EQUAL 1)
        set(_FREERTOS_VARIANT "NTZ")
        set(_FREERTOS_PORT_DIR "ARM_CM55_NTZ/non_secure")
    elseif(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
        set(_FREERTOS_VARIANT "TZ_Sec")
        set(_FREERTOS_PORT_DIR "ARM_CM55/secure")
    elseif(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "non-security")
        set(_FREERTOS_VARIANT "TZ_NonSec")
        set(_FREERTOS_PORT_DIR "ARM_CM55/non_secure")
    else()
        set(_FREERTOS_VARIANT "NTZ")
        set(_FREERTOS_PORT_DIR "ARM_CM55_NTZ/non_secure")
    endif()

    list(APPEND SDK_CROSS_MODULE_INCLUDE_DIRS
        ${SDK_ROOT}/os/freertos/${_FREERTOS_VARIANT}/freertos_kernel/include
        ${SDK_ROOT}/os/freertos/${_FREERTOS_VARIANT}/freertos_kernel/portable/GCC/${_FREERTOS_PORT_DIR}
        ${SDK_ROOT}/os/freertos/${_FREERTOS_VARIANT}/config
    )
endif()

# SDK_COMMON_INCLUDE_DIRS - alias for linker.cmake compatibility
set(SDK_COMMON_INCLUDE_DIRS ${SDK_CROSS_MODULE_INCLUDE_DIRS})

# Common compile options for TrustZone security
set(SDK_COMMON_COMPILE_OPTIONS "")
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    list(APPEND SDK_COMMON_COMPILE_OPTIONS -mcmse)
endif()

# Function to apply SDK common settings to a target
# This function provides the "glue" for SDK's tightly-coupled code
# Individual modules still define their PUBLIC includes/defines for proper propagation
function(sdk_apply_common_settings TARGET_NAME)
    # Apply DEBUG/NDEBUG and SEMIHOST
    target_compile_definitions(${TARGET_NAME} PRIVATE ${SDK_COMMON_DEFINITIONS})

    # Apply cross-module includes needed for tight coupling in SDK code
    target_include_directories(${TARGET_NAME} PRIVATE ${SDK_CROSS_MODULE_INCLUDE_DIRS})

    # Apply TrustZone compile options
    if(SDK_COMMON_COMPILE_OPTIONS)
        target_compile_options(${TARGET_NAME} PRIVATE ${SDK_COMMON_COMPILE_OPTIONS})
    endif()
endfunction()

message(STATUS "SDK Root: ${SDK_ROOT}")
message(STATUS "SDK Board: ${SDK_BOARD}")
message(STATUS "SDK TrustZone: ${SDK_TRUSTZONE} (${SDK_TRUSTZONE_TYPE}, FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
