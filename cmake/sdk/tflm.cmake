# TensorFlow Lite Micro Library module for Grove Vision AI V2 SDK
# Ported from library/inference/tflmtag2209_u55tag2205/tflmtag2209_u55tag2205.mk
#
# This module can build TFLM from source or use prebuilt library.
# Set SDK_TFLM_FORCE_PREBUILT=ON to use prebuilt (default: OFF = build from source)
#
# When SDK_TFLM_USE_CMSIS_NN=ON, CMSIS-NN optimized kernels are used.
# CMSIS-NN library must also be built/linked separately (via cmsis_nn.cmake).

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including tflm.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Configuration options
option(SDK_TFLM_FORCE_PREBUILT "Use prebuilt TFLM library instead of building from source" OFF)
option(SDK_TFLM_USE_CMSIS_NN "Use CMSIS-NN optimized kernels" OFF)

# Include CMSIS-NN module if using CMSIS-NN kernels (for include dirs)
if(SDK_TFLM_USE_CMSIS_NN AND NOT DEFINED SDK_CMSIS_NN_ROOT)
    include(${CMAKE_CURRENT_LIST_DIR}/cmsis_nn.cmake)
endif()

set(SDK_TFLM_VERSION "tflmtag2209_u55tag2205" CACHE STRING "TFLM version")
set_property(CACHE SDK_TFLM_VERSION PROPERTY STRINGS
    tflmtag2209_u55tag2205
    tflmtag2412_u55tag2411
)

# Directory paths
set(SDK_TFLM_ROOT ${SDK_ROOT}/library/inference/${SDK_TFLM_VERSION})

# Prebuilt library path
if(SDK_TFLM_USE_CMSIS_NN)
    set(SDK_TFLM_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/lib${SDK_TFLM_VERSION}_cmsisnn_gnu.a)
else()
    set(SDK_TFLM_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/lib${SDK_TFLM_VERSION}_gnu.a)
endif()

# Include directories (from tflmtag2209_u55tag2205.mk lines 15-28)
set(SDK_TFLM_INCLUDE_DIRS
    ${SDK_TFLM_ROOT}
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro
    ${SDK_TFLM_ROOT}/tensorflow/lite/schema
    ${SDK_TFLM_ROOT}/tensorflow/lite/c
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels/internal/reference
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels/internal
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels
    ${SDK_TFLM_ROOT}/tensorflow/lite
    ${SDK_TFLM_ROOT}/tensorflow/lite/core/api
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels
    ${SDK_TFLM_ROOT}/third_party/flatbuffers/include
    ${SDK_TFLM_ROOT}/third_party
    ${SDK_TFLM_ROOT}/third_party/ethos_u_core_driver/include
    ${SDK_TFLM_ROOT}/third_party/gemmlowp
    ${SDK_TFLM_ROOT}/third_party/ruy
)

# Compile definitions (from tflmtag2209_u55tag2205.mk lines 223-224)
set(SDK_TFLM_DEFINITIONS
    TFLM2209_U55TAG2205
    TF_LITE_STATIC_MEMORY
    TF_LITE_MCU_DEBUG_LOG
    ETHOSU_ARCH=u55
    ETHOSU55
    ETHOSU_LOG_SEVERITY=ETHOSU_LOG_WARN
    ETHOS_U
)

# C source files (from tflmtag2209_u55tag2205.mk lines 35-38)
set(SDK_TFLM_C_SOURCES
    ${SDK_TFLM_ROOT}/third_party/ethos_u_core_driver/src/ethosu_pmu.c
    ${SDK_TFLM_ROOT}/third_party/ethos_u_core_driver/src/ethosu_driver.c
    ${SDK_TFLM_ROOT}/third_party/ethos_u_core_driver/src/ethosu_device_u55_u65.c
)

