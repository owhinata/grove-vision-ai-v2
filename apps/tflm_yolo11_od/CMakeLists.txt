# TFLM YOLO11 Object Detection Application (No OS)
# Camera sensor with YOLO11 object detection using TensorFlow Lite Micro
cmake_minimum_required(VERSION 3.16)

# Setup development environment (submodules, toolchain, venv)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/setup.cmake)
grove_setup_all()

# Set toolchain before project()
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/arm-none-eabi-gcc.cmake")

project(tflm_yolo11_od LANGUAGES C CXX ASM)

# SDK root path
set(SDK_ROOT "${GROVE_EXTERNAL_DIR}/EPII_CM55M_APP_S")

# =============================================================================
# SDK configuration (from tflm_yolo11_od.mk)
# =============================================================================
set(SDK_BOARD "epii_evb")
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)  # Security Only
set(SDK_SEMIHOST OFF)
set(SDK_USE_FREERTOS OFF)  # No FreeRTOS - uses event handler

# TFLM version - use tflmtag2412_u55tag2411 for YOLO11
set(SDK_TFLM_VERSION "tflmtag2412_u55tag2411" CACHE STRING "TFLM version" FORCE)

# Event handler configuration
set(SDK_EVT_DATAPATH ON CACHE BOOL "Enable datapath event handling" FORCE)

# =============================================================================
# Library build options
# =============================================================================
option(SDK_TFLM_FORCE_PREBUILT "Use prebuilt TFLM library" OFF)
option(SDK_CMSIS_NN_FORCE_PREBUILT "Use prebuilt CMSIS-NN library" OFF)
set(SDK_TFLM_USE_CMSIS_NN ON)

# CIS sensor model selection (default: cis_imx219)
set(CIS_SENSOR_MODEL "cis_imx219" CACHE STRING "Camera sensor model")
set_property(CACHE CIS_SENSOR_MODEL PROPERTY STRINGS
    cis_hm0360
    cis_ov5647
    cis_imx219
)

# Model file selection
set(MODEL_FILE "yolo11n_full_integer_quant_vela_imgz_224_kris_nopost_241230.tflite"
    CACHE STRING "YOLO11 model file")
set_property(CACHE MODEL_FILE PROPERTY STRINGS
    "yolo11n_full_integer_quant_192_241219_batch_matmul_vela.tflite"
    "yolo11n_full_integer_quant_vela_imgz_224_kris_nopost_241230.tflite"
)

# Model flash address (XIP mapped address for model loading)
set(MODEL_FLASH_ADDR "0x3AB7B000" CACHE STRING "Model flash address (XIP mapped)")

# =============================================================================
# Include SDK modules
# =============================================================================
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/device.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/board.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/interface.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/common.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/trustzone.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/library.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/event_handler.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/cmsis_nn.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/tflm.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/linker.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/image.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/sdk/flash.cmake)

# =============================================================================
# Create SDK libraries
# =============================================================================

# Always built from source
sdk_add_device_library(device)
sdk_add_board_library(board)
sdk_add_interface_library(interface)
sdk_add_common_library(common)
sdk_add_trustzone_cfg_library(trustzone_cfg)
sdk_add_event_handler_library(event_handler)

# Interface libraries (for includes/defines, link prebuilt)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_sensordp_library(sensordp)
sdk_add_spi_ptl_library(spi_ptl)
sdk_add_spi_eeprom_library(spi_eeprom)
sdk_add_extdevice_library(extdevice)
sdk_add_driver_library(driver)
sdk_add_img_proc_library(img_proc)

# Libraries with source build support
sdk_add_tflm_library(tflm_lib)

