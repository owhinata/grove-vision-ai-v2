# Grove Vision AI V2 SDK CMake Modules

This directory contains CMake modules for building applications with the Grove Vision AI V2 SDK.

## Module Architecture

The modules are organized in a hierarchical dependency structure:

```
                    cmsis_core (INTERFACE)
                         |
              +----------+----------+
              |                     |
       drivers_interface       [direct use]
        (INTERFACE)                 |
              |                     |
              +----------+----------+
                         |
                      device
                         |
         +-------+-------+-------+-------+-------+
         |       |       |       |       |       |
       board  interface common trustzone freertos ...
         |                         _cfg
    [application]
```

## Core Modules

### cmsis_core.cmake

**Type:** INTERFACE library (header-only)

**Purpose:** Provides CMSIS core headers and fundamental ARM compiler definitions.

**PUBLIC Includes:**
- `${SDK_ROOT}/CMSIS`
- `${SDK_ROOT}/CMSIS/Driver/Include`

**PUBLIC Definitions:**
- `__GNU__` - GNU compiler
- `__NEWLIB__` - Newlib C library
- `ARMCM55` - ARM Cortex-M55
- `CM55_BIG` - CM55 big configuration

**Usage:**
```cmake
include(${CMAKE_CURRENT_LIST_DIR}/cmsis_core.cmake)
# cmsis_core target is automatically created
target_link_libraries(my_target PUBLIC cmsis_core)
```

---

### drivers.cmake

**Type:** INTERFACE library (header-only)

**Purpose:** Provides driver include directories and IP peripheral definitions.

**Dependencies:** `cmsis_core`

**PUBLIC Includes:**
- `${SDK_ROOT}/drivers`
- `${SDK_ROOT}/drivers/inc`
- `${SDK_ROOT}/drivers/seconly_inc` (when TrustZone security enabled)

**PUBLIC Definitions:**
- `IP_*` - Driver IP enables (scu, uart, spi, gpio, etc.)
- `IP_INST_*` - Driver IP instances (UART0, GPIO_G0, TIMER0, etc.)

**Usage:**
```cmake
include(${CMAKE_CURRENT_LIST_DIR}/drivers.cmake)
# drivers_interface target is automatically created
target_link_libraries(my_target PUBLIC drivers_interface)
```

---

### device.cmake

**Type:** Static library

**Purpose:** Core device initialization and startup code for WE2 (Himax).

**Dependencies:** `cmsis_core`, `drivers_interface`

**PUBLIC Includes:**
- `${SDK_ROOT}/device`
- `${SDK_ROOT}/device/inc`
- `${SDK_ROOT}/device/clib`

**PUBLIC Definitions:**
- `IC_VERSION=${SDK_IC_VER}` - IC version (default: 30)
- `IC_PACKAGE_${SDK_IC_PACKAGE}` - IC package type (default: WLCSP65)
- `COREV_0P9V` - Core voltage

**Sources:**
- `WE2_core.c` - Core initialization
- `system_WE2_ARMCM55.c` - System initialization
- `startup_WE2_ARMCM55.cc` - Startup code
- C library support files (retarget, console_io)

**Function:**
```cmake
sdk_add_device_library(TARGET_NAME)
```

**Usage:**
```cmake
include(${CMAKE_CURRENT_LIST_DIR}/device.cmake)
sdk_add_device_library(device)
target_link_libraries(my_app PRIVATE device)
```

---

### board.cmake

**Type:** Static library

**Purpose:** Board-specific initialization and pin configuration.

**Dependencies:** `device`

**PUBLIC Includes:**
- `${SDK_ROOT}/board`
- `${SDK_ROOT}/board/${SDK_BOARD}`
- `${SDK_ROOT}/board/${SDK_BOARD}/config`
- `${SDK_ROOT}/customer/sec_inc/seeed`

**PUBLIC Definitions:**
- `seeed` - Seeed board identifier
- `EPII_EVB` - EPII EVB board (when SDK_BOARD=epii_evb)

**Sources:**
- `board.c` - Board initialization
- `pinmux_init.c` - Pin multiplexing configuration
- `platform_driver_init.c` - Platform driver initialization

**Function:**
```cmake
sdk_add_board_library(TARGET_NAME)
```

---

### interface.cmake

**Type:** Static library

**Purpose:** Driver interface abstraction layer.

**Dependencies:** `device`

**PUBLIC Includes:**
- `${SDK_ROOT}/interface`

**Sources:**
- `driver_interface.c`
- `timer_interface.c`

**Function:**
```cmake
sdk_add_interface_library(TARGET_NAME)
```

---

### common.cmake

**Type:** Static library

**Purpose:** Common library containing xprintf and utilities.

**Dependencies:** `device`

