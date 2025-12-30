cmake_minimum_required(VERSION 3.16)
project(GroveVisionAI_V2 LANGUAGES C CXX ASM)

# Check and initialize git submodules if needed
find_package(Git QUIET)
if(GIT_FOUND)
    set(GROVE_SUBMODULE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/sdk")

    # Check if submodule directory exists and has content
    if(NOT EXISTS "${GROVE_SUBMODULE_DIR}/.git" AND NOT EXISTS "${GROVE_SUBMODULE_DIR}/EPII_CM55M_APP_S")
        message(STATUS "Git submodule not initialized. Running git submodule update --init --recursive...")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
            RESULT_VARIABLE GIT_SUBMOD_RESULT
        )
        if(NOT GIT_SUBMOD_RESULT EQUAL "0")
            message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}. "
                "Please run manually: git submodule update --init --recursive")
        endif()
        message(STATUS "Git submodule initialized successfully")
    else()
        # Check if submodule needs updating (empty directory)
        file(GLOB SUBMOD_FILES "${GROVE_SUBMODULE_DIR}/*")
        list(LENGTH SUBMOD_FILES SUBMOD_FILES_COUNT)
        if(SUBMOD_FILES_COUNT EQUAL 0)
            message(STATUS "Git submodule directory is empty. Running git submodule update --init --recursive...")
            execute_process(
                COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE GIT_SUBMOD_RESULT
            )
            if(NOT GIT_SUBMOD_RESULT EQUAL "0")
                message(FATAL_ERROR "git submodule update --init --recursive failed with ${GIT_SUBMOD_RESULT}.")
            endif()
            message(STATUS "Git submodule initialized successfully")
        endif()
    endif()
else()
    message(WARNING "Git not found. Cannot automatically initialize submodules. "
        "Please ensure external/sdk is populated.")
endif()

# Options
option(GROVE_DOWNLOAD_TOOLCHAIN "Download ARM GNU Toolchain if not found" ON)
option(GROVE_VERBOSE "Enable verbose build output" OFF)

set(GROVE_APP_TYPE "allon_sensor_tflm" CACHE STRING "Application type to build")
set_property(CACHE GROVE_APP_TYPE PROPERTY STRINGS
    allon_sensor_tflm
    allon_sensor_tflm_freertos
    allon_jpeg_encode
    tflm_fd_fm
    tflm_yolov8_od
    tflm_yolov8_pose
    tflm_peoplenet
    tflm_yolo11_od
    edge_impulse_firmware
    hello_world_freertos_tz_s_only
)

set(GROVE_OLEVEL "O2" CACHE STRING "Optimization level")
set_property(CACHE GROVE_OLEVEL PROPERTY STRINGS O0 O1 O2 O3 Os Ofast Og)

