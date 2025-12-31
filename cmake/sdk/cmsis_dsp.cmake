# CMSIS-DSP Library module for Grove Vision AI V2 SDK
# Ported from library/cmsis_dsp/cmsis_dsp.mk
#
# This module can build CMSIS-DSP from source or use prebuilt library.
# Set SDK_CMSIS_DSP_FORCE_PREBUILT=ON to use prebuilt (default: OFF = build from source)
#
# Depends on: cmsis_core (for CMSIS headers and MVE intrinsics)

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including cmsis_dsp.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)

# Configuration options
option(SDK_CMSIS_DSP_FORCE_PREBUILT "Use prebuilt CMSIS-DSP library instead of building from source" OFF)

# Directory paths
set(SDK_CMSIS_DSP_ROOT ${SDK_ROOT}/library/cmsis_dsp)
set(SDK_CMSIS_DSP_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/lib_cmsis_dsp.a)

# Include directories (from cmsis_dsp.mk lines 40-43)
set(SDK_CMSIS_DSP_INCLUDE_DIRS
    ${SDK_CMSIS_DSP_ROOT}
    ${SDK_CMSIS_DSP_ROOT}/Include
    ${SDK_CMSIS_DSP_ROOT}/Include/dsp
    ${SDK_CMSIS_DSP_ROOT}/PrivateInclude
    ${SDK_CMSIS_DSP_ROOT}/ComputeLibrary/Include
)

# Source subdirectories (from cmsis_dsp.mk lines 22-30)
# Note: Uses "_Used" variants for reduced footprint
set(SDK_CMSIS_DSP_SOURCE_DIRS
    ${SDK_CMSIS_DSP_ROOT}/Source/BasicMathFunctions
    ${SDK_CMSIS_DSP_ROOT}/Source/StatisticsFunctions_Used
    ${SDK_CMSIS_DSP_ROOT}/Source/MatrixFunctions
    ${SDK_CMSIS_DSP_ROOT}/Source/ComplexMathFunctions_Used
    ${SDK_CMSIS_DSP_ROOT}/Source/FastMathFunctions
    ${SDK_CMSIS_DSP_ROOT}/Source/CommonTables_Used
    ${SDK_CMSIS_DSP_ROOT}/Source/TransformFunctions_Used
    ${SDK_CMSIS_DSP_ROOT}/Source/SupportFunctions
)

# Compile definitions (from cmsis_dsp.mk line 60)
set(SDK_CMSIS_DSP_DEFINITIONS
    LIB_CMSIS_DSP
    ARM_MATH_MVEI
    ARM_MATH_DSP
    ARM_MATH_LOOPUNROLL
)

# Function to create CMSIS-DSP library
function(sdk_add_cmsis_dsp_library TARGET_NAME)
    if(SDK_CMSIS_DSP_FORCE_PREBUILT)
        # Use prebuilt library
        add_library(${TARGET_NAME} INTERFACE)

        # Link against cmsis_core (inherits CMSIS includes and defines)
        target_link_libraries(${TARGET_NAME} INTERFACE cmsis_core)

        # CMSIS-DSP includes (INTERFACE - propagate to dependents)
        target_include_directories(${TARGET_NAME} INTERFACE ${SDK_CMSIS_DSP_INCLUDE_DIRS})

        # CMSIS-DSP definitions (INTERFACE - propagate to dependents)
        foreach(DEF ${SDK_CMSIS_DSP_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} INTERFACE ${DEF})
        endforeach()

        # Note: Prebuilt library should be linked directly in --start-group block
        message(STATUS "CMSIS-DSP: Using prebuilt library")
    else()
        # Build from source
        # Collect all C source files from source directories
        set(CMSIS_DSP_SOURCES "")
        foreach(SRC_DIR ${SDK_CMSIS_DSP_SOURCE_DIRS})
            file(GLOB DIR_SOURCES "${SRC_DIR}/*.c")
            list(APPEND CMSIS_DSP_SOURCES ${DIR_SOURCES})
        endforeach()

        # Create static library
        add_library(${TARGET_NAME} STATIC ${CMSIS_DSP_SOURCES})

        # Apply SDK common settings
        sdk_apply_common_settings(${TARGET_NAME})

        # Link against cmsis_core (inherits CMSIS includes and defines)
        target_link_libraries(${TARGET_NAME} PUBLIC cmsis_core)

        # CMSIS-DSP includes (PUBLIC - propagate to dependents)
        target_include_directories(${TARGET_NAME} PUBLIC ${SDK_CMSIS_DSP_INCLUDE_DIRS})

        # CMSIS-DSP definitions (PUBLIC - propagate to dependents)
        foreach(DEF ${SDK_CMSIS_DSP_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
        endforeach()

        # Suppress warnings for CMSIS-DSP code
        target_compile_options(${TARGET_NAME} PRIVATE
            -Wno-unused-parameter
            -Wno-sign-compare
        )

        # Count source files for status message
        list(LENGTH CMSIS_DSP_SOURCES NUM_SOURCES)
        message(STATUS "CMSIS-DSP: Building from source (${NUM_SOURCES} files)")
    endif()
endfunction()

message(STATUS "CMSIS-DSP module loaded")