# CMSIS-NN library (built from source when SDK_TFLM_USE_CMSIS_NN=ON)
if(SDK_TFLM_USE_CMSIS_NN AND NOT SDK_CMSIS_NN_FORCE_PREBUILT)
    sdk_add_cmsis_nn_library(cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

# =============================================================================
# Application configuration
# =============================================================================

# SDK scenario app source directory
set(SDK_APP_DIR ${SDK_ROOT}/app/scenario_app/tflm_yolo11_od)

# CIS sensor source directory (from SDK)
set(CIS_SENSOR_DIR ${SDK_APP_DIR}/cis_sensor/${CIS_SENSOR_MODEL})

# Application sources (from tflm_yolo11_od.mk)
set(APP_SOURCES
    ${SDK_ROOT}/app/main.c
    ${SDK_APP_DIR}/tflm_yolo11_od.c
    ${SDK_APP_DIR}/hardfault_handler.c
    ${SDK_APP_DIR}/memory_manage.c
    ${SDK_APP_DIR}/cvapp_yolo11n_ob.cpp
    ${SDK_APP_DIR}/send_result.cpp
    ${SDK_APP_DIR}/yolo_postprocessing.cc
    # CIS sensor sources (from SDK)
    ${CIS_SENSOR_DIR}/cisdp_sensor.c
)

# Create executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK common settings to application
sdk_apply_common_settings(${PROJECT_NAME})

# Application specific definitions (from tflm_yolo11_od.mk)
target_compile_definitions(${PROJECT_NAME} PRIVATE
    TFLM_YOLO11_OD
    DBG_MORE
    HM_COMMON
    LIB_EVENT
    UART_SEND_ALOGO_RESEULT
    audvidpre_ret_pll400_timer1
)

# Add CIS_IMX define for IMX sensors
if(CIS_SENSOR_MODEL MATCHES "cis_imx.*")
    target_compile_definitions(${PROJECT_NAME} PRIVATE CIS_IMX)
endif()

# Application include directories
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SDK_APP_DIR}
    ${CIS_SENSOR_DIR}
    ${SDK_ROOT}/app
    ${SDK_ROOT}/app/scenario_app
    # External device support (CIS)
    ${SDK_ROOT}/external
    ${SDK_ROOT}/external/cis
    ${SDK_ROOT}/external/cis/hm_common
    # hxevent library
    ${SDK_ROOT}/library/hxevent
    # img_proc library
    ${SDK_ROOT}/library/img_proc
)

# =============================================================================
# Link libraries
# =============================================================================
# Use --start-group/--end-group to resolve circular dependencies

# Prebuilt hxevent library path
set(SDK_LIB_HXEVENT_PREBUILT ${SDK_ROOT}/prebuilt_libs/gnu/libhxevent.a)

# Build list of libraries for --start-group block
set(LINK_LIBS_GROUP
    # Built from source
    board
    device
    interface
    common
    trustzone_cfg
    event_handler
    # Prebuilt libraries
    ${SDK_LIB_DRIVER_PREBUILT}
    ${SDK_LIB_PWRMGMT_PREBUILT}
    ${SDK_LIB_SENSORDP_PREBUILT}
    ${SDK_LIB_EXTDEVICE_PREBUILT}
    ${SDK_LIB_SPI_PTL_PREBUILT}
    ${SDK_LIB_SPI_EEPROM_PREBUILT}
    ${SDK_LIB_IMG_PROC_PREBUILT}
    ${SDK_LIB_HXEVENT_PREBUILT}
    ${SDK_ROOT}/prebuilt_libs/gnu/libcustomer.a
)

# Add TFLM and CMSIS-NN libraries
if(SDK_TFLM_FORCE_PREBUILT)
    list(APPEND LINK_LIBS_GROUP ${SDK_TFLM_PREBUILT})
    if(SDK_TFLM_USE_CMSIS_NN AND SDK_CMSIS_NN_FORCE_PREBUILT)
        list(APPEND LINK_LIBS_GROUP ${SDK_CMSIS_NN_PREBUILT})
    endif()
else()
    list(APPEND LINK_LIBS_GROUP tflm_lib)
    if(SDK_TFLM_USE_CMSIS_NN)
        if(SDK_CMSIS_NN_FORCE_PREBUILT)
            list(APPEND LINK_LIBS_GROUP ${SDK_CMSIS_NN_PREBUILT})
        else()
            list(APPEND LINK_LIBS_GROUP cmsis_nn_${SDK_CMSIS_NN_VERSION})
        endif()
    endif()
endif()

