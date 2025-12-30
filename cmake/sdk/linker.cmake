# Linker configuration module for Grove Vision AI V2 SDK
# Handles linker script preprocessing and linker flags

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including linker.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Linker script directory
set(SDK_LINKER_SCRIPT_DIR ${SDK_ROOT}/linker_script/gcc)

# Select appropriate linker script based on TrustZone configuration
if(SDK_TRUSTZONE)
    if(SDK_TRUSTZONE_TYPE STREQUAL "security")
        if(SDK_TRUSTZONE_FW_TYPE EQUAL 1)
            set(SDK_LINKER_SCRIPT_TEMPLATE ${SDK_LINKER_SCRIPT_DIR}/TrustZone_S_ONLY.ld)
        else()
            set(SDK_LINKER_SCRIPT_TEMPLATE ${SDK_LINKER_SCRIPT_DIR}/TrustZone_S.ld)
        endif()
    else()
        set(SDK_LINKER_SCRIPT_TEMPLATE ${SDK_LINKER_SCRIPT_DIR}/NoTrustZone.ld)
    endif()
else()
    set(SDK_LINKER_SCRIPT_TEMPLATE ${SDK_LINKER_SCRIPT_DIR}/NoTrustZone.ld)
endif()

# Function to apply linker settings to a target
function(sdk_apply_linker_settings TARGET_NAME)
    # Parse optional arguments
    set(options "")
    set(oneValueArgs LINKER_SCRIPT)
    set(multiValueArgs "")
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Use provided linker script or default
    if(ARG_LINKER_SCRIPT)
        set(LD_SCRIPT ${ARG_LINKER_SCRIPT})
    else()
        set(LD_SCRIPT ${SDK_LINKER_SCRIPT_TEMPLATE})
    endif()

    # Generate preprocessed linker script
    get_filename_component(LD_NAME ${LD_SCRIPT} NAME_WE)
    set(PREPROCESSED_LD ${CMAKE_CURRENT_BINARY_DIR}/${LD_NAME}_preprocessed.ld)

    # Build include paths list for preprocessor
    set(PP_ARGS "")
    foreach(INC_DIR ${SDK_COMMON_INCLUDE_DIRS})
        list(APPEND PP_ARGS "-I${INC_DIR}")
    endforeach()

    # Build defines list for preprocessor
    foreach(DEF ${SDK_COMMON_DEFINITIONS})
        list(APPEND PP_ARGS "-D${DEF}")
    endforeach()

    # Create custom target for linker script preprocessing
    set(LD_TARGET ${TARGET_NAME}_linker_script)
    add_custom_target(${LD_TARGET}
        COMMAND ${CMAKE_C_COMPILER} -E -P -x c
                ${PP_ARGS}
                ${LD_SCRIPT}
                -o ${PREPROCESSED_LD}
        DEPENDS ${LD_SCRIPT}
        COMMENT "Preprocessing linker script for ${TARGET_NAME}"
        BYPRODUCTS ${PREPROCESSED_LD}
    )

    # Add dependency
    add_dependencies(${TARGET_NAME} ${LD_TARGET})

    # Apply linker script
    target_link_options(${TARGET_NAME} PRIVATE
        -T${PREPROCESSED_LD}
        -Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.map
    )

    # Add post-build commands for binary generation
    # Extract only ROM sections to avoid huge gaps between ROM (0x10000000) and RAM (0x30000000)
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        COMMAND ${CMAKE_OBJCOPY} -O binary
            -j .table -j .text -j .rodata -j .ARM.exidx -j .copy.table -j .zero.table
            $<TARGET_FILE:${TARGET_NAME}> ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.bin
        COMMAND ${CMAKE_SIZE} $<TARGET_FILE:${TARGET_NAME}>
        COMMENT "Generating binary and size info for ${TARGET_NAME}"
    )
endfunction()

message(STATUS "SDK Linker script: ${SDK_LINKER_SCRIPT_TEMPLATE}")