# C++ source files (from tflmtag2209_u55tag2205.mk lines 45-175)
set(SDK_TFLM_CXX_SOURCES
    ${SDK_TFLM_ROOT}/tensorflow/lite/c/common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/schema/schema_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels/internal/reference/portable_tensor_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels/internal/quantization_util.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/kernels/kernel_util.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/core/api/op_resolver.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/core/api/error_reporter.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/core/api/tensor_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/core/api/flatbuffer_conversions.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/all_ops_resolver.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/debug_log.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/fake_micro_context.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/flatbuffer_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/memory_helpers.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_allocation_info.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_context.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_error_reporter.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_graph.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_interpreter.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_log.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_profiler.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_resource_variable.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_string.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_time.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/micro_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/mock_micro_graph.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/recording_micro_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/test_helpers.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/test_helper_custom_ops.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/arena_allocator/non_persistent_arena_buffer_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/arena_allocator/persistent_arena_buffer_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/arena_allocator/recording_single_arena_buffer_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/arena_allocator/single_arena_buffer_allocator.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/cortex_m_corstone_300/micro_time.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/memory_planner/greedy_memory_planner.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/memory_planner/linear_memory_planner.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/memory_planner/non_persistent_buffer_planner_shim.cc
    # Kernels (common)
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/activations.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/activations_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/add_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/add_n.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/arg_min_max.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/assign_variable.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/batch_to_space_nd.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/broadcast_args.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/broadcast_to.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/call_once.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cast.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/ceil.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/circular_buffer.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/circular_buffer_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/comparisons.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/concatenation.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/conv_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cumsum.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/depth_to_space.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/depthwise_conv_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/dequantize.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/dequantize_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/detection_postprocess.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/div.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/elementwise.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/elu.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/exp.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/expand_dims.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/fill.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/floor.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/floor_div.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/floor_mod.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/fully_connected_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/gather.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/gather_nd.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/hard_swish.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/hard_swish_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/if.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/kernel_runner.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/kernel_util.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/l2_pool_2d.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/l2norm.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/leaky_relu.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/leaky_relu_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/log_softmax.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/logical.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/logical_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/logistic.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/logistic_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/lstm_eval.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/maximum_minimum.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/micro_tensor_utils.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/mirror_pad.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/mul_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/neg.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/pack.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/pad.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/pooling_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/prelu.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/prelu_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/quantize.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/quantize_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/read_variable.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/reduce.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/reduce_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/reshape.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/resize_bilinear.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/resize_nearest_neighbor.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/round.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/select.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/shape.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/slice.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/softmax_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/space_to_batch_nd.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/space_to_depth.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/split.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/split_v.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/squared_difference.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/squeeze.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/strided_slice.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/sub.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/sub_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/svdf_common.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/tanh.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/transpose.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/transpose_conv.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/unidirectional_sequence_lstm.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/unpack.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/var_handle.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/while.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/zeros_like.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/ethos_u/ethosu.cc
)

# CMSIS-NN optimized kernels (from tflmtag2209_u55tag2205.mk lines 178-186)
set(SDK_TFLM_CMSIS_NN_SOURCES
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/add.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/conv.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/depthwise_conv.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/fully_connected.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/mul.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/pooling.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/softmax.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/cmsis_nn/svdf.cc
)

# Reference kernels (non-CMSIS-NN) (from tflmtag2209_u55tag2205.mk lines 192-200)
set(SDK_TFLM_REFERENCE_SOURCES
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/add.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/conv.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/depthwise_conv.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/fully_connected.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/mul.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/pooling.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/softmax.cc
    ${SDK_TFLM_ROOT}/tensorflow/lite/micro/kernels/svdf.cc
)

# Function to create TFLM library
function(sdk_add_tflm_library TARGET_NAME)
    if(SDK_TFLM_FORCE_PREBUILT)
        # Use prebuilt library
        add_library(${TARGET_NAME} INTERFACE)
        target_include_directories(${TARGET_NAME} INTERFACE ${SDK_TFLM_INCLUDE_DIRS})
        foreach(DEF ${SDK_TFLM_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} INTERFACE ${DEF})
        endforeach()
        if(SDK_TFLM_USE_CMSIS_NN)
            target_compile_definitions(${TARGET_NAME} INTERFACE CMSIS_NN)
            target_include_directories(${TARGET_NAME} INTERFACE ${SDK_CMSIS_NN_INCLUDE_DIRS})
        endif()
        # Note: Prebuilt library should be linked directly in --start-group block
        message(STATUS "TFLM: Using prebuilt library (CMSIS-NN: ${SDK_TFLM_USE_CMSIS_NN})")
    else()
        # Build from source
        set(TFLM_SOURCES ${SDK_TFLM_C_SOURCES} ${SDK_TFLM_CXX_SOURCES})

        # Select kernels based on CMSIS-NN configuration
        if(SDK_TFLM_USE_CMSIS_NN)
            # Use CMSIS-NN optimized kernels
            list(APPEND TFLM_SOURCES ${SDK_TFLM_CMSIS_NN_SOURCES})
            set(KERNEL_TYPE "CMSIS-NN")
        else()
            # Use reference kernels
            list(APPEND TFLM_SOURCES ${SDK_TFLM_REFERENCE_SOURCES})
            set(KERNEL_TYPE "reference")
        endif()

        # Create static library
        add_library(${TARGET_NAME} STATIC ${TFLM_SOURCES})

        # Apply SDK common settings
        sdk_apply_common_settings(${TARGET_NAME})

        # Add include directories
        target_include_directories(${TARGET_NAME} PUBLIC ${SDK_TFLM_INCLUDE_DIRS})

        # Add compile definitions
        foreach(DEF ${SDK_TFLM_DEFINITIONS})
            target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
        endforeach()

        # Add CMSIS-NN specific settings
        if(SDK_TFLM_USE_CMSIS_NN)
            target_compile_definitions(${TARGET_NAME} PUBLIC CMSIS_NN)
            target_include_directories(${TARGET_NAME} PUBLIC ${SDK_CMSIS_NN_INCLUDE_DIRS})
        endif()

        # Suppress some warnings for TFLM code
        target_compile_options(${TARGET_NAME} PRIVATE
            -Wno-unused-parameter
            -Wno-sign-compare
        )

        # Count source files for status message
        list(LENGTH TFLM_SOURCES NUM_SOURCES)
        message(STATUS "TFLM: Building from source (${NUM_SOURCES} files, ${KERNEL_TYPE} kernels)")
    endif()
endfunction()

message(STATUS "TFLM module loaded (version: ${SDK_TFLM_VERSION})")
