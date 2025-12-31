# sensordplib API Reference

API documentation for Himax WE2 Sensor Datapath Library

**File:** `EPII_CM55M_APP_S/library/sensordp/inc/sensor_dp_lib.h`

---

## Table of Contents

1. [Overview](#1-overview)
2. [Enumerations](#2-enumerations)
3. [Structures](#3-structures)
4. [Callbacks](#4-callbacks)
5. [Initialization & Control API](#5-initialization--control-api)
6. [Datapath Configuration API](#6-datapath-configuration-api)
7. [xDMA Management API](#7-xdma-management-api)
8. [MIPI CSI-RX API](#8-mipi-csi-rx-api)
9. [MIPI CSI-TX API](#9-mipi-csi-tx-api)
10. [AUTO I2C API](#10-auto-i2c-api)
11. [Utility API](#11-utility-api)
12. [Usage Examples](#12-usage-examples)

---

## 1. Overview

`sensordplib` is a library for controlling the sensor datapath (ISP pipeline) on the Himax WE2 platform. It processes image data from camera sensors through hardware accelerators (HW2x2, HW5x5, CDM, JPEG) and outputs to memory.

### Key Features

- Sensor input control (INP)
- Hardware accelerator configuration (HW2x2, HW5x5, CDM, JPEG)
- DMA transfer management (WDMA1/2/3, RDMA)
- MIPI CSI-RX/TX control
- Auto I2C control (for PMU mode)
- Periodic capture via RTC timer

### Architecture Diagram

```
+---------------------------------------------------------------------+
|                    sensordplib Datapath Configuration               |
+---------------------------------------------------------------------+
|                                                                     |
|  [Sensor] -> [INP] -> [HW2x2] -> [CDM] -> [WDMA1]                   |
|                 |                                                   |
|                 +---> [HW5x5] -> [JPEG] -> [WDMA2]                  |
|                          |                                          |
|                          +---> [WDMA3] (YUV/RGB Raw)                |
|                                                                     |
|  [RDMA] -> [TPG] -> [JPEG Dec] -> [WDMA3]                          |
|                                                                     |
+---------------------------------------------------------------------+
```

---

## 2. Enumerations

### SENSORDPLIB_PATH_E

Selects the datapath configuration.

| Value | Description | Data Flow |
|-------|-------------|-----------|
| `SENSORDPLIB_PATH_INP_WDMA2` | RAW output | Sensor -> INP -> WDMA2 |
| `SENSORDPLIB_PATH_INP_HW2x2_CDM` | Motion detection | Sensor -> INP -> 2x2 -> CDM -> WDMA1 |
| `SENSORDPLIB_PATH_INP_HW5x5` | Demosaic | Sensor -> INP -> 5x5 -> WDMA3 |
| `SENSORDPLIB_PATH_INP_HW5x5_JPEG` | JPEG output | Sensor -> INP -> 5x5 -> JPEG -> WDMA2 |
| `SENSORDPLIB_PATH_JPEGDEC` | JPEG decode | RDMA -> JPEG Dec -> WDMA3 |
| `SENSORDPLIB_PATH_INP_HW2x2` | 2x2 filter | Sensor -> INP -> 2x2 -> WDMA1 |
| `SENSORDPLIB_PATH_INP_CDM` | CDM only | Sensor -> INP -> CDM -> WDMA1 |
| `SENSORDPLIB_PATH_INT1` | **Full integration** | CDM+YUV+JPEG simultaneous output |
| `SENSORDPLIB_PATH_INTNOJPEG` | Integration (no JPEG) | CDM+YUV output |
| `SENSORDPLIB_PATH_INT3` | RAW+YUV integration | RAW(WDMA2)+YUV(WDMA3) |
| `SENSORDPLIB_PATH_INT_INP_HW5X5_JPEG` | **Recommended** | YUV(WDMA3)+JPEG(WDMA2) |
| `SENSORDPLIB_PATH_TPG_JPEGENC` | TPG->JPEG | RDMA -> TPG -> JPEG -> WDMA2 |

### SENSORDPLIB_SENSOR_E

Supported sensor types.

| Value | Description |
|-------|-------------|
| `SENSORDPLIB_SENSOR_HM0360_MODE1` | HM0360 Mode1 (8bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE2` | HM0360 Mode2 (8bit IO, 4bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE3` | HM0360 Mode3 (4bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE5` | HM0360 Mode5 (1bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM01B0_8BITIO` | HM01B0 8bit IO |
| `SENSORDPLIB_SENSOR_HM11B1_LSB` | HM11B1 LSB |
| `SENSORDPLIB_SENSOR_HM2170_MIPI` | HM2170 MIPI |
| `SENSORDPLIB_SENSOR_HM2130` | HM2130 (used for OV5647, etc.) |

### SENSORDPLIB_STREAM_E

Sensor streaming modes.

| Value | Description |
|-------|-------------|
| `SENSORDPLIB_STREAM_NONEAOS` | **Standard** - Streaming via I2C master |
| `SENSORDPLIB_STREAM_HM01B0_CONT` | HM01B0 continuous mode (HW trigger) |
| `SENSORDPLIB_STREAM_HM0360_CONT` | HM0360 continuous mode (no MCLK) |
| `SENSORDPLIB_STREAM_HM0360_BURST` | HM0360 burst mode |
| `SENSORDPLIB_STREAM_HM0360_SENSOR_ACT` | HM0360 sensor active mode |
| `SENSORDPLIB_STREAM_HM11B1_LOWPOWER` | HM11B1 low power mode |
| `SENSORDPLIB_STREAM_NONEAOS_AUTOI2C` | AUTO I2C control mode |

### SENSORDPLIB_STATUS_E

Callback event status.

**Normal Events:**

| Value | Description |
|-------|-------------|
| `SENSORDPLIB_STATUS_XDMA_FRAME_READY` | **Frame ready** (most important) |
| `SENSORDPLIB_STATUS_CDM_MOTION_DETECT` | Motion detected |
| `SENSORDPLIB_STATUS_XDMA_WDMA1_FINISH` | WDMA1 complete |
| `SENSORDPLIB_STATUS_XDMA_WDMA2_FINISH` | WDMA2 complete |
| `SENSORDPLIB_STATUS_XDMA_WDMA3_FINISH` | WDMA3 complete |
| `SENSORDPLIB_STATUS_TIMER_FIRE_APP_READY` | Timer fired (ready) |

**Error Events (negative values):**

| Value | Description |
|-------|-------------|
| `SENSORDPLIB_STATUS_ERR_FS_ERR` (-100) | Frame start error |
| `SENSORDPLIB_STATUS_EDM_WDT1_TIMEOUT` (-75) | WDMA1 watchdog timeout |
| `SENSORDPLIB_STATUS_CDM_FIFO_OVERFLOW` (-60) | CDM FIFO overflow |
| `SENSORDPLIB_STATUS_XDMA_WDMA1_ABNORMALx` (-50~) | WDMA1 abnormal |
| `SENSORDPLIB_STATUS_XDMA_WDMA2_ABNORMALx` (-40~) | WDMA2 abnormal |
| `SENSORDPLIB_STATUS_XDMA_WDMA3_ABNORMALx` (-30~) | WDMA3 abnormal |

---

## 3. Structures

### SENSORDPLIB_HOGDMA_CFG_T

HOG DMA configuration.

```c
typedef struct {
    uint32_t wdma_startaddr;        // HOG WDMA output address
    uint32_t rdma_ch1_startaddr;    // HOG RDMA Y channel address
    uint32_t rdma_ch2_startaddr;    // HOG RDMA U channel address
    uint32_t rdma_ch3_startaddr;    // HOG RDMA V channel address
} SENSORDPLIB_HOGDMA_CFG_T;
```

### SENSORDPLIB_RDMA_CFG_T

RDMA configuration for TPG path.

```c
typedef struct {
    uint32_t rdma_ch1_startaddr;    // TPG RDMA channel 1 address
    uint32_t rdma_ch2_startaddr;    // TPG RDMA channel 2 address
    uint32_t rdma_ch3_startaddr;    // TPG RDMA channel 3 address
} SENSORDPLIB_RDMA_CFG_T;
```

### SENSORDPLIB_HM11B1_HEADER_T

HM11B1 sensor header information.

```c
typedef struct {
    INP_1BITPARSER_FSM_E fsm;       // 1bit INP parser FSM state
    uint16_t hw_hsize;              // HW calculated HSIZE
    uint16_t hw_vsize;              // HW calculated VSIZE
    uint16_t sensor_hsize;          // Sensor header HSIZE
    uint16_t sensor_vsize;          // Sensor header VSIZE
    uint16_t frame_len;             // Frame length
    uint16_t line_len;              // Line length
    uint8_t again;                  // Analog gain
    uint16_t dgain;                 // Digital gain
    uint16_t intg;                  // Integration time
    uint16_t sensor_crc;            // Sensor CRC
    uint16_t hw_crc;                // HW calculated CRC
    uint16_t err_status;            // Error status
} SENSORDPLIB_HM11B1_HEADER_T;
```

---

## 4. Callbacks

### sensordplib_CBEvent_t

Datapath event callback function type.

```c
typedef void (*sensordplib_CBEvent_t)(SENSORDPLIB_STATUS_E event);
```

**Usage Example:**

```c
void my_dp_callback(SENSORDPLIB_STATUS_E event) {
    switch(event) {
        case SENSORDPLIB_STATUS_XDMA_FRAME_READY:
            // Frame ready - run inference
            process_frame();
            sensordplib_retrigger_capture();  // Request next frame
            break;
        case SENSORDPLIB_STATUS_CDM_MOTION_DETECT:
            // Motion detected
            handle_motion();
            break;
        default:
            if(event < 0) {
                // Error handling
                handle_error(event);
            }
            break;
    }
}
```

---

## 5. Initialization & Control API

### sensordplib_init

Initializes the library.

```c
void sensordplib_init();
```

### sensordplib_set_sensorctrl_inp

Configures sensor control and INP (Input Processor).

```c
int sensordplib_set_sensorctrl_inp(
    SENSORDPLIB_SENSOR_E sensor_type,   // Sensor type
    SENSORDPLIB_STREAM_E type,          // Streaming mode
    uint16_t hsize,                     // Horizontal size
    uint16_t frame_len,                 // Frame length
    INP_SUBSAMPLE_E subsample           // Subsampling setting
);
```

**Return:** 0=success, -1=failure

### sensordplib_set_sensorctrl_inp_wi_crop

Configures sensor control and INP with cropping.

```c
int sensordplib_set_sensorctrl_inp_wi_crop(
    SENSORDPLIB_SENSOR_E sensor_type,
    SENSORDPLIB_STREAM_E type,
    uint16_t hsize,
    uint16_t frame_len,
    INP_SUBSAMPLE_E subsample,
    INP_CROP_T crop                     // Crop settings
);
```

### sensordplib_set_sensorctrl_inp_wi_crop_bin

Configures sensor control and INP with cropping and binning (IC_VERSION >= 30).

```c
int sensordplib_set_sensorctrl_inp_wi_crop_bin(
    SENSORDPLIB_SENSOR_E sensor_type,
    SENSORDPLIB_STREAM_E type,
    uint16_t hsize,
    uint16_t frame_len,
    INP_SUBSAMPLE_E subsample,
    INP_CROP_T crop,
    INP_BINNING_E binmode               // Binning mode
);
```

### sensordplib_set_sensorctrl_start

Starts capture.

```c
int sensordplib_set_sensorctrl_start();
```

**Return:** 0=success, -1=failure

### sensordplib_set_rtc_start

Starts periodic capture via RTC timer.

```c
int sensordplib_set_rtc_start(uint32_t time_interval);  // Interval (ms)
```

### sensordplib_stop_capture

Stops capture.

```c
void sensordplib_stop_capture();
```

**Operations performed:**
1. Disable xDMA
2. Disable DP multiplexer
3. Disable CDM
4. Disable periodic timer
5. SWRESET sensor control
6. Stop EDM WDT

### sensordplib_retrigger_capture

Triggers the next frame capture.

```c
void sensordplib_retrigger_capture();
```

**Note:** When not using RTC timer, call this function after frame ready to request the next frame.

### sensordplib_start_swreset

Performs software reset of the datapath.

```c
void sensordplib_start_swreset();
```

**Reset targets:**
- INP (Bit 0)
- Sensor Control (Bit 1)
- HW2x2 (Bit 2)
- HW5x5 (Bit 3)
- CDM (Bit 4)
- JPEG (Bit 5)
- TPG (Bit 6)
- EDM (Bit 7)
- Datapath (Bit 8)
- WDMA1/2/3 (Bit 9-11)
- RDMA (Bit 12)

### sensordplib_stop_swreset_WoSensorCtrl

Returns to normal mode except sensor control.

```c
void sensordplib_stop_swreset_WoSensorCtrl();
```

### sensordplib_set_mclkctrl_xsleepctrl_bySCMode

Configures MCLK and xSleep control based on streaming mode.

```c
void sensordplib_set_mclkctrl_xsleepctrl_bySCMode();
```

---

## 6. Datapath Configuration API

### Single Path Configuration

#### sensordplib_set_raw_wdma2

Configures RAW output path.

```c
void sensordplib_set_raw_wdma2(
    uint16_t width,                     // Input width
    uint16_t height,                    // Input height
    sensordplib_CBEvent_t dplib_cb      // Callback
);
```

**Data Flow:** Sensor -> INP -> WDMA2

#### sensordplib_set_hw5x5_wdma3

Configures HW5x5 demosaic path.

```c
void sensordplib_set_hw5x5_wdma3(
    HW5x5_CFG_T hw5x5_cfg,              // HW5x5 configuration
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** Sensor -> INP -> HW5x5 -> WDMA3

#### sensordplib_set_HW2x2_wdma1

Configures HW2x2 filter path.

```c
void sensordplib_set_HW2x2_wdma1(
    HW2x2_CFG_T hw2x2_cfg,              // HW2x2 configuration
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** Sensor -> INP -> HW2x2 -> WDMA1

#### sensordplib_set_CDM

Configures CDM (motion detection) path.

```c
void sensordplib_set_CDM(
    CDM_CFG_T cdm_cfg,                  // CDM configuration
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** Sensor -> INP -> CDM -> WDMA1

#### sensordplib_set_HW2x2_CDM

Configures HW2x2 + CDM path.

```c
void sensordplib_set_HW2x2_CDM(
    HW2x2_CFG_T hw2x2_cfg,
    CDM_CFG_T cdm_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** Sensor -> INP -> HW2x2 -> CDM -> WDMA1

#### sensordplib_set_hw5x5_jpeg_wdma2

Configures HW5x5 + JPEG output path.

```c
void sensordplib_set_hw5x5_jpeg_wdma2(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,          // Cyclic buffer count
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** Sensor -> INP -> HW5x5 -> JPEG -> WDMA2

### Integrated Path Configuration

#### sensordplib_set_INT1_HWACC

**Full integration path** - CDM + YUV + JPEG simultaneous output.

```c
void sensordplib_set_INT1_HWACC(
    HW2x2_CFG_T hw2x2_cfg,              // HW2x2 configuration
    CDM_CFG_T cdm_cfg,                  // CDM configuration
    HW5x5_CFG_T hw5x5_cfg,              // HW5x5 configuration
    JPEG_CFG_T jpeg_cfg,                // JPEG configuration
    uint8_t cyclic_buffer_cnt,          // JPEG cyclic buffer count
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:**
- Sensor -> INP -> HW2x2 -> CDM -> WDMA1
- Sensor -> INP -> HW5x5(YUV) -> JPEG -> WDMA2
- Sensor -> INP -> HW5x5(YUV) -> WDMA3

#### sensordplib_set_INTNoJPEG_HWACC

Integration path without JPEG.

```c
void sensordplib_set_INTNoJPEG_HWACC(
    HW2x2_CFG_T hw2x2_cfg,
    CDM_CFG_T cdm_cfg,
    HW5x5_CFG_T hw5x5_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:**
- Sensor -> INP -> HW2x2 -> CDM -> WDMA1
- Sensor -> INP -> HW5x5 -> WDMA3

#### sensordplib_set_int_hw5x5_jpeg_wdma23

**Recommended path** - YUV + JPEG simultaneous output (for TFLite inference).

```c
void sensordplib_set_int_hw5x5_jpeg_wdma23(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:**
- Sensor -> INP -> HW5x5(YUV) -> JPEG -> WDMA2
- Sensor -> INP -> HW5x5(YUV) -> WDMA3

#### sensordplib_set_int_hw5x5rgb_jpeg_wdma23

RGB output + JPEG simultaneous output.

```c
void sensordplib_set_int_hw5x5rgb_jpeg_wdma23(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:**
- Sensor -> INP -> HW5x5(RGB) -> RGB2YUV -> JPEG -> WDMA2
- Sensor -> INP -> HW5x5(RGB) -> WDMA3

#### sensordplib_set_int_raw_hw5x5_wdma23

RAW + YUV simultaneous output.

```c
void sensordplib_set_int_raw_hw5x5_wdma23(
    uint16_t width,
    uint16_t height,
    HW5x5_CFG_T hw5x5_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:**
- Sensor -> INP -> WDMA2 (RAW)
- Sensor -> INP -> HW5x5 -> WDMA3 (YUV)

### JPEG Decoder Path

#### sensordplib_set_jpegdec

Configures JPEG decode path.

```c
void sensordplib_set_jpegdec(
    JPEG_CFG_T jpegdec_cfg,
    uint16_t in_width,                  // Input width
    uint16_t in_height,                 // Input height
    uint32_t frame_no,                  // Frame number
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** RDMA -> JPEG Dec -> WDMA3

### TPG Path

#### sensordplib_tpg_jpegenc_wdma2

Configures TPG to JPEG encode path.

```c
void sensordplib_tpg_jpegenc_wdma2(
    JPEG_CFG_T jpeg_cfg,
    uint32_t wdma2_startaddr,           // WDMA2 output address
    uint8_t jpegfilesize_fillen,        // Enable file size storage
    uint32_t jpegfilesize_filladdr,     // File size storage address
    SENSORDPLIB_RDMA_CFG_T dplib_rdma_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**Data Flow:** RDMA -> TPG -> JPEG -> WDMA2

---

## 7. xDMA Management API

### sensordplib_set_xDMA_baseaddrbyapp

Sets xDMA base addresses.

```c
void sensordplib_set_xDMA_baseaddrbyapp(
    uint32_t wdma1_addr,                // WDMA1 base address
    uint32_t wdma2_addr,                // WDMA2 base address
    uint32_t wdma3_addr                 // WDMA3 base address
);
```

**Default values:**
- WDMA1: 0x20050000 (for HW2x2/CDM)
- WDMA2: 0x2009B000 (for JPEG)
- WDMA3: 0x200E6000 (for HW5x5)

### sensordplib_get_xDMA_baseaddr

Gets current xDMA base addresses.

```c
void sensordplib_get_xDMA_baseaddr(
    uint32_t *wdma1_addr,
    uint32_t *wdma2_addr,
    uint32_t *wdma3_addr
);
```

### sensordplib_set_jpegfilesize_addrbyapp

Sets JPEG auto file size storage address.

```c
void sensordplib_set_jpegfilesize_addrbyapp(uint32_t jpegfilesize_autoaddr);
```

**Default:** 0x2015FE70

### sensordplib_get_jpegfilesize_addrbyapp

Gets JPEG auto file size storage address.

```c
void sensordplib_get_jpegfilesize_addrbyapp(uint32_t *jpegfilesize_autoaddr);
```

### sensordplib_get_xdma_fin

Gets xDMA completion flags (for debugging).

```c
void sensordplib_get_xdma_fin(
    uint8_t *wdma1_fin,                 // WDMA1 completion flag
    uint8_t *wdma2_fin,                 // WDMA2 completion flag
    uint8_t *wdma3_fin,                 // WDMA3 completion flag
    uint8_t *rdma_fin                   // RDMA completion flag
);
```

### sensordplib_get_xdma_sc_finflag

Gets xDMA and sensor control completion flags.

```c
void sensordplib_get_xdma_sc_finflag(
    uint8_t *xdma_fin_flag,             // xDMA completion flag
    uint8_t *sc_fin_flag                // Sensor control completion flag
);
```

---

## 8. MIPI CSI-RX API

### sensordplib_csirx_enable

Enables MIPI CSI-RX.

```c
void sensordplib_csirx_enable(uint8_t lane_nb);  // Number of lanes
```

### sensordplib_csirx_disable

Disables MIPI CSI-RX.

```c
void sensordplib_csirx_disable(void);
```

### sensordplib_csirx_set_vcnum

Sets virtual channel number.

```c
void sensordplib_csirx_set_vcnum(uint8_t vc_num);
```

### sensordplib_csirx_set_hscnt

Configures HS-Count settings.

```c
void sensordplib_csirx_set_hscnt(MIPIRX_DPHYHSCNT_CFG_T hs_cnt);
```

### sensordplib_csirx_set_deskew

Configures DESKEW feature.

```c
void sensordplib_csirx_set_deskew(uint8_t enable);
```

### sensordplib_csirx_set_pixel_depth

Sets pixel depth.

```c
void sensordplib_csirx_set_pixel_depth(uint8_t depth);  // 8 or 10
```

### sensordplib_csirx_set_fifo_fill

Sets FIFO FILL.

```c
void sensordplib_csirx_set_fifo_fill(uint16_t fifo_fill);
```

### sensordplib_csirx_set_lnswap_enable

Enables lane swap.

```c
void sensordplib_csirx_set_lnswap_enable(uint8_t enable);
```

---

## 9. MIPI CSI-TX API

### sensordplib_csitx_enable

Enables MIPI CSI-TX.

```c
void sensordplib_csitx_enable(
    uint8_t lane_nb,                    // Number of lanes
    uint16_t bit_rate,                  // Bit rate
    uint16_t line_len,                  // Line length
    uint16_t frame_len                  // Frame length
);
```

### sensordplib_csitx_disable

Disables MIPI CSI-TX.

```c
void sensordplib_csitx_disable(void);
```

### sensordplib_csitx_set_dphy_clkmode

Sets clock mode.

```c
void sensordplib_csitx_set_dphy_clkmode(CSITX_DPHYCLKMODE_E clkmode);
```

### sensordplib_csitx_set_fifo_fill

Sets TX FIFO FILL.

```c
void sensordplib_csitx_set_fifo_fill(uint16_t fifo_fill);
```

### sensordplib_csitx_set_pixel_depth

Sets TX pixel depth.

```c
void sensordplib_csitx_set_pixel_depth(uint8_t depth);
```

---

## 10. AUTO I2C API

For automatic sensor control in PMU mode.

### sensordplib_autoi2c_cfg

Configures AUTO I2C.

```c
void sensordplib_autoi2c_cfg(
    HXAUTOI2CHC_STATIC_CFG_T scfg,      // Static configuration
    HXAUTOI2CHC_INT_CFG_T icfg,         // Interrupt configuration
    HXAUTOI2CHC_CMD_CFG_T trig_cfg,     // Trigger command configuration
    HXAUTOI2CHC_CMD_CFG_T stop_cfg      // Stop command configuration
);
```

### sensordplib_autoi2c_trigcmd

Sets trigger commands.

```c
void sensordplib_autoi2c_trigcmd(
    HXAUTOI2CHC_CMD_T cmd1,
    HXAUTOI2CHC_CMD_T cmd2,
    HXAUTOI2CHC_CMD_T cmd3,
    HXAUTOI2CHC_CMD_T cmd4
);
```

### sensordplib_autoi2c_stopcmd

Sets stop commands.

```c
void sensordplib_autoi2c_stopcmd(
    HXAUTOI2CHC_CMD_T cmd1,
    HXAUTOI2CHC_CMD_T cmd2,
    HXAUTOI2CHC_CMD_T cmd3,
    HXAUTOI2CHC_CMD_T cmd4
);
```

### sensordplib_autoi2c_enable / disable

Enables/disables AUTO I2C.

```c
void sensordplib_autoi2c_enable(void);
void sensordplib_autoi2c_disable(void);
```

---

## 11. Utility API

### sensordplib_get_version

Gets library version.

```c
void sensordplib_get_version(uint32_t *version);
```

### sensordplib_get_cur_dp_path

Gets current datapath.

```c
void sensordplib_get_cur_dp_path(SENSORDPLIB_PATH_E *dplib_case);
```

### sensorlib_get_cur_sensortype

Gets current sensor type.

```c
void sensorlib_get_cur_sensortype(SENSORDPLIB_SENSOR_E *cursensorId);
```

### sensordplib_set_readyflag

Sets ready flag (when using RTC timer).

```c
void sensordplib_set_readyflag(uint8_t ready_flag);
// ready_flag = 1: Execute capture on timer fire
// ready_flag = 0: Pause capture on timer fire
```

### sensordplib_get_readyflag

Gets ready flag.

```c
void sensordplib_get_readyflag(uint8_t *ready_flag);
```

### sensordplib_get_status

Gets library status (for debugging).

```c
void sensordplib_get_status(
    uint8_t *ready_flag,                // Ready flag
    uint8_t *nframe_end,                // NFrame End status
    uint8_t *xdmadone                   // xDMA completion flag
);
```

### sensordplib_edm_wdt_config

Configures EDM watchdog.

```c
void sensordplib_edm_wdt_config(
    uint8_t wdt1_en,                    // Enable WDMA1 WDT
    uint8_t wdt2_en,                    // Enable WDMA2 WDT
    uint8_t wdt3_en                     // Enable WDMA3 WDT
);
```

### sensordplib_inp_set_crop_area

Sets INP crop area.

```c
void sensordplib_inp_set_crop_area(INP_CROP_T crop);
```

### hx_dplib_register_cb

Registers callback function.

```c
void hx_dplib_register_cb(
    sensordplib_CBEvent_t cb_event,
    SENSORDPLIB_CB_FUNTYPE_E type       // DP, RS, HOG, JPEG_DEC
);
```

### sensordplib_gated_dp_clk_bycase / ungated

Gates/ungates datapath clock.

```c
void sensordplib_gated_dp_clk_bycase(SENSORDPLIB_PATH_E dplib_case);
void sensordplib_ungated_dp_clk_bycase(SENSORDPLIB_PATH_E dplib_case);
```

---

## 12. Usage Examples

### Basic Capture Flow

```c
#include "sensor_dp_lib.h"
#include "hx_drv_hw5x5.h"
#include "hx_drv_jpeg.h"

// Global variables
static volatile uint8_t g_frame_ready = 0;

// Callback function
void dp_callback(SENSORDPLIB_STATUS_E event) {
    if(event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
        g_frame_ready = 1;
    }
}

int main(void) {
    // 1. Initialize library
    sensordplib_init();

    // 2. Set xDMA addresses
    sensordplib_set_xDMA_baseaddrbyapp(
        0x20050000,  // WDMA1
        0x2009B000,  // WDMA2 (JPEG)
        0x200E6000   // WDMA3 (YUV)
    );
    sensordplib_set_jpegfilesize_addrbyapp(0x2015FE70);

    // 3. Configure sensor
    sensordplib_set_sensorctrl_inp(
        SENSORDPLIB_SENSOR_HM2130,       // OV5647, etc.
        SENSORDPLIB_STREAM_NONEAOS,
        640, 480,
        INP_SUBSAMPLE_DISABLE
    );

    // 4. Configure HW5x5
    HW5x5_CFG_T hw5x5_cfg = {
        .hw5x5_path = HW5x5_PATH_THROUGH_DEMOSAIC,
        .demos_color_mode = DEMOS_COLORMODE_YUV420,
        .demos_pattern_mode = DEMOS_PATTENMODE_BGGR,
        .demos_bndmode = DEMOS_BNDODE_REFLECT,
        .demoslpf_roundmode = DEMOSLPF_ROUNDMODE_FLOOR,
        .hw55_crop_stx = 0,
        .hw55_crop_sty = 0,
        .hw55_in_width = 640,
        .hw55_in_height = 480
    };

    // 5. Configure JPEG
    JPEG_CFG_T jpeg_cfg = {
        .jpeg_path = JPEG_PATH_ENCODER_EN,
        .enc_width = 640,
        .enc_height = 480,
        .jpeg_enctype = JPEG_ENC_TYPE_YUV420,
        .jpeg_encqtable = JPEG_ENC_QTABLE_10X
    };

    // 6. Configure datapath (YUV + JPEG simultaneous output)
    sensordplib_set_int_hw5x5_jpeg_wdma23(
        hw5x5_cfg,
        jpeg_cfg,
        1,           // Cyclic buffer count
        dp_callback
    );

    // 7. Configure MCLK and xSleep control
    sensordplib_set_mclkctrl_xsleepctrl_bySCMode();

    // 8. Start capture
    sensordplib_set_sensorctrl_start();

    // 9. Main loop
    while(1) {
        if(g_frame_ready) {
            g_frame_ready = 0;

            // Process frame
            process_yuv_frame();

            // Request next frame
            sensordplib_retrigger_capture();
        }
    }

    return 0;
}
```

### Periodic Capture with RTC Timer

```c
// Start periodic capture (500ms interval)
sensordplib_set_sensorctrl_start();
sensordplib_set_rtc_start(500);

// Pause
sensordplib_set_readyflag(0);

// Resume
sensordplib_set_readyflag(1);
```

### Stopping and Resetting Datapath

```c
// Stop
sensordplib_stop_capture();

// Reset
sensordplib_start_swreset();
sensordplib_stop_swreset_WoSensorCtrl();
```

---

## Appendix: Dependent Headers

```c
#include "hx_drv_hw2x2.h"       // HW2x2_CFG_T
#include "hx_drv_hw5x5.h"       // HW5x5_CFG_T
#include "hx_drv_cdm.h"         // CDM_CFG_T
#include "hx_drv_jpeg.h"        // JPEG_CFG_T
#include "hx_drv_dp.h"          // DP multiplexer
#include "hx_drv_xdma.h"        // DMA
#include "hx_drv_tpg.h"         // TPG
#include "hx_drv_inp.h"         // INP
#include "hx_drv_sensorctrl.h"  // Sensor control
#include "hx_drv_csirx.h"       // MIPI CSI-RX
#include "hx_drv_csitx.h"       // MIPI CSI-TX
#include "hx_drv_hxautoi2c_mst.h" // AUTO I2C
```

---

*Document generated: 2025-12-29*
*Target library: sensordplib (Himax WE2)*