**PUBLIC Includes:**
- `${SDK_ROOT}/library/common`

**PRIVATE Definitions:**
- `LIB_COMMON`

**Sources:**
- `xprintf.c` - Printf implementation

**Function:**
```cmake
sdk_add_common_library(TARGET_NAME)
```

---

### trustzone.cmake

**Type:** Static library

**Purpose:** TrustZone SAU/MPC/PPC configuration.

**Dependencies:** `device`

**PUBLIC Includes:**
- `${SDK_ROOT}/trustzone/tz_cfg`
- `${SDK_ROOT}/trustzone`

**PUBLIC Definitions:**
- `TRUSTZONE` - TrustZone enabled
- `TRUSTZONE_CFG` - TrustZone configuration
- `TRUSTZONE_SEC` - Security side (when SDK_TRUSTZONE_TYPE=security)
- `TRUSTZONE_SEC_ONLY` - Security only mode (when SDK_TRUSTZONE_FW_TYPE=1)
- `TRUSTZONE_NS` - Non-security side (when SDK_TRUSTZONE_TYPE=non-security)

**PUBLIC Compile Options:**
- `-mcmse` - Cortex-M Security Extensions (when security side)

**Functions:**
```cmake
sdk_add_trustzone_cfg_library(TARGET_NAME)  # TrustZone configuration
sdk_add_nsc_library(TARGET_NAME)            # Non-Secure Callable veneers (S+NS only)
```

---

### freertos.cmake

**Type:** Static library

**Purpose:** FreeRTOS kernel for real-time operating system support.

**Dependencies:** `device`

**Configuration Variables:**
| Variable | Value | FreeRTOS Variant |
|----------|-------|------------------|
| `SDK_TRUSTZONE_FW_TYPE=1` | Security Only | NTZ with FREERTOS_SECONLY |
| `SDK_TRUSTZONE_TYPE=security` | S+NS Secure | TZ_Sec |
| `SDK_TRUSTZONE_TYPE=non-security` | S+NS Non-Secure | TZ_NonSec |
| (no TrustZone) | Non-TrustZone | NTZ |

**PUBLIC Includes:**
- `${SDK_ROOT}/os/freertos/${variant}/freertos_kernel/include`
- `${SDK_ROOT}/os/freertos/${variant}/freertos_kernel/portable/GCC/${port_dir}`
- `${SDK_ROOT}/os/freertos/${variant}/config`

**PUBLIC Definitions:**
- `FREERTOS` - FreeRTOS enabled
- `ENABLE_OS` - OS enabled (prevents device from defining SysTick_Handler/SVC_Handler)
- `OS_FREERTOS` - OS type identifier
- `configENABLE_MPU=0` - MPU disabled
- `FREERTOS_SECONLY` - Security Only mode (when SDK_TRUSTZONE_FW_TYPE=1)
- `FREERTOS_S` - Secure side (when TZ_Sec)
- `FREERTOS_NS` - Non-Secure side (when TZ_NonSec)

**Sources (NTZ/TZ_NonSec variants):**
- FreeRTOS kernel: tasks.c, queue.c, list.c, timers.c, event_groups.c, stream_buffer.c, croutine.c
- Port: port.c, portasm.c
- Memory management: heap_4.c

**Function:**
```cmake
sdk_add_freertos_library(TARGET_NAME)
```

**Usage:**
```cmake
set(SDK_USE_FREERTOS ON)
include(${CMAKE_CURRENT_LIST_DIR}/freertos.cmake)
sdk_add_freertos_library(freertos)
target_link_libraries(my_app PRIVATE freertos)
```

---

### event_handler.cmake

**Type:** Static library

**Purpose:** Event-driven framework for sensor and peripheral handling.

**Dependencies:** `device`

**Configuration Options:**
| Option | Default | Description |
|--------|---------|-------------|
| `SDK_EVT_DATAPATH` | ON | Datapath event handling |
| `SDK_EVT_I2CCOMM` | OFF | I2C communication events |
| `SDK_EVT_UARTCOMM` | OFF | UART communication events |
| `SDK_EVT_CM55STIMER` | OFF | CM55S timer events |
| `SDK_EVT_CM55MTIMER` | OFF | CM55M timer events |
| `SDK_EVT_CM55MMB` | OFF | CM55M mailbox events |

**PUBLIC Includes:**
- `${SDK_ROOT}/app/scenario_app/event_handler`
- Event-specific subdirectories based on enabled options

**PUBLIC Definitions:**
- `EVT_DATAPATH`, `EVT_I2CS_0_CMD`, etc. (based on enabled options)

**Function:**
```cmake
sdk_add_event_handler_library(TARGET_NAME)
```

---

## Inference Modules

