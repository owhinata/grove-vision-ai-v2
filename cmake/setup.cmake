# Grove Vision AI V2 Development Environment Setup
# Automatically sets up git submodules, toolchain, and Python venv

# Detect project root directory (parent of cmake/)
get_filename_component(GROVE_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)

# Paths
set(GROVE_EXTERNAL_DIR "${GROVE_ROOT_DIR}/external/sdk")
set(GROVE_TOOLCHAIN_DIR "${GROVE_ROOT_DIR}/toolchain")
set(GROVE_VENV_DIR "${GROVE_ROOT_DIR}/.venv")

# Toolchain version
set(GROVE_TOOLCHAIN_VERSION "13.2.Rel1")

# =============================================================================
# Platform Detection
# =============================================================================
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

set(GROVE_TOOLCHAIN_NAME "arm-gnu-toolchain-${GROVE_TOOLCHAIN_VERSION}-${GROVE_TOOLCHAIN_SUFFIX}-arm-none-eabi")
set(GROVE_TOOLCHAIN_PATH "${GROVE_TOOLCHAIN_DIR}/${GROVE_TOOLCHAIN_NAME}")

# Python venv paths
if(GROVE_PLATFORM STREQUAL "windows")
    set(GROVE_PYTHON_VENV "${GROVE_VENV_DIR}/Scripts/python.exe")
    set(GROVE_PIP_VENV "${GROVE_VENV_DIR}/Scripts/pip.exe")
else()
    set(GROVE_PYTHON_VENV "${GROVE_VENV_DIR}/bin/python")
    set(GROVE_PIP_VENV "${GROVE_VENV_DIR}/bin/pip")
endif()

# =============================================================================
# 1. Git Submodule Initialization
# =============================================================================
function(grove_setup_submodules)
    find_package(Git QUIET)
    if(NOT GIT_FOUND)
        message(WARNING "Git not found. Cannot automatically initialize submodules.")
        return()
    endif()

    set(SUBMODULE_DIR "${GROVE_EXTERNAL_DIR}")

    # Check if submodule needs initialization
    if(NOT EXISTS "${SUBMODULE_DIR}/.git" AND NOT EXISTS "${SUBMODULE_DIR}/EPII_CM55M_APP_S")
        message(STATUS "Git submodule not initialized. Running git submodule update --init --recursive...")
        execute_process(
            COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE GIT_RESULT
        )
        if(NOT GIT_RESULT EQUAL "0")
            message(FATAL_ERROR "git submodule update --init --recursive failed. Please run manually.")
        endif()
        message(STATUS "Git submodule initialized successfully")
    else()
        # Check if submodule directory is empty
        file(GLOB SUBMOD_FILES "${SUBMODULE_DIR}/*")
        list(LENGTH SUBMOD_FILES SUBMOD_FILES_COUNT)
        if(SUBMOD_FILES_COUNT EQUAL 0)
            message(STATUS "Git submodule directory is empty. Running git submodule update...")
            execute_process(
                COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${GROVE_ROOT_DIR}
                RESULT_VARIABLE GIT_RESULT
            )
            if(NOT GIT_RESULT EQUAL "0")
                message(FATAL_ERROR "git submodule update failed.")
            endif()
            message(STATUS "Git submodule initialized successfully")
        endif()
    endif()
endfunction()

# =============================================================================
# 2. Toolchain Download
# =============================================================================
function(grove_setup_toolchain)
    # Check if toolchain exists
    find_program(ARM_GCC arm-none-eabi-gcc
        PATHS "${GROVE_TOOLCHAIN_PATH}/bin"
        NO_DEFAULT_PATH
    )

    if(ARM_GCC)
        message(STATUS "ARM toolchain found: ${ARM_GCC}")
        return()
    endif()

    message(STATUS "ARM toolchain not found. Downloading...")

    if(GROVE_PLATFORM STREQUAL "windows")
        execute_process(
            COMMAND powershell -ExecutionPolicy Bypass -File "${GROVE_ROOT_DIR}/scripts/download_toolchain.ps1"
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE TOOLCHAIN_RESULT
        )
    else()
        execute_process(
            COMMAND "${GROVE_ROOT_DIR}/scripts/download_toolchain.sh"
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE TOOLCHAIN_RESULT
        )
    endif()

    if(NOT TOOLCHAIN_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to download toolchain. Run scripts/download_toolchain.sh manually.")
    endif()

    # Verify installation
    find_program(ARM_GCC arm-none-eabi-gcc
        PATHS "${GROVE_TOOLCHAIN_PATH}/bin"
        NO_DEFAULT_PATH
    )

    if(NOT ARM_GCC)
        message(FATAL_ERROR "Toolchain download completed but arm-none-eabi-gcc not found at ${GROVE_TOOLCHAIN_PATH}")
    endif()

    message(STATUS "ARM toolchain installed: ${ARM_GCC}")
endfunction()

# =============================================================================
# 3. Python Virtual Environment Setup
# =============================================================================
function(grove_setup_venv)
    if(EXISTS "${GROVE_PYTHON_VENV}")
        message(STATUS "Python venv found: ${GROVE_VENV_DIR}")
        return()
    endif()

    message(STATUS "Setting up Python virtual environment...")

    find_program(PYTHON3_EXECUTABLE python3 python)
    if(NOT PYTHON3_EXECUTABLE)
        message(WARNING "Python3 not found. Cannot setup venv automatically.")
        return()
    endif()

    # Create venv
    execute_process(
        COMMAND ${PYTHON3_EXECUTABLE} -m venv ${GROVE_VENV_DIR}
        WORKING_DIRECTORY ${GROVE_ROOT_DIR}
        RESULT_VARIABLE VENV_RESULT
    )

    if(NOT VENV_RESULT EQUAL 0)
        message(WARNING "Failed to create Python venv")
        return()
    endif()

    # Upgrade pip
    execute_process(
        COMMAND ${GROVE_PIP_VENV} install --upgrade pip
        WORKING_DIRECTORY ${GROVE_ROOT_DIR}
        OUTPUT_QUIET
        ERROR_QUIET
    )

    # Install requirements
    set(REQUIREMENTS_FILE "${GROVE_EXTERNAL_DIR}/xmodem/requirements.txt")
    if(EXISTS "${REQUIREMENTS_FILE}")
        message(STATUS "Installing Python packages from ${REQUIREMENTS_FILE}...")
        execute_process(
            COMMAND ${GROVE_PIP_VENV} install -r ${REQUIREMENTS_FILE}
            WORKING_DIRECTORY ${GROVE_ROOT_DIR}
            RESULT_VARIABLE PIP_RESULT
        )
        if(PIP_RESULT EQUAL 0)
            message(STATUS "Python venv ready: ${GROVE_VENV_DIR}")
        else()
            message(WARNING "Failed to install some Python packages")
        endif()
    else()
        message(STATUS "Python venv created: ${GROVE_VENV_DIR}")
    endif()
endfunction()

# =============================================================================
# Run All Setup Steps
# =============================================================================
function(grove_setup_all)
    message(STATUS "")
    message(STATUS "=== Grove Vision AI V2 Development Environment Setup ===")
    message(STATUS "Project root: ${GROVE_ROOT_DIR}")
    message(STATUS "Platform: ${GROVE_PLATFORM} (${GROVE_HOST_ARCH})")
    message(STATUS "")

    grove_setup_submodules()
    grove_setup_toolchain()
    grove_setup_venv()

    message(STATUS "")
    message(STATUS "Setup complete!")
    message(STATUS "")
endfunction()

# Variables are automatically available to the including file
# since include() shares the same scope as the caller
