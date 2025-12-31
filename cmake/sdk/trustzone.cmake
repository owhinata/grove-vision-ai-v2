# TrustZone module for Grove Vision AI V2 SDK
# Ported from trustzone/trustzone.mk, trustzone/tz_cfg/tz_cfg.mk,
# and trustzone/nsc_function/nsc_function.mk
#
# This module provides three libraries:
# 1. libtrustzone_cfg.a - TrustZone SAU/MPC/PPC configuration (always needed for TZ)
# 2. libnsc.a - Non-Secure Callable veneer functions (only for S+NS configurations)
# 3. libtrustzone_sec.a - Additional secure-only code (currently empty)
#
# For TRUSTZONE_SEC_ONLY (FW_TYPE=1), only libtrustzone_cfg.a is needed.

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including trustzone.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# TrustZone directories
set(SDK_TRUSTZONE_DIR ${SDK_ROOT}/trustzone)
set(SDK_TRUSTZONE_CFG_DIR ${SDK_TRUSTZONE_DIR}/tz_cfg)
set(SDK_NSC_DIR ${SDK_TRUSTZONE_DIR}/nsc_function)
set(SDK_NSC_SRC_DIR ${SDK_NSC_DIR}/nsc_src)

# =============================================================================
# libtrustzone_cfg.a - TrustZone Configuration Library
# From: trustzone/tz_cfg/tz_cfg.mk
# Contains: SAU, MPC, PPC configuration for memory security
# =============================================================================

set(SDK_TRUSTZONE_CFG_SOURCES
    ${SDK_TRUSTZONE_CFG_DIR}/trustzone_cfg.c
)

set(SDK_TRUSTZONE_CFG_INCLUDE_DIRS
    ${SDK_TRUSTZONE_CFG_DIR}
    ${SDK_TRUSTZONE_DIR}
)

# Function to create TrustZone configuration library
function(sdk_add_trustzone_cfg_library TARGET_NAME)
    add_library(${TARGET_NAME} STATIC ${SDK_TRUSTZONE_CFG_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add TrustZone specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_TRUSTZONE_CFG_INCLUDE_DIRS})

    # Add TrustZone specific definitions (from tz_cfg.mk line 38)
    target_compile_definitions(${TARGET_NAME} PRIVATE TRUSTZONE_CFG)
endfunction()

# =============================================================================
# libnsc.a - Non-Secure Callable Library
# From: trustzone/nsc_function/nsc_function.mk
# Contains: Veneer functions for S->NS calls
# Only needed when TRUSTZONE_FW_TYPE != 1 (i.e., S+NS configuration)
# =============================================================================

# NSC IP modules (from nsc_cfg/cm55m_nsc_cfg.mk)
set(SDK_NSC_IP_LIST
    clk_ctrl
    sys_ctrl
    power_ctrl
    timer_ctrl
)

# Collect NSC sources based on IP list
set(SDK_NSC_SOURCES "")
set(SDK_NSC_INCLUDE_DIRS
    ${SDK_NSC_DIR}
    ${SDK_NSC_DIR}/nsc_inc
)

foreach(NSC_IP ${SDK_NSC_IP_LIST})
    # Add source directory for each IP
    set(NSC_IP_SRC_DIR ${SDK_NSC_SRC_DIR}/${NSC_IP})
    if(EXISTS ${NSC_IP_SRC_DIR})
        file(GLOB NSC_IP_SOURCES "${NSC_IP_SRC_DIR}/*.c")
        list(APPEND SDK_NSC_SOURCES ${NSC_IP_SOURCES})
        list(APPEND SDK_NSC_INCLUDE_DIRS ${NSC_IP_SRC_DIR})
    endif()
endforeach()

# Add nsc_test sources (veneer_table.c)
if(EXISTS ${SDK_NSC_SRC_DIR}/nsc_test)
    file(GLOB NSC_TEST_SOURCES "${SDK_NSC_SRC_DIR}/nsc_test/*.c")
    list(APPEND SDK_NSC_SOURCES ${NSC_TEST_SOURCES})
endif()

# Function to create NSC library (only for S+NS configurations)
function(sdk_add_nsc_library TARGET_NAME)
    if(NOT SDK_NSC_SOURCES)
        message(WARNING "No NSC sources found, skipping libnsc.a")
        return()
    endif()

    add_library(${TARGET_NAME} STATIC ${SDK_NSC_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add NSC specific include directories
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_NSC_INCLUDE_DIRS})

    # Add NSC specific definitions
    # For non-security side: -DNSC
    # For each IP: -DNSC_<ip>
    if(NOT SDK_TRUSTZONE_TYPE STREQUAL "security")
        target_compile_definitions(${TARGET_NAME} PRIVATE NSC)
    endif()

    foreach(NSC_IP ${SDK_NSC_IP_LIST})
        string(TOUPPER ${NSC_IP} NSC_IP_UPPER)
        target_compile_definitions(${TARGET_NAME} PRIVATE NSC_${NSC_IP})
    endforeach()
endfunction()

# =============================================================================
# Customer NSC extensions (optional)
# From: trustzone/nsc_function/nsc_customer/nsc_customer.mk
# =============================================================================

# Customer can be set via SDK_NSC_CUSTOMER variable
if(DEFINED SDK_NSC_CUSTOMER)
    set(SDK_NSC_CUSTOMER_DIR ${SDK_NSC_DIR}/nsc_customer)
    set(SDK_NSC_CUSTOMER_SRC_DIR ${SDK_NSC_CUSTOMER_DIR}/nsc_src/${SDK_NSC_CUSTOMER})
    set(SDK_NSC_CUSTOMER_INC_DIR ${SDK_NSC_CUSTOMER_DIR}/nsc_inc/${SDK_NSC_CUSTOMER})

    if(EXISTS ${SDK_NSC_CUSTOMER_SRC_DIR})
        file(GLOB SDK_NSC_CUSTOMER_SOURCES "${SDK_NSC_CUSTOMER_SRC_DIR}/*.c")
        list(APPEND SDK_NSC_SOURCES ${SDK_NSC_CUSTOMER_SOURCES})
    endif()

    if(EXISTS ${SDK_NSC_CUSTOMER_INC_DIR})
        list(APPEND SDK_NSC_INCLUDE_DIRS ${SDK_NSC_CUSTOMER_INC_DIR})
    endif()
endif()

# =============================================================================
# Summary
# =============================================================================

message(STATUS "TrustZone configuration library module loaded")
if(SDK_TRUSTZONE AND NOT SDK_TRUSTZONE_FW_TYPE EQUAL 1)
    message(STATUS "  NSC library available (S+NS configuration)")
    message(STATUS "  NSC IP modules: ${SDK_NSC_IP_LIST}")
endif()