### tflm.cmake

**Type:** Static library (or INTERFACE for prebuilt)

**Purpose:** TensorFlow Lite Micro inference engine.

**Dependencies:** `cmsis_core`

**Configuration Options:**
| Option | Default | Description |
|--------|---------|-------------|
| `SDK_TFLM_FORCE_PREBUILT` | OFF | Use prebuilt library |
| `SDK_TFLM_USE_CMSIS_NN` | OFF | Use CMSIS-NN optimized kernels |
| `SDK_TFLM_VERSION` | tflmtag2209_u55tag2205 | TFLM version |

**PUBLIC Includes:**
- TensorFlow Lite headers
- Flatbuffers headers
- Ethos-U driver headers
- CMSIS-NN headers (when enabled)

**PUBLIC Definitions:**
- `TFLM2209_U55TAG2205`
- `TF_LITE_STATIC_MEMORY`
- `TF_LITE_MCU_DEBUG_LOG`
- `ETHOSU_ARCH=u55`, `ETHOSU55`, `ETHOS_U`
- `CMSIS_NN` (when SDK_TFLM_USE_CMSIS_NN=ON)

**Function:**
```cmake
sdk_add_tflm_library(TARGET_NAME)
```

**Usage:**
```cmake
set(SDK_TFLM_USE_CMSIS_NN ON)
include(${CMAKE_CURRENT_LIST_DIR}/tflm.cmake)
sdk_add_tflm_library(tflm_lib)
```

---

### cmsis_nn.cmake

**Type:** Static library (or INTERFACE for prebuilt)

**Purpose:** CMSIS-NN neural network library with MVE optimization.

**Dependencies:** `cmsis_core`

**Configuration Options:**
| Option | Default | Description |
|--------|---------|-------------|
| `SDK_CMSIS_NN_FORCE_PREBUILT` | OFF | Use prebuilt library |
| `SDK_CMSIS_NN_VERSION` | 7_0_0 | CMSIS-NN version |

**PUBLIC Includes:**
- `${SDK_ROOT}/library/cmsis_nn/cmsis_nn_${version}`
- `${SDK_ROOT}/library/cmsis_nn/cmsis_nn_${version}/Include`
- `${SDK_ROOT}/library/cmsis_nn/cmsis_nn_${version}/Include/Internal`

**PUBLIC Definitions:**
- `LIB_CMSIS_NN`
- `ARM_MATH_MVEI` - MVE intrinsics
- `ARM_MATH_DSP` - DSP extensions
- `ARM_MATH_LOOPUNROLL` - Loop unrolling optimization

**Function:**
```cmake
sdk_add_cmsis_nn_library(TARGET_NAME)
```

---

## Support Modules

### sdk_base.cmake

**Purpose:** SDK configuration options and common settings.

**Configuration Variables:**
| Variable | Default | Description |
|----------|---------|-------------|
| `SDK_BOARD` | epii_evb | Board type |
| `SDK_IC_VER` | 30 | IC version |
| `SDK_BD_VER` | 10 | Board version |
| `SDK_CORTEX_M` | 55 | Cortex-M version |
| `SDK_IC_PACKAGE` | WLCSP65 | IC package type |
| `SDK_TRUSTZONE` | ON | Enable TrustZone |
| `SDK_TRUSTZONE_TYPE` | security | TrustZone type |
| `SDK_TRUSTZONE_FW_TYPE` | 1 | Firmware type (0=S+NS, 1=S only) |
| `SDK_USE_FREERTOS` | OFF | Use FreeRTOS |
| `SDK_USE_RTX` | OFF | Use RTX |
| `SDK_SEMIHOST` | OFF | Use semihosting |
| `SDK_DEBUG` | ON | Debug build |

**Function:**
```cmake
sdk_apply_common_settings(TARGET_NAME)
```

This function applies:
- DEBUG/NDEBUG and SEMIHOST definitions
- Cross-module include directories (for SDK's tightly-coupled code)
- TrustZone compile options (-mcmse)

---

### linker.cmake

**Purpose:** Linker script configuration and preprocessing.

**Functions:**
```cmake
sdk_setup_linker_script(TARGET_NAME LD_SCRIPT)  # Configure linker script
```

---

### prebuilt_libs.cmake

**Purpose:** Prebuilt SDK library management.

**Functions:**
```cmake
sdk_add_pwrmgmt_library(TARGET_NAME)    # Power management
sdk_add_spi_eeprom_library(TARGET_NAME) # SPI EEPROM
sdk_add_audio_library(TARGET_NAME)      # Audio processing
sdk_add_img_proc_library(TARGET_NAME)   # Image processing
```

---

### image_gen.cmake

**Purpose:** Firmware image generation for flashing.

**Functions:**
```cmake
sdk_setup_image_gen(TARGET_NAME)  # Setup image generation
sdk_add_flash_target(TARGET_NAME) # Add flash target
```

---

## Example Application CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.20)

# Setup toolchain
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/arm-none-eabi-gcc.cmake)

