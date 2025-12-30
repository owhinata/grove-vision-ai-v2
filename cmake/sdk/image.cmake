# Image generation module for Grove Vision AI V2 SDK
# Handles flashable image (.img) generation using we2_local_image_gen tool
# Runs in build directory to avoid polluting external/sdk

# Use GROVE_EXTERNAL_DIR from setup.cmake if available
if(NOT DEFINED GROVE_EXTERNAL_DIR)
    if(DEFINED SDK_ROOT)
        get_filename_component(GROVE_EXTERNAL_DIR "${SDK_ROOT}/.." ABSOLUTE)
    else()
        get_filename_component(GROVE_EXTERNAL_DIR "${CMAKE_CURRENT_LIST_DIR}/../../external/sdk" ABSOLUTE)
    endif()
endif()

# Image generation tool source directory
set(SDK_IMAGE_GEN_SRC_DIR "${GROVE_EXTERNAL_DIR}/we2_image_gen_local")

# Select image generation tool based on platform
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    execute_process(COMMAND uname -m OUTPUT_VARIABLE HOST_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
    if(HOST_ARCH STREQUAL "arm64")
        set(SDK_IMAGE_GEN_TOOL_NAME "we2_local_image_gen_macOS_arm64")
    else()
        set(SDK_IMAGE_GEN_TOOL_NAME "we2_local_image_gen")
    endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(SDK_IMAGE_GEN_TOOL_NAME "we2_local_image_gen.exe")
else()
    set(SDK_IMAGE_GEN_TOOL_NAME "we2_local_image_gen")
endif()

# Function to add image generation to a target
# This creates a flashable .img file from the compiled ELF
# All operations are performed in the build directory
function(sdk_add_image_generation TARGET_NAME)
    # Working directory for image generation (inside build dir)
    set(IMAGE_GEN_WORK_DIR "${CMAKE_CURRENT_BINARY_DIR}/image_gen")
    set(IMAGE_GEN_INPUT_DIR "${IMAGE_GEN_WORK_DIR}/input_case1_secboot")
    set(IMAGE_GEN_OUTPUT_DIR "${IMAGE_GEN_WORK_DIR}/output_case1_sec_wlcsp")

    # Setup image generation working directory at configure time
    # Copy entire directory structure (tool requires write access for temp files)
    if(NOT EXISTS "${IMAGE_GEN_WORK_DIR}/${SDK_IMAGE_GEN_TOOL_NAME}")
        message(STATUS "Setting up image generation working directory...")
        file(COPY "${SDK_IMAGE_GEN_SRC_DIR}/" DESTINATION "${IMAGE_GEN_WORK_DIR}")
    endif()

    set(IMAGE_GEN_TOOL "${IMAGE_GEN_WORK_DIR}/${SDK_IMAGE_GEN_TOOL_NAME}")

    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
        # Copy ELF to input directory
        COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${TARGET_NAME}>
            ${IMAGE_GEN_INPUT_DIR}/EPII_CM55M_gnu_epii_evb_WLCSP65_s.elf
        # Run image generation tool
        COMMAND ${IMAGE_GEN_TOOL} project_case1_blp_wlcsp.json
        # Copy output image to build directory
        COMMAND ${CMAKE_COMMAND} -E copy ${IMAGE_GEN_OUTPUT_DIR}/output.img
            ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.img
        WORKING_DIRECTORY ${IMAGE_GEN_WORK_DIR}
        COMMENT "Generating flashable image ${TARGET_NAME}.img"
    )
endfunction()

message(STATUS "Image generation tool: ${SDK_IMAGE_GEN_SRC_DIR}/${SDK_IMAGE_GEN_TOOL_NAME}")
