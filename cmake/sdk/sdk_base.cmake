# SDK Base Configuration for Grove Vision AI V2
# Sets up common paths, definitions, and include directories

# SDK root directory (should be set before including this file)
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including sdk_base.cmake")
endif()

# SDK configuration options with defaults
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

# Common definitions
set(SDK_COMMON_DEFINITIONS
    __GNU__
    __NEWLIB__
    ARMCM${SDK_CORTEX_M}
    CM55_BIG
    IC_VERSION=${SDK_IC_VER}
)

if(SDK_DEBUG)
    list(APPEND SDK_COMMON_DEFINITIONS DEBUG)
else()
    list(APPEND SDK_COMMON_DEFINITIONS NDEBUG)
endif()

if(SDK_TRUSTZONE)
    list(APPEND SDK_COMMON_DEFINITIONS TRUSTZONE)
    if(SDK_TRUSTZONE_TYPE STREQUAL "security")
        list(APPEND SDK_COMMON_DEFINITIONS TRUSTZONE_SEC)
        if(SDK_TRUSTZONE_FW_TYPE EQUAL 1)
            list(APPEND SDK_COMMON_DEFINITIONS TRUSTZONE_SEC_ONLY)
        endif()
    else()
        list(APPEND SDK_COMMON_DEFINITIONS TRUSTZONE_NS)
    endif()
endif()

if(SDK_SEMIHOST)
    list(APPEND SDK_COMMON_DEFINITIONS SEMIHOST)
endif()

# Driver IP definitions (required for peripheral access)
# These correspond to DRIVERS_IP_LIST in the SDK makefile
set(SDK_DRIVERS_IP_LIST
    scu uart spi i3c_mst isp iic mb timer watchdog rtc
    cdm edm jpeg xdma dp inp tpg inp1bitparser sensorctrl
    gpio i2s pdm i3c_slv vad swreg_aon swreg_lsc dma
    ppc pmu mpc hxautoi2c_mst csirx csitx adcc pwm
    inpovparser adcc_hv u55 2x2 5x5
)
foreach(IP ${SDK_DRIVERS_IP_LIST})
    list(APPEND SDK_COMMON_DEFINITIONS "IP_${IP}")
endforeach()

# Common include directories
set(SDK_COMMON_INCLUDE_DIRS
    ${SDK_ROOT}/CMSIS
    ${SDK_ROOT}/CMSIS/Driver
    ${SDK_ROOT}/device
    ${SDK_ROOT}/device/inc
    ${SDK_ROOT}/device/clib
    ${SDK_ROOT}/board/${SDK_BOARD}
    ${SDK_ROOT}/board/${SDK_BOARD}/config
    ${SDK_ROOT}/drivers/inc
    ${SDK_ROOT}/interface
    ${SDK_ROOT}/library/common
)

# TrustZone security specific includes
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    list(APPEND SDK_COMMON_INCLUDE_DIRS
        ${SDK_ROOT}/drivers/seconly_inc
        ${SDK_ROOT}/trustzone/tz_cfg
    )
endif()

# Common compile options for TrustZone security
set(SDK_COMMON_COMPILE_OPTIONS "")
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    list(APPEND SDK_COMMON_COMPILE_OPTIONS -mcmse)
endif()

# Function to apply SDK common settings to a target
function(sdk_apply_common_settings TARGET_NAME)
    target_compile_definitions(${TARGET_NAME} PRIVATE ${SDK_COMMON_DEFINITIONS})
    target_include_directories(${TARGET_NAME} PRIVATE ${SDK_COMMON_INCLUDE_DIRS})
    if(SDK_COMMON_COMPILE_OPTIONS)
        target_compile_options(${TARGET_NAME} PRIVATE ${SDK_COMMON_COMPILE_OPTIONS})
    endif()
endfunction()

message(STATUS "SDK Root: ${SDK_ROOT}")
message(STATUS "SDK Board: ${SDK_BOARD}")
message(STATUS "SDK TrustZone: ${SDK_TRUSTZONE} (${SDK_TRUSTZONE_TYPE}, FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
