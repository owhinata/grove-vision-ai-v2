# Drivers module for Grove Vision AI V2 SDK
# Provides driver includes and IP peripheral definitions
#
# This module creates an INTERFACE library that provides:
# - Driver include directories
# - IP_* defines for peripheral access
# - IP_INST_* defines for peripheral instances
#
# Depends on: cmsis_core

# Ensure SDK_ROOT is defined
if(NOT DEFINED SDK_ROOT)
    message(FATAL_ERROR "SDK_ROOT must be defined before including drivers.cmake")
endif()

# Include dependencies
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)

# Drivers directories
set(SDK_DRIVERS_DIR ${SDK_ROOT}/drivers)

# Drivers include directories (PUBLIC - propagate to dependents)
set(SDK_DRIVERS_INCLUDE_DIRS
    ${SDK_DRIVERS_DIR}
    ${SDK_DRIVERS_DIR}/inc
)

# TrustZone security specific includes
if(SDK_TRUSTZONE AND SDK_TRUSTZONE_TYPE STREQUAL "security")
    list(APPEND SDK_DRIVERS_INCLUDE_DIRS
        ${SDK_DRIVERS_DIR}/seconly_inc
    )
endif()

# Driver IP definitions (required for peripheral access)
# These correspond to DRIVERS_IP_LIST in the SDK makefile
set(SDK_DRIVERS_IP_LIST
    scu uart spi i3c_mst isp iic mb timer watchdog rtc
    cdm edm jpeg xdma dp inp tpg inp1bitparser sensorctrl
    gpio i2s pdm i3c_slv vad swreg_aon swreg_lsc dma
    ppc pmu mpc hxautoi2c_mst csirx csitx adcc pwm
    inpovparser adcc_hv u55 2x2 5x5
)

# Driver IP instance definitions (required for peripheral initialization)
# These correspond to DRIVERS_IP_INSTANCE in the SDK makefile
# (see drivers/mk_cfg/drv_onecore_cm55m_s_only.mk)
set(SDK_DRIVERS_IP_INSTANCE
    # RTC instances
    RTC0 RTC1 RTC2
    # Timer instances
    TIMER0 TIMER1 TIMER2 TIMER3 TIMER4 TIMER5 TIMER6 TIMER7 TIMER8
    # Watchdog instances
    WDT0 WDT1
    # DMA instances
    DMA0 DMA1 DMA2 DMA3
    # UART instances
    UART0 UART1 UART2
    # I2C instances
    IIC_HOST_SENSOR IIC_HOST IIC_HOST_MIPI
    # I3C instances
    IIIC_SLAVE0 IIIC_SLAVE1
    # SPI instances
    SSPI_HOST QSPI_HOST OSPI_HOST SSPI_SLAVE
    # GPIO instances (critical for platform_driver_init)
    GPIO_G0 GPIO_G1 GPIO_G2 GPIO_G3 SB_GPIO AON_GPIO
    # Audio/misc instances
    I2S_HOST I2S_SLAVE
    # PWM/ADC instances
    PWM0 PWM1 PWM2 ADCC ADCC_HV
)

# Build the definitions list
set(SDK_DRIVERS_DEFINITIONS "")
foreach(IP ${SDK_DRIVERS_IP_LIST})
    list(APPEND SDK_DRIVERS_DEFINITIONS "IP_${IP}")
endforeach()
foreach(INST ${SDK_DRIVERS_IP_INSTANCE})
    list(APPEND SDK_DRIVERS_DEFINITIONS "IP_INST_${INST}")
endforeach()

# Create drivers interface library (only once)
if(NOT TARGET drivers_interface)
    add_library(drivers_interface INTERFACE)

    # Link against cmsis_core
    target_link_libraries(drivers_interface INTERFACE cmsis_core)

    # Drivers include directories
    target_include_directories(drivers_interface INTERFACE
        ${SDK_DRIVERS_INCLUDE_DIRS}
    )

    # IP definitions
    target_compile_definitions(drivers_interface INTERFACE
        ${SDK_DRIVERS_DEFINITIONS}
    )
endif()
