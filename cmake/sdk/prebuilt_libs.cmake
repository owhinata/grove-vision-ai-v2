# Prebuilt Libraries module for Grove Vision AI V2 SDK
# Links against prebuilt static libraries from the SDK

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including prebuilt_libs.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Prebuilt library directory (GNU toolchain)
set(SDK_PREBUILT_DIR ${SDK_ROOT}/prebuilt_libs/gnu)

# Core prebuilt libraries for basic functionality
# Note: libcommon.a is now built from source via common.cmake
# Note: libtrustzone_cfg.a is now built from source via trustzone.cmake
set(SDK_PREBUILT_CORE_LIBS
    ${SDK_PREBUILT_DIR}/libdriver.a
)

# Optional prebuilt libraries
set(SDK_PREBUILT_PWRMGMT ${SDK_PREBUILT_DIR}/libpwrmgmt.a)
set(SDK_PREBUILT_HXEVENT ${SDK_PREBUILT_DIR}/libhxevent.a)
set(SDK_PREBUILT_SENSORDP ${SDK_PREBUILT_DIR}/libsensordp.a)
set(SDK_PREBUILT_EXTDEVICE ${SDK_PREBUILT_DIR}/libextdevice.a)
set(SDK_PREBUILT_TFLM ${SDK_PREBUILT_DIR}/libtflmtag2209_u55tag2205_cmsisnn_gnu.a)
set(SDK_PREBUILT_CMSIS_NN ${SDK_PREBUILT_DIR}/lib_cmsis_nn.a)
set(SDK_PREBUILT_CMSIS_DSP ${SDK_PREBUILT_DIR}/lib_cmsis_dsp.a)
set(SDK_PREBUILT_SPI_EEPROM ${SDK_PREBUILT_DIR}/lib_spi_eeprom.a)
set(SDK_PREBUILT_I2C_COMM ${SDK_PREBUILT_DIR}/lib_i2c_comm.a)
set(SDK_PREBUILT_AUDIO ${SDK_PREBUILT_DIR}/libaudio.a)

# Function to link core prebuilt libraries to a target
function(sdk_link_prebuilt_core TARGET_NAME)
    foreach(LIB ${SDK_PREBUILT_CORE_LIBS})
        if(EXISTS ${LIB})
            target_link_libraries(${TARGET_NAME} PRIVATE ${LIB})
        else()
            message(WARNING "Prebuilt library not found: ${LIB}")
        endif()
    endforeach()
endfunction()

# Function to link all common prebuilt libraries (for typical apps)
function(sdk_link_prebuilt_common TARGET_NAME)
    sdk_link_prebuilt_core(${TARGET_NAME})

    # Additional common libraries
    set(COMMON_OPTIONAL_LIBS
        ${SDK_PREBUILT_PWRMGMT}
        ${SDK_PREBUILT_HXEVENT}
    )

    foreach(LIB ${COMMON_OPTIONAL_LIBS})
        if(EXISTS ${LIB})
            target_link_libraries(${TARGET_NAME} PRIVATE ${LIB})
        endif()
    endforeach()
endfunction()

message(STATUS "SDK Prebuilt libs directory: ${SDK_PREBUILT_DIR}")
