# CMSIS-NN Library module for Grove Vision AI V2 SDK
# Ported from library/cmsis_nn/cmsis_nn_7_0_0/cmsis_nn_7_0_0.mk
#
# This module can build CMSIS-NN from source or use prebuilt library.
# Set SDK_CMSIS_NN_FORCE_PREBUILT=ON to use prebuilt (default: OFF = build from source)
#
# Depends on: cmsis_core (for CMSIS headers and MVE intrinsics)

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including cmsis_nn.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)

# Configuration options
option(SDK_CMSIS_NN_FORCE_PREBUILT "Use prebuilt CMSIS-NN library instead of building from source" OFF)
set(SDK_CMSIS_NN_VERSION "7_0_0" CACHE STRING "CMSIS-NN version")
set_property(CACHE SDK_CMSIS_NN_VERSION PROPERTY STRINGS "7_0_0")

# Directory paths
set(SDK_CMSIS_NN_ROOT ${SDK_ROOT}/library/cmsis_nn/cmsis_nn_${SDK_CMSIS_NN_VERSION})
set(SDK_CMSIS_NN_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/lib_cmsis_nn_${SDK_CMSIS_NN_VERSION}.a)

# Include directories (from cmsis_nn_7_0_0.mk lines 29-30)
# Note: CMSIS core headers come from cmsis_core via target_link_libraries
set(SDK_CMSIS_NN_INCLUDE_DIRS
    ${SDK_CMSIS_NN_ROOT}
    ${SDK_CMSIS_NN_ROOT}/Include
    ${SDK_CMSIS_NN_ROOT}/Include/Internal
)

# Source subdirectories (from cmsis_nn_7_0_0.mk lines 11-23)
set(SDK_CMSIS_NN_SOURCE_DIRS
    ${SDK_CMSIS_NN_ROOT}/Source/ActivationFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/BasicMathFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/ConcatenationFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/ConvolutionFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/FullyConnectedFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/LSTMFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/NNSupportFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/PadFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/PoolingFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/ReshapeFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/SoftmaxFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/SVDFunctions
    ${SDK_CMSIS_NN_ROOT}/Source/TransposeFunctions
)

# Compile definitions (from cmsis_nn_7_0_0.mk line 48)
# Note: ARM_MATH_AUTOVECTORIZE is NOT used - we use optimized MVE assembly
set(SDK_CMSIS_NN_DEFINITIONS
    LIB_CMSIS_NN
    ARM_MATH_MVEI
    ARM_MATH_DSP
    ARM_MATH_LOOPUNROLL
)

# Function to create CMSIS-NN library
function(sdk_add_cmsis_nn_library TARGET_NAME)
    if(SDK_CMSIS_NN_FORCE_PREBUILT)
        # Use prebuilt library
        add_library(${TARGET_NAME} INTERFACE)

        # Link against cmsis_core (inherits CMSIS includes and defines)
        target_link_libraries(${TARGET_NAME} INTERFACE cmsis_core)

        # CMSIS-NN includes (INTERFACE - propagate to dependents)
        target_include_directories(${TARGET_NAME} INTERFACE ${SDK_CMSIS_NN_INCLUDE_DIRS})

        # CMSIS-NN definitions (INTERFACE - propagate to dependents)
        foreach(DEF ${SDK_CMSIS_NN_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} INTERFACE ${DEF})
        endforeach()

        # Note: Prebuilt library should be linked directly in --start-group block
        message(STATUS "CMSIS-NN: Using prebuilt library")
    else()
        # Build from source
        # Collect all C source files from source directories
        set(CMSIS_NN_SOURCES "")
        foreach(SRC_DIR ${SDK_CMSIS_NN_SOURCE_DIRS})
            file(GLOB DIR_SOURCES "${SRC_DIR}/*.c")
            list(APPEND CMSIS_NN_SOURCES ${DIR_SOURCES})
        endforeach()

        # Create static library
        add_library(${TARGET_NAME} STATIC ${CMSIS_NN_SOURCES})

        # Apply SDK common settings (temporary - will be removed as we modularize)
        sdk_apply_common_settings(${TARGET_NAME})

        # Link against cmsis_core (inherits CMSIS includes and defines)
        target_link_libraries(${TARGET_NAME} PUBLIC cmsis_core)

        # CMSIS-NN includes (PUBLIC - propagate to dependents)
        target_include_directories(${TARGET_NAME} PUBLIC ${SDK_CMSIS_NN_INCLUDE_DIRS})

        # CMSIS-NN definitions (PUBLIC - propagate to dependents)
        foreach(DEF ${SDK_CMSIS_NN_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
        endforeach()

        # Count source files for status message
        list(LENGTH CMSIS_NN_SOURCES NUM_SOURCES)
        message(STATUS "CMSIS-NN: Building from source (${NUM_SOURCES} files)")
    endif()
endfunction()

message(STATUS "CMSIS-NN module loaded (version: ${SDK_CMSIS_NN_VERSION})")
