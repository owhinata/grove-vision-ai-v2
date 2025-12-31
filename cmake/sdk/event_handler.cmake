# Event Handler library for Grove Vision AI V2 SDK
# Provides event-driven framework for sensor and peripheral handling

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including event_handler.cmake")
endif()

# Include base SDK configuration if not already included
if(NOT DEFINED SDK_COMMON_INCLUDE_DIRS)
    include(${CMAKE_CURRENT_LIST_DIR}/sdk_base.cmake)
endif()

# Event handler source directory
set(SDK_EVENT_HANDLER_DIR ${SDK_ROOT}/app/scenario_app/event_handler)

# Event handler configuration options
option(SDK_EVT_DATAPATH "Enable datapath event handling" ON)
option(SDK_EVT_I2CCOMM "Enable I2C communication event handling" OFF)
option(SDK_EVT_UARTCOMM "Enable UART communication event handling" OFF)
option(SDK_EVT_CM55STIMER "Enable CM55S timer event handling" OFF)
option(SDK_EVT_CM55MTIMER "Enable CM55M timer event handling" OFF)
option(SDK_EVT_CM55MMB "Enable CM55M mailbox event handling" OFF)

# Function to create event handler library
function(sdk_add_event_handler_library TARGET_NAME)
    # Base sources (always included)
    # From scenario_app.mk: all .c files in event_handler directory are compiled
    set(EVENT_HANDLER_SOURCES
        ${SDK_EVENT_HANDLER_DIR}/event_handler.c
        ${SDK_EVENT_HANDLER_DIR}/evt_reboot_api.c
    )

    # Include directories
    set(EVENT_HANDLER_INCLUDES
        ${SDK_EVENT_HANDLER_DIR}
        ${SDK_ROOT}/app  # For WE2_debug.h
    )

    # Compile definitions
    set(EVENT_HANDLER_DEFINES "")

    # Add optional modules based on configuration
    if(SDK_EVT_DATAPATH)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_datapath/evt_datapath.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_datapath
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_DATAPATH)
    endif()

    if(SDK_EVT_I2CCOMM)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_i2ccomm/evt_i2ccomm.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_i2ccomm
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_I2CS_0_CMD)
    endif()

    if(SDK_EVT_UARTCOMM)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_uartcomm/evt_uartcomm.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_uartcomm
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_UARTCOMM)
    endif()

    if(SDK_EVT_CM55STIMER)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55stimer/evt_cm55stimer.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55stimer
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_CM55STIMER)
    endif()

    if(SDK_EVT_CM55MTIMER)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55mtimer/evt_cm55mtimer.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55mtimer
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_CM55MTIMER)
    endif()

    if(SDK_EVT_CM55MMB)
        list(APPEND EVENT_HANDLER_SOURCES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55mmb/evt_cm55mmb.c
        )
        list(APPEND EVENT_HANDLER_INCLUDES
            ${SDK_EVENT_HANDLER_DIR}/evt_cm55mmb
        )
        list(APPEND EVENT_HANDLER_DEFINES EVT_CM55MMB)
    endif()

    # Create static library
    add_library(${TARGET_NAME} STATIC ${EVENT_HANDLER_SOURCES})

    # Apply SDK common settings
    sdk_apply_common_settings(${TARGET_NAME})

    # Add include directories
    target_include_directories(${TARGET_NAME} PUBLIC
        ${EVENT_HANDLER_INCLUDES}
        ${SDK_ROOT}/library/hxevent
        ${SDK_ROOT}/library/sensordp/inc
        ${SDK_ROOT}/library/pwrmgmt
        ${SDK_ROOT}/library/pwrmgmt/seconly_inc
    )

    # Add compile definitions
    foreach(DEF ${EVENT_HANDLER_DEFINES})
        target_compile_definitions(${TARGET_NAME} PUBLIC ${DEF})
    endforeach()
endfunction()

message(STATUS "Event handler module loaded")
