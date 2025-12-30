# Flash module for Grove Vision AI V2 SDK
# Provides flash target for firmware upload via xmodem

# Use GROVE_ROOT_DIR from setup.cmake, or calculate if not set
if(NOT DEFINED GROVE_ROOT_DIR)
    get_filename_component(GROVE_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
endif()

if(NOT DEFINED GROVE_EXTERNAL_DIR)
    set(GROVE_EXTERNAL_DIR "${GROVE_ROOT_DIR}/external/sdk")
endif()

# xmodem script path
set(SDK_XMODEM_SCRIPT "${GROVE_EXTERNAL_DIR}/xmodem/xmodem_send.py")

# venv Python path
if(NOT DEFINED GROVE_PYTHON_VENV)
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
        set(GROVE_PYTHON_VENV "${GROVE_ROOT_DIR}/.venv/Scripts/python.exe")
    else()
        set(GROVE_PYTHON_VENV "${GROVE_ROOT_DIR}/.venv/bin/python")
    endif()
endif()

# Flash configuration (can be overridden via -D options)
set(GROVE_SERIAL_PORT "/dev/ttyACM0" CACHE STRING "Serial port for flashing")
set(GROVE_SERIAL_BAUDRATE "921600" CACHE STRING "Serial baudrate for flashing")

# Function to add flash target for a firmware
function(sdk_add_flash_target TARGET_NAME)
    # Use venv Python if available, otherwise find system Python
    if(EXISTS "${GROVE_PYTHON_VENV}")
        set(PYTHON_EXECUTABLE "${GROVE_PYTHON_VENV}")
    else()
        find_program(PYTHON_EXECUTABLE python3 python)
        if(NOT PYTHON_EXECUTABLE)
            message(WARNING "Python not found. Flash target will not work.")
            return()
        endif()
        message(WARNING "venv not found at ${GROVE_PYTHON_VENV}. Using system Python.")
    endif()

    add_custom_target(flash
        COMMAND ${PYTHON_EXECUTABLE} ${SDK_XMODEM_SCRIPT}
            --port=${GROVE_SERIAL_PORT}
            --baudrate=${GROVE_SERIAL_BAUDRATE}
            --protocol=xmodem
            --file=${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.img
        DEPENDS ${TARGET_NAME}
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Flashing ${TARGET_NAME}.img to ${GROVE_SERIAL_PORT}"
        USES_TERMINAL
    )
endfunction()

message(STATUS "Serial port: ${GROVE_SERIAL_PORT} (override with -DGROVE_SERIAL_PORT=...)")