project(my_app C CXX ASM)

# Set SDK root
set(SDK_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../external/sdk/EPII_CM55M_APP_S)

# Include SDK modules
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/sdk_base.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/board.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/interface.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/common.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/trustzone.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/event_handler.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/prebuilt_libs.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/linker.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/image_gen.cmake)

# Enable CMSIS-NN for TFLM
set(SDK_TFLM_USE_CMSIS_NN ON)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/tflm.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/../../cmake/sdk/cmsis_nn.cmake)

# Create SDK library targets
sdk_add_device_library(device)
sdk_add_board_library(board)
sdk_add_interface_library(interface)
sdk_add_common_library(common)
sdk_add_trustzone_cfg_library(trustzone_cfg)
sdk_add_event_handler_library(event_handler)
sdk_add_pwrmgmt_library(pwrmgmt)
sdk_add_tflm_library(tflm_lib)
sdk_add_cmsis_nn_library(cmsis_nn)

# Application sources
set(APP_SOURCES
    src/main.c
    src/app.c
)

# Create application executable
add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Apply SDK settings
sdk_apply_common_settings(${PROJECT_NAME})

# Link libraries
target_link_libraries(${PROJECT_NAME} PRIVATE
    board
    interface
    common
    trustzone_cfg
    event_handler
    pwrmgmt
    tflm_lib
    cmsis_nn
)

# Setup linker and image generation
sdk_setup_linker_script(${PROJECT_NAME} ${CMAKE_CURRENT_LIST_DIR}/linker.ld)
sdk_setup_image_gen(${PROJECT_NAME})
sdk_add_flash_target(${PROJECT_NAME})
```

---

## Module Dependency Graph

```
Application
    |
    +-- board ----+
    |             |
    +-- interface-+-- device --+-- cmsis_core
    |             |            |
    +-- common ---+            +-- drivers_interface --+-- cmsis_core
    |             |
    +-- trustzone_cfg
    |
    +-- freertos ----+-- device
    |
    +-- event_handler
    |
    +-- tflm_lib --------+-- cmsis_core
    |                    |
    +-- cmsis_nn --------+
    |
    +-- pwrmgmt (prebuilt)
```

---

## Notes

### Tight Coupling in SDK Code

The SDK code has tight coupling between modules (e.g., device sources include board.h, ethosu_driver.c includes WE2_core.h). The `sdk_apply_common_settings()` function provides cross-module includes to handle this. Individual modules still define their PUBLIC includes/defines for proper propagation to dependent targets.

### Building from Source vs Prebuilt

TFLM and CMSIS-NN can be built from source (default) or use prebuilt libraries:

```cmake
# Build from source (default)
set(SDK_TFLM_FORCE_PREBUILT OFF)
set(SDK_CMSIS_NN_FORCE_PREBUILT OFF)

# Use prebuilt
set(SDK_TFLM_FORCE_PREBUILT ON)
set(SDK_CMSIS_NN_FORCE_PREBUILT ON)
```

### TrustZone Configurations

| SDK_TRUSTZONE_FW_TYPE | Configuration | Libraries Needed |
|-----------------------|---------------|------------------|
| 1 | Security Only (S) | trustzone_cfg |
| 0 | Secure + Non-Secure (S+NS) | trustzone_cfg, nsc |

### FreeRTOS Configurations

| TrustZone Setting | FreeRTOS Variant | Kernel Type |
|-------------------|------------------|-------------|
| `SDK_TRUSTZONE_FW_TYPE=1` | NTZ | Full kernel with FREERTOS_SECONLY |
| `SDK_TRUSTZONE_TYPE=security` (S+NS) | TZ_Sec | Secure port only |
| `SDK_TRUSTZONE_TYPE=non-security` (S+NS) | TZ_NonSec | Full kernel |
| No TrustZone | NTZ | Full kernel |

**Example FreeRTOS Application:**
```cmake
# SDK configuration
set(SDK_USE_FREERTOS ON)
set(SDK_TRUSTZONE ON)
set(SDK_TRUSTZONE_TYPE "security")
set(SDK_TRUSTZONE_FW_TYPE 1)  # Security Only

# Include modules
include(${CMAKE_CURRENT_LIST_DIR}/freertos.cmake)

# Create libraries
sdk_add_freertos_library(freertos)

# Link to application
target_link_libraries(${PROJECT_NAME} PRIVATE
    freertos
    board
    device
    interface
    common
    trustzone_cfg
)
```
