# FreeRTOS module for Grove Vision AI V2 SDK
# Provides FreeRTOS kernel for TrustZone Security Only configuration
#
# Configuration:
#   SDK_USE_FREERTOS must be ON
#   SDK_TRUSTZONE_FW_TYPE = 1 (Security Only) uses NTZ kernel with FREERTOS_SECONLY
#
# Depends on: device

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including freertos.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/device.cmake)

# FreeRTOS directories
set(SDK_FREERTOS_ROOT ${SDK_ROOT}/os/freertos)

# Determine FreeRTOS variant based on TrustZone configuration
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_FW_TYPE EQUAL 1)
    # TrustZone Security Only - use NTZ kernel with FREERTOS_SECONLY
    set(SDK_FREERTOS_VARIANT "NTZ")
    set(SDK_FREERTOS_PORT_DIR "ARM_CM55_NTZ/non_secure")
    set(SDK_FREERTOS_DEFINES FREERTOS FREERTOS_SECONLY ENABLE_OS OS_FREERTOS configENABLE_MPU=0)
elseif(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    # TrustZone Secure side (S+NS) - use TZ_Sec (secure port only)
    set(SDK_FREERTOS_VARIANT "TZ_Sec")
    set(SDK_FREERTOS_PORT_DIR "ARM_CM55/secure")
    set(SDK_FREERTOS_DEFINES FREERTOS FREERTOS_S ENABLE_OS OS_FREERTOS configENABLE_MPU=0)
elseif(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "non-security")
    # TrustZone Non-Secure side - use TZ_NonSec
    set(SDK_FREERTOS_VARIANT "TZ_NonSec")
    set(SDK_FREERTOS_PORT_DIR "ARM_CM55/non_secure")
    set(SDK_FREERTOS_DEFINES FREERTOS FREERTOS_NS ENABLE_OS OS_FREERTOS configENABLE_MPU=0)
else()
    # Non-TrustZone - use NTZ
    set(SDK_FREERTOS_VARIANT "NTZ")
    set(SDK_FREERTOS_PORT_DIR "ARM_CM55_NTZ/non_secure")
    set(SDK_FREERTOS_DEFINES FREERTOS ENABLE_OS OS_FREERTOS configENABLE_MPU=0)
endif()

set(SDK_FREERTOS_KERNEL_DIR ${SDK_FREERTOS_ROOT}/${SDK_FREERTOS_VARIANT}/freertos_kernel)
set(SDK_FREERTOS_CONFIG_DIR ${SDK_FREERTOS_ROOT}/${SDK_FREERTOS_VARIANT}/config)
set(SDK_FREERTOS_PORT_SRC_DIR ${SDK_FREERTOS_KERNEL_DIR}/portable/GCC/${SDK_FREERTOS_PORT_DIR})

# FreeRTOS include directories
set(SDK_FREERTOS_INCLUDE_DIRS
    ${SDK_FREERTOS_KERNEL_DIR}/include
    ${SDK_FREERTOS_PORT_SRC_DIR}
    ${SDK_FREERTOS_CONFIG_DIR}
)

# FreeRTOS kernel sources (for NTZ and TZ_NonSec - full kernel)
if(SDK_FREERTOS_VARIANT STREQUAL "NTZ" OR SDK_FREERTOS_VARIANT STREQUAL "TZ_NonSec")
    set(SDK_FREERTOS_KERNEL_SOURCES
        ${SDK_FREERTOS_KERNEL_DIR}/croutine.c
        ${SDK_FREERTOS_KERNEL_DIR}/event_groups.c
        ${SDK_FREERTOS_KERNEL_DIR}/list.c
        ${SDK_FREERTOS_KERNEL_DIR}/queue.c
        ${SDK_FREERTOS_KERNEL_DIR}/stream_buffer.c
        ${SDK_FREERTOS_KERNEL_DIR}/tasks.c
        ${SDK_FREERTOS_KERNEL_DIR}/timers.c
    )

    # Port sources
    set(SDK_FREERTOS_PORT_SOURCES
        ${SDK_FREERTOS_PORT_SRC_DIR}/port.c
        ${SDK_FREERTOS_PORT_SRC_DIR}/portasm.c
    )

    # Memory management (heap_4)
    set(SDK_FREERTOS_MEMMANG_SOURCES
        ${SDK_FREERTOS_KERNEL_DIR}/portable/MemMang/heap_4.c
    )
    list(APPEND SDK_FREERTOS_INCLUDE_DIRS
        ${SDK_FREERTOS_KERNEL_DIR}/portable/MemMang
    )
else()
    # TZ_Sec - secure port only (no full kernel)
    set(SDK_FREERTOS_KERNEL_SOURCES "")
    set(SDK_FREERTOS_PORT_SOURCES
        ${SDK_FREERTOS_PORT_SRC_DIR}/secure_context.c
        ${SDK_FREERTOS_PORT_SRC_DIR}/secure_context_port.c
        ${SDK_FREERTOS_PORT_SRC_DIR}/secure_heap.c
        ${SDK_FREERTOS_PORT_SRC_DIR}/secure_init.c
    )
    set(SDK_FREERTOS_MEMMANG_SOURCES "")
endif()

# All FreeRTOS sources
set(SDK_FREERTOS_SOURCES
    ${SDK_FREERTOS_KERNEL_SOURCES}
    ${SDK_FREERTOS_PORT_SOURCES}
    ${SDK_FREERTOS_MEMMANG_SOURCES}
)

# Function to create FreeRTOS library
function(sdk_add_freertos_library TARGET_NAME)
    if(NOT SDK_FREERTOS_SOURCES)
        message(WARNING "No FreeRTOS sources for variant ${SDK_FREERTOS_VARIANT}")
        return()
    endif()

    add_library(${TARGET_NAME} STATIC ${SDK_FREERTOS_SOURCES})

    # Apply SDK common settings (temporary - will be removed as we modularize)
    sdk_apply_common_settings(${TARGET_NAME})

    # Link against device (inherits includes and defines)
    target_link_libraries(${TARGET_NAME} PUBLIC device)

    # FreeRTOS includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC
        ${SDK_FREERTOS_INCLUDE_DIRS}
    )

    # FreeRTOS definitions (PUBLIC - propagate to dependents)
    target_compile_definitions(${TARGET_NAME} PUBLIC
        ${SDK_FREERTOS_DEFINES}
    )

    # Suppress warnings for FreeRTOS code
    target_compile_options(${TARGET_NAME} PRIVATE
        -Wno-unused-parameter
    )

    list(LENGTH SDK_FREERTOS_SOURCES NUM_SOURCES)
    message(STATUS "FreeRTOS: ${SDK_FREERTOS_VARIANT} variant (${NUM_SOURCES} files)")
endfunction()

message(STATUS "FreeRTOS module loaded (variant: ${SDK_FREERTOS_VARIANT})")
