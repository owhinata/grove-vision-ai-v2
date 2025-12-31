# CMSIS-CV Library module for Grove Vision AI V2 SDK
# Ported from library/cmsis_cv/cmsis_cv.mk
#
# This module provides CMSIS-CV (Computer Vision) functions
# including color transforms, image resize, filtering, and edge detection.
#
# Depends on: cmsis_core (for CMSIS headers and MVE intrinsics)

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including cmsis_cv.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_dsp.cmake)

# Directory paths
set(SDK_CMSIS_CV_ROOT ${SDK_ROOT}/library/cmsis_cv/CMSIS-CV)

# Include directories (from cmsis_cv.mk lines 40-42)
set(SDK_CMSIS_CV_INCLUDE_DIRS
    ${SDK_CMSIS_CV_ROOT}
    ${SDK_CMSIS_CV_ROOT}/Include
    ${SDK_CMSIS_CV_ROOT}/Include/cv
    ${SDK_CMSIS_CV_ROOT}/PrivateInclude
)

# Source subdirectories (from cmsis_cv.mk lines 12-16)
set(SDK_CMSIS_CV_SOURCE_DIRS
    ${SDK_CMSIS_CV_ROOT}/Source
    ${SDK_CMSIS_CV_ROOT}/Source/FeatureDetection
    ${SDK_CMSIS_CV_ROOT}/Source/LinearFilters
    ${SDK_CMSIS_CV_ROOT}/Source/ColorTransforms
    ${SDK_CMSIS_CV_ROOT}/Source/ImageTransforms
)

# Compile definitions (from cmsis_cv.mk line 59)
# Note: LIB_CMSIS_DSP is defined here because CMSIS-CV depends on DSP functions
set(SDK_CMSIS_CV_DEFINITIONS
    LIB_CMSIS_DSP
    ARM_MATH_MVEI
    ARM_MATH_DSP
    ARM_MATH_LOOPUNROLL
)

# Function to create CMSIS-CV library
function(sdk_add_cmsis_cv_library TARGET_NAME)
    # Collect all C source files from source directories
    set(CMSIS_CV_SOURCES "")
    foreach(SRC_DIR ${SDK_CMSIS_CV_SOURCE_DIRS})
        file(GLOB DIR_SOURCES "${SRC_DIR}/*.c")
        list(APPEND CMSIS_CV_SOURCES ${DIR_SOURCES})
    endforeach()

    # Build from source
    add_library(${TARGET_NAME} STATIC ${CMSIS_CV_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Link against cmsis_core (inherits CMSIS includes and defines)
    target_link_libraries(${TARGET_NAME} PUBLIC cmsis_core)

    # CMSIS-CV depends on CMSIS-DSP headers (arm_math_types.h)
    target_include_directories(${TARGET_NAME} PRIVATE ${SDK_CMSIS_DSP_INCLUDE_DIRS})

    # CMSIS-CV includes (PUBLIC - propagate to dependents)
    target_include_directories(${TARGET_NAME} PUBLIC ${SDK_CMSIS_CV_INCLUDE_DIRS})

    # CMSIS-CV definitions (PUBLIC - propagate to dependents)
    foreach(DEF ${SDK_CMSIS_CV_DEFINITIONS})
        target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
    endforeach()

    # Suppress warnings for CMSIS-CV code
    target_compile_options(${TARGET_NAME} PRIVATE
        -Wno-unused-parameter
    )

    # Count source files for status message
    list(LENGTH CMSIS_CV_SOURCES NUM_SOURCES)
    message(STATUS "CMSIS-CV: Building from source (${NUM_SOURCES} files)")
endfunction()

message(STATUS "CMSIS-CV module loaded")