# Interface library list for includes/defines propagation
set(INTERFACE_LIBS
    pwrmgmt
    sensordp
    spi_ptl
    spi_eeprom
    extdevice
    img_proc
    event_handler
    tflm_lib
)
if(SDK_TFLM_USE_CMSIS_NN AND NOT SDK_CMSIS_NN_FORCE_PREBUILT AND NOT SDK_TFLM_FORCE_PREBUILT)
    list(APPEND INTERFACE_LIBS cmsis_nn_${SDK_CMSIS_NN_VERSION})
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE
    # Interface libraries (for includes/defines propagation)
    ${INTERFACE_LIBS}
    # Actual link group
    -Wl,--start-group
    ${LINK_LIBS_GROUP}
    -lm -lc_nano -lgcc -lstdc++_nano
    -Wl,--end-group
)

# =============================================================================
# Build artifacts
# =============================================================================

# Apply linker settings (custom linker script for this app)
sdk_apply_linker_settings(${PROJECT_NAME}
    LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/tflm_yolo11_od.ld
)

# Add image generation
sdk_add_image_generation(${PROJECT_NAME})

# =============================================================================
# Flash target (firmware + model)
# =============================================================================

# Model file path
set(MODEL_ZOO_DIR "${GROVE_EXTERNAL_DIR}/model_zoo/tflm_yolo11_od")
set(MODEL_PATH "${MODEL_ZOO_DIR}/${MODEL_FILE}")

# Calculate model flash offset (XIP address - flash base)
# Flash base: 0x3A000000, so offset = MODEL_FLASH_ADDR - 0x3A000000
math(EXPR MODEL_FLASH_OFFSET "${MODEL_FLASH_ADDR} - 0x3A000000" OUTPUT_FORMAT HEXADECIMAL)

# Custom flash target that writes both firmware and model
# Model format: --model="bin_file flash_address_hex offset_hex"
add_custom_target(flash
    COMMAND ${CMAKE_COMMAND} -E echo "Flashing firmware and model..."
    COMMAND ${GROVE_PYTHON_VENV} ${SDK_XMODEM_SCRIPT}
        --port=${GROVE_SERIAL_PORT}
        --baudrate=${GROVE_SERIAL_BAUDRATE}
        --protocol=xmodem
        --file=${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.img
        "--model=${MODEL_PATH} ${MODEL_FLASH_OFFSET} 0"
    DEPENDS ${PROJECT_NAME}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Flashing ${PROJECT_NAME}.img and model to ${GROVE_SERIAL_PORT}"
    USES_TERMINAL
)

# Separate target to flash only the model
add_custom_target(flash-model
    COMMAND ${CMAKE_COMMAND} -E echo "Flashing model to ${MODEL_FLASH_OFFSET}..."
    COMMAND ${GROVE_PYTHON_VENV} ${SDK_XMODEM_SCRIPT}
        --port=${GROVE_SERIAL_PORT}
        --baudrate=${GROVE_SERIAL_BAUDRATE}
        --protocol=xmodem
        "--model=${MODEL_PATH} ${MODEL_FLASH_OFFSET} 0"
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Flashing model ${MODEL_FILE} to ${GROVE_SERIAL_PORT}"
    USES_TERMINAL
)

# =============================================================================
# Print configuration
# =============================================================================
message(STATUS "")
message(STATUS "=== Application Configuration ===")
message(STATUS "Application: ${PROJECT_NAME}")
message(STATUS "SDK Root: ${SDK_ROOT}")
message(STATUS "CIS Sensor: ${CIS_SENSOR_MODEL}")
message(STATUS "Event Handler: datapath=${SDK_EVT_DATAPATH}")
message(STATUS "TFLM: ${SDK_TFLM_VERSION} (prebuilt: ${SDK_TFLM_FORCE_PREBUILT})")
message(STATUS "CMSIS-NN: ${SDK_TFLM_USE_CMSIS_NN} (prebuilt: ${SDK_CMSIS_NN_FORCE_PREBUILT})")
message(STATUS "TrustZone: ${SDK_TRUSTZONE_TYPE} (FW_TYPE=${SDK_TRUSTZONE_FW_TYPE})")
message(STATUS "Model: ${MODEL_FILE}")
message(STATUS "Model Flash Addr: ${MODEL_FLASH_ADDR} (offset: ${MODEL_FLASH_OFFSET})")
message(STATUS "")