# Paths
set(GROVE_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(GROVE_EXTERNAL_DIR ${GROVE_ROOT_DIR}/external/sdk)
set(GROVE_TOOLCHAIN_DIR ${GROVE_ROOT_DIR}/toolchain)
set(GROVE_BUILD_DIR ${GROVE_ROOT_DIR}/build)
set(GROVE_OUTPUT_DIR ${GROVE_ROOT_DIR}/output)

# Source directory for firmware build
set(GROVE_FIRMWARE_DIR ${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S)

# Image generation directory
set(GROVE_IMAGE_GEN_DIR ${GROVE_EXTERNAL_DIR}/we2_image_gen_local)

# Detect platform
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
    set(GROVE_PLATFORM "macos")
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE GROVE_HOST_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GROVE_HOST_ARCH STREQUAL "arm64")
        set(GROVE_TOOLCHAIN_SUFFIX "darwin-arm64")
    else()
        set(GROVE_TOOLCHAIN_SUFFIX "darwin-x86_64")
    endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
    set(GROVE_PLATFORM "linux")
    execute_process(
        COMMAND uname -m
        OUTPUT_VARIABLE GROVE_HOST_ARCH
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if(GROVE_HOST_ARCH STREQUAL "aarch64")
        set(GROVE_TOOLCHAIN_SUFFIX "aarch64")
    else()
        set(GROVE_TOOLCHAIN_SUFFIX "x86_64")
    endif()
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    set(GROVE_PLATFORM "windows")
    set(GROVE_TOOLCHAIN_SUFFIX "mingw-w64-i686")
else()
    message(FATAL_ERROR "Unsupported platform: ${CMAKE_HOST_SYSTEM_NAME}")
endif()

set(GROVE_TOOLCHAIN_VERSION "13.2.Rel1")
set(GROVE_TOOLCHAIN_NAME "arm-gnu-toolchain-${GROVE_TOOLCHAIN_VERSION}-${GROVE_TOOLCHAIN_SUFFIX}-arm-none-eabi")
set(GROVE_TOOLCHAIN_PATH ${GROVE_TOOLCHAIN_DIR}/${GROVE_TOOLCHAIN_NAME})

# Detect Make command (use gmake on macOS if available)
if(GROVE_PLATFORM STREQUAL "macos")
    find_program(GROVE_MAKE_COMMAND gmake)
    if(NOT GROVE_MAKE_COMMAND)
        find_program(GROVE_MAKE_COMMAND make)
        message(WARNING "gmake not found, using make. If build fails due to make version, install gmake: brew install make")
    endif()
else()
    find_program(GROVE_MAKE_COMMAND make)
endif()

if(NOT GROVE_MAKE_COMMAND)
    message(FATAL_ERROR "make command not found")
endif()

message(STATUS "Using make command: ${GROVE_MAKE_COMMAND}")

# Check for toolchain
find_program(ARM_GCC arm-none-eabi-gcc
    PATHS ${GROVE_TOOLCHAIN_PATH}/bin
    NO_DEFAULT_PATH
)

if(NOT ARM_GCC AND GROVE_DOWNLOAD_TOOLCHAIN)
    message(STATUS "ARM toolchain not found. Running download script...")
    if(GROVE_PLATFORM STREQUAL "windows")
        execute_process(
            COMMAND powershell -ExecutionPolicy Bypass -File ${GROVE_ROOT_DIR}/scripts/download_toolchain.ps1
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE TOOLCHAIN_RESULT
        )
    else()
        execute_process(
            COMMAND ${GROVE_ROOT_DIR}/scripts/download_toolchain.sh
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE TOOLCHAIN_RESULT
        )
    endif()

    if(NOT TOOLCHAIN_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to download toolchain")
    endif()

    find_program(ARM_GCC arm-none-eabi-gcc
        PATHS ${GROVE_TOOLCHAIN_PATH}/bin
        NO_DEFAULT_PATH
    )
endif()

if(NOT ARM_GCC)
    message(FATAL_ERROR "ARM toolchain not found at ${GROVE_TOOLCHAIN_PATH}. "
        "Please run scripts/download_toolchain.sh (Linux/macOS) or scripts/download_toolchain.ps1 (Windows)")
endif()

message(STATUS "ARM GCC found: ${ARM_GCC}")

# Determine ELF output path
set(GROVE_ELF_OUTPUT_DIR "${GROVE_FIRMWARE_DIR}/obj_epii_evb_icv30_bdv10/gnu_epii_evb_WLCSP65")
set(GROVE_ELF_NAME "EPII_CM55M_gnu_epii_evb_WLCSP65_s.elf")
set(GROVE_ELF_PATH "${GROVE_ELF_OUTPUT_DIR}/${GROVE_ELF_NAME}")

# Build command options
set(GROVE_MAKE_OPTS
    "GNU_TOOLPATH=${GROVE_TOOLCHAIN_PATH}/bin"
    "APP_TYPE=${GROVE_APP_TYPE}"
    "OLEVEL=${GROVE_OLEVEL}"
)

if(GROVE_VERBOSE)
    list(APPEND GROVE_MAKE_OPTS "V=1")
else()
    list(APPEND GROVE_MAKE_OPTS "V=0")
endif()

# Main build target
add_custom_target(firmware ALL
    COMMAND ${GROVE_MAKE_COMMAND} ${GROVE_MAKE_OPTS}
    WORKING_DIRECTORY ${GROVE_FIRMWARE_DIR}
    COMMENT "Building Grove Vision AI V2 firmware (APP_TYPE=${GROVE_APP_TYPE})"
    USES_TERMINAL
)

# Clean target
add_custom_target(firmware_clean
    COMMAND ${GROVE_MAKE_COMMAND} ${GROVE_MAKE_OPTS} clean
    WORKING_DIRECTORY ${GROVE_FIRMWARE_DIR}
    COMMENT "Cleaning firmware build"
    USES_TERMINAL
)

# Image generation target
if(GROVE_PLATFORM STREQUAL "macos" AND GROVE_HOST_ARCH STREQUAL "arm64")
    set(GROVE_IMAGE_GEN_TOOL "${GROVE_IMAGE_GEN_DIR}/we2_local_image_gen_macOS_arm64")
elseif(GROVE_PLATFORM STREQUAL "windows")
    set(GROVE_IMAGE_GEN_TOOL "${GROVE_IMAGE_GEN_DIR}/we2_local_image_gen.exe")
else()
    set(GROVE_IMAGE_GEN_TOOL "${GROVE_IMAGE_GEN_DIR}/we2_local_image_gen")
endif()

# Ensure output directory exists
file(MAKE_DIRECTORY ${GROVE_OUTPUT_DIR})

add_custom_target(image
    COMMAND ${CMAKE_COMMAND} -E copy ${GROVE_ELF_PATH} ${GROVE_IMAGE_GEN_DIR}/input_case1_secboot/
    COMMAND ${GROVE_IMAGE_GEN_TOOL} project_case1_blp_wlcsp.json
    COMMAND ${CMAKE_COMMAND} -E copy ${GROVE_IMAGE_GEN_DIR}/output_case1_sec_wlcsp/output.img ${GROVE_OUTPUT_DIR}/firmware.img
    WORKING_DIRECTORY ${GROVE_IMAGE_GEN_DIR}
    DEPENDS firmware
    COMMENT "Generating firmware image"
    USES_TERMINAL
)

# Python venv setup
set(GROVE_VENV_DIR ${GROVE_ROOT_DIR}/.venv)
set(GROVE_XMODEM_SCRIPT ${GROVE_EXTERNAL_DIR}/xmodem/xmodem_send.py)

if(GROVE_PLATFORM STREQUAL "windows")
    set(GROVE_PYTHON_VENV ${GROVE_VENV_DIR}/Scripts/python.exe)
    set(GROVE_PIP_VENV ${GROVE_VENV_DIR}/Scripts/pip.exe)
else()
    set(GROVE_PYTHON_VENV ${GROVE_VENV_DIR}/bin/python)
    set(GROVE_PIP_VENV ${GROVE_VENV_DIR}/bin/pip)
endif()

# Auto-setup Python venv at configure time if not exists
if(NOT EXISTS "${GROVE_PYTHON_VENV}")
    message(STATUS "Setting up Python virtual environment...")
    find_program(PYTHON3_EXECUTABLE python3 python)
    if(NOT PYTHON3_EXECUTABLE)
        message(WARNING "Python3 not found. Run 'cmake --build . --target setup_venv' manually.")
    else()
        execute_process(
            COMMAND ${PYTHON3_EXECUTABLE} -m venv ${GROVE_VENV_DIR}
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE VENV_RESULT
        )
        if(VENV_RESULT EQUAL 0)
            message(STATUS "Installing Python packages...")
            execute_process(
                COMMAND ${GROVE_PIP_VENV} install --upgrade pip
                WORKING_DIRECTORY ${GROVE_ROOT_DIR}
                OUTPUT_QUIET
            )
            execute_process(
                COMMAND ${GROVE_PIP_VENV} install -r ${GROVE_EXTERNAL_DIR}/xmodem/requirements.txt
                WORKING_DIRECTORY ${GROVE_ROOT_DIR}
                RESULT_VARIABLE PIP_RESULT
            )
            if(PIP_RESULT EQUAL 0)
                message(STATUS "Python virtual environment ready at ${GROVE_VENV_DIR}")
            else()
                message(WARNING "Failed to install Python packages")
            endif()
        else()
            message(WARNING "Failed to create virtual environment")
        endif()
    endif()
else()
    message(STATUS "Python virtual environment: ${GROVE_VENV_DIR} (exists)")
endif()

# Flash target
add_custom_target(flash
    COMMAND ${GROVE_PYTHON_VENV} ${GROVE_XMODEM_SCRIPT}
        --port=${GROVE_SERIAL_PORT}
        --baudrate=921600
        --protocol=xmodem
        --file=${GROVE_OUTPUT_DIR}/firmware.img
    WORKING_DIRECTORY ${GROVE_ROOT_DIR}
    DEPENDS image
    COMMENT "Flashing firmware to device"
    USES_TERMINAL
)

# Manual setup_venv target (for recreating venv)
add_custom_target(setup_venv
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${GROVE_VENV_DIR}
    COMMAND ${PYTHON3_EXECUTABLE} -m venv ${GROVE_VENV_DIR}
    COMMAND ${GROVE_PIP_VENV} install --upgrade pip
    COMMAND ${GROVE_PIP_VENV} install -r ${GROVE_EXTERNAL_DIR}/xmodem/requirements.txt
    WORKING_DIRECTORY ${GROVE_ROOT_DIR}
    COMMENT "Recreating Python virtual environment"
    USES_TERMINAL
)

# Print configuration
message(STATUS "")
message(STATUS "=== Grove Vision AI V2 Build Configuration ===")
message(STATUS "Platform: ${GROVE_PLATFORM} (${GROVE_HOST_ARCH})")
message(STATUS "Toolchain: ${GROVE_TOOLCHAIN_PATH}")
message(STATUS "Make command: ${GROVE_MAKE_COMMAND}")
message(STATUS "App type: ${GROVE_APP_TYPE}")
message(STATUS "Optimization: ${GROVE_OLEVEL}")
message(STATUS "")
message(STATUS "Available targets:")
message(STATUS "  cmake --build . --target firmware       - Build firmware")
message(STATUS "  cmake --build . --target firmware_clean - Clean build")
message(STATUS "  cmake --build . --target image          - Generate flashable image")
message(STATUS "  cmake --build . --target setup_venv     - Recreate Python venv")
message(STATUS "  cmake --build . --target flash          - Flash to device (set GROVE_SERIAL_PORT)")
message(STATUS "")
