# sensordplib API リファレンス

Himax WE2 センサーデータパスライブラリのAPIドキュメント

**ファイル:** `EPII_CM55M_APP_S/library/sensordp/inc/sensor_dp_lib.h`

---

## 目次

1. [概要](#1-概要)
2. [列挙型](#2-列挙型)
3. [構造体](#3-構造体)
4. [コールバック](#4-コールバック)
5. [初期化・制御API](#5-初期化制御api)
6. [データパス設定API](#6-データパス設定api)
7. [xDMA管理API](#7-xdma管理api)
8. [MIPI CSI-RX API](#8-mipi-csi-rx-api)
9. [MIPI CSI-TX API](#9-mipi-csi-tx-api)
10. [AUTO I2C API](#10-auto-i2c-api)
11. [ユーティリティAPI](#11-ユーティリティapi)
12. [使用例](#12-使用例)

---

## 1. 概要

`sensordplib`は、Himax WE2プラットフォームのセンサーデータパス（ISPパイプライン）を制御するためのライブラリです。カメラセンサーからの画像データをハードウェアアクセラレータ（HW2x2, HW5x5, CDM, JPEG）を通じて処理し、メモリに出力します。

### 主な機能

- センサー入力制御（INP）
- ハードウェアアクセラレータ設定（HW2x2, HW5x5, CDM, JPEG）
- DMA転送管理（WDMA1/2/3, RDMA）
- MIPI CSI-RX/TX制御
- 自動I2C制御（PMUモード用）
- RTCタイマーによる周期キャプチャ

### アーキテクチャ図

```
┌─────────────────────────────────────────────────────────────────────┐
│                    sensordplib データパス構成                        │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  [センサー] → [INP] → [HW2x2] → [CDM] → [WDMA1]                    │
│                  │                                                  │
│                  └──→ [HW5x5] → [JPEG] → [WDMA2]                   │
│                           │                                         │
│                           └──→ [WDMA3] (YUV/RGB Raw)               │
│                                                                     │
│  [RDMA] → [TPG] → [JPEG Dec] → [WDMA3]                             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 2. 列挙型

### SENSORDPLIB_PATH_E

データパスの構成を選択します。

| 値 | 説明 | データフロー |
|----|------|--------------|
| `SENSORDPLIB_PATH_INP_WDMA2` | RAW出力 | Sensor → INP → WDMA2 |
| `SENSORDPLIB_PATH_INP_HW2x2_CDM` | 動き検出 | Sensor → INP → 2x2 → CDM → WDMA1 |
| `SENSORDPLIB_PATH_INP_HW5x5` | デモザイク | Sensor → INP → 5x5 → WDMA3 |
| `SENSORDPLIB_PATH_INP_HW5x5_JPEG` | JPEG出力 | Sensor → INP → 5x5 → JPEG → WDMA2 |
| `SENSORDPLIB_PATH_JPEGDEC` | JPEGデコード | RDMA → JPEG Dec → WDMA3 |
| `SENSORDPLIB_PATH_INP_HW2x2` | 2x2フィルタ | Sensor → INP → 2x2 → WDMA1 |
| `SENSORDPLIB_PATH_INP_CDM` | CDMのみ | Sensor → INP → CDM → WDMA1 |
| `SENSORDPLIB_PATH_INT1` | **完全統合** | CDM+YUV+JPEG同時出力 |
| `SENSORDPLIB_PATH_INTNOJPEG` | 統合(JPEG無し) | CDM+YUV出力 |
| `SENSORDPLIB_PATH_INT3` | RAW+YUV統合 | RAW(WDMA2)+YUV(WDMA3) |
| `SENSORDPLIB_PATH_INT_INP_HW5X5_JPEG` | **推奨** | YUV(WDMA3)+JPEG(WDMA2) |
| `SENSORDPLIB_PATH_TPG_JPEGENC` | TPG→JPEG | RDMA → TPG → JPEG → WDMA2 |

### SENSORDPLIB_SENSOR_E

サポートされるセンサータイプ。

| 値 | 説明 |
|----|------|
| `SENSORDPLIB_SENSOR_HM0360_MODE1` | HM0360 Mode1 (8bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE2` | HM0360 Mode2 (8bit IO, 4bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE3` | HM0360 Mode3 (4bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM0360_MODE5` | HM0360 Mode5 (1bit IO, 8bit data) |
| `SENSORDPLIB_SENSOR_HM01B0_8BITIO` | HM01B0 8bit IO |
| `SENSORDPLIB_SENSOR_HM11B1_LSB` | HM11B1 LSB |
| `SENSORDPLIB_SENSOR_HM2170_MIPI` | HM2170 MIPI |
| `SENSORDPLIB_SENSOR_HM2130` | HM2130 (OV5647等に使用) |

### SENSORDPLIB_STREAM_E

センサーストリーミングモード。

| 値 | 説明 |
|----|------|
| `SENSORDPLIB_STREAM_NONEAOS` | **標準** - I2Cマスターによるストリーミング |
| `SENSORDPLIB_STREAM_HM01B0_CONT` | HM01B0 連続モード (HWトリガー) |
| `SENSORDPLIB_STREAM_HM0360_CONT` | HM0360 連続モード (MCLK無し) |
| `SENSORDPLIB_STREAM_HM0360_BURST` | HM0360 バーストモード |
| `SENSORDPLIB_STREAM_HM0360_SENSOR_ACT` | HM0360 センサーアクティブモード |
| `SENSORDPLIB_STREAM_HM11B1_LOWPOWER` | HM11B1 低電力モード |
| `SENSORDPLIB_STREAM_NONEAOS_AUTOI2C` | AUTO I2C制御モード |

### SENSORDPLIB_STATUS_E

コールバックイベントステータス。

**正常イベント:**

| 値 | 説明 |
|----|------|
| `SENSORDPLIB_STATUS_XDMA_FRAME_READY` | **フレーム準備完了** (最重要) |
| `SENSORDPLIB_STATUS_CDM_MOTION_DETECT` | 動き検出 |
| `SENSORDPLIB_STATUS_XDMA_WDMA1_FINISH` | WDMA1完了 |
| `SENSORDPLIB_STATUS_XDMA_WDMA2_FINISH` | WDMA2完了 |
| `SENSORDPLIB_STATUS_XDMA_WDMA3_FINISH` | WDMA3完了 |
| `SENSORDPLIB_STATUS_TIMER_FIRE_APP_READY` | タイマー発火(準備完了) |

**エラーイベント (負の値):**

| 値 | 説明 |
|----|------|
| `SENSORDPLIB_STATUS_ERR_FS_ERR` (-100) | フレームスタートエラー |
| `SENSORDPLIB_STATUS_EDM_WDT1_TIMEOUT` (-75) | WDMA1 ウォッチドッグタイムアウト |
| `SENSORDPLIB_STATUS_CDM_FIFO_OVERFLOW` (-60) | CDM FIFOオーバーフロー |
| `SENSORDPLIB_STATUS_XDMA_WDMA1_ABNORMALx` (-50~) | WDMA1異常 |
| `SENSORDPLIB_STATUS_XDMA_WDMA2_ABNORMALx` (-40~) | WDMA2異常 |
| `SENSORDPLIB_STATUS_XDMA_WDMA3_ABNORMALx` (-30~) | WDMA3異常 |

---

## 3. 構造体

### SENSORDPLIB_HOGDMA_CFG_T

HOG DMA設定。

```c
typedef struct {
    uint32_t wdma_startaddr;        // HOG WDMA 出力先アドレス
    uint32_t rdma_ch1_startaddr;    // HOG RDMA Y チャネルアドレス
    uint32_t rdma_ch2_startaddr;    // HOG RDMA U チャネルアドレス
    uint32_t rdma_ch3_startaddr;    // HOG RDMA V チャネルアドレス
} SENSORDPLIB_HOGDMA_CFG_T;
```

### SENSORDPLIB_RDMA_CFG_T

TPGパス用RDMA設定。

```c
typedef struct {
    uint32_t rdma_ch1_startaddr;    // TPG RDMA チャネル1アドレス
    uint32_t rdma_ch2_startaddr;    // TPG RDMA チャネル2アドレス
    uint32_t rdma_ch3_startaddr;    // TPG RDMA チャネル3アドレス
} SENSORDPLIB_RDMA_CFG_T;
```

### SENSORDPLIB_HM11B1_HEADER_T

HM11B1センサーヘッダ情報。

```c
typedef struct {
    INP_1BITPARSER_FSM_E fsm;       // 1bit INP parser FSM状態
    uint16_t hw_hsize;              // HW計算 HSIZE
    uint16_t hw_vsize;              // HW計算 VSIZE
    uint16_t sensor_hsize;          // センサーヘッダ HSIZE
    uint16_t sensor_vsize;          // センサーヘッダ VSIZE
    uint16_t frame_len;             // フレーム長
    uint16_t line_len;              // ライン長
    uint8_t again;                  // アナログゲイン
    uint16_t dgain;                 // デジタルゲイン
    uint16_t intg;                  // 積分時間
    uint16_t sensor_crc;            // センサーCRC
    uint16_t hw_crc;                // HW計算CRC
    uint16_t err_status;            // エラーステータス
} SENSORDPLIB_HM11B1_HEADER_T;
```

---

## 4. コールバック

### sensordplib_CBEvent_t

データパスイベントコールバック関数型。

```c
typedef void (*sensordplib_CBEvent_t)(SENSORDPLIB_STATUS_E event);
```

**使用例:**

```c
void my_dp_callback(SENSORDPLIB_STATUS_E event) {
    switch(event) {
        case SENSORDPLIB_STATUS_XDMA_FRAME_READY:
            // フレーム準備完了 - 推論実行
            process_frame();
            sensordplib_retrigger_capture();  // 次フレーム要求
            break;
        case SENSORDPLIB_STATUS_CDM_MOTION_DETECT:
            // 動き検出
            handle_motion();
            break;
        default:
            if(event < 0) {
                // エラー処理
                handle_error(event);
            }
            break;
    }
}
```

---

## 5. 初期化・制御API

### sensordplib_init

ライブラリを初期化します。

```c
void sensordplib_init();
```

### sensordplib_set_sensorctrl_inp

センサー制御とINP（入力プロセッサ）を設定します。

```c
int sensordplib_set_sensorctrl_inp(
    SENSORDPLIB_SENSOR_E sensor_type,   // センサータイプ
    SENSORDPLIB_STREAM_E type,          // ストリーミングモード
    uint16_t hsize,                     // 水平サイズ
    uint16_t frame_len,                 // フレーム長
    INP_SUBSAMPLE_E subsample           // サブサンプリング設定
);
```

**戻り値:** 0=成功, -1=失敗

### sensordplib_set_sensorctrl_inp_wi_crop

クロップ付きでセンサー制御とINPを設定します。

```c
int sensordplib_set_sensorctrl_inp_wi_crop(
    SENSORDPLIB_SENSOR_E sensor_type,
    SENSORDPLIB_STREAM_E type,
    uint16_t hsize,
    uint16_t frame_len,
    INP_SUBSAMPLE_E subsample,
    INP_CROP_T crop                     // クロップ設定
);
```

### sensordplib_set_sensorctrl_inp_wi_crop_bin

クロップとビニング付きでセンサー制御とINPを設定します（IC_VERSION >= 30）。

```c
int sensordplib_set_sensorctrl_inp_wi_crop_bin(
    SENSORDPLIB_SENSOR_E sensor_type,
    SENSORDPLIB_STREAM_E type,
    uint16_t hsize,
    uint16_t frame_len,
    INP_SUBSAMPLE_E subsample,
    INP_CROP_T crop,
    INP_BINNING_E binmode               // ビニングモード
);
```

### sensordplib_set_sensorctrl_start

キャプチャを開始します。

```c
int sensordplib_set_sensorctrl_start();
```

**戻り値:** 0=成功, -1=失敗

### sensordplib_set_rtc_start

RTCタイマーによる周期キャプチャを開始します。

```c
int sensordplib_set_rtc_start(uint32_t time_interval);  // 間隔(ms)
```

### sensordplib_stop_capture

キャプチャを停止します。

```c
void sensordplib_stop_capture();
```

**実行される処理:**
1. xDMA無効化
2. DPマルチプレクサ無効化
3. CDM無効化
4. 周期タイマー無効化
5. センサーコントロールをSWRESET
6. EDM WDT停止

### sensordplib_retrigger_capture

次のフレームキャプチャをトリガーします。

```c
void sensordplib_retrigger_capture();
```

**注意:** RTCタイマー未使用時、フレーム準備完了後にこの関数を呼び出して次フレームを要求します。

### sensordplib_start_swreset

データパスのソフトウェアリセットを実行します。

```c
void sensordplib_start_swreset();
```

**リセット対象:**
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

センサーコントロール以外を通常モードに戻します。

```c
void sensordplib_stop_swreset_WoSensorCtrl();
```

### sensordplib_set_mclkctrl_xsleepctrl_bySCMode

ストリーミングモードに基づいてMCLKとxSleep制御を設定します。

```c
void sensordplib_set_mclkctrl_xsleepctrl_bySCMode();
```

---

## 6. データパス設定API

### 単一パス設定

#### sensordplib_set_raw_wdma2

RAW出力パスを設定します。

```c
void sensordplib_set_raw_wdma2(
    uint16_t width,                     // 入力幅
    uint16_t height,                    // 入力高さ
    sensordplib_CBEvent_t dplib_cb      // コールバック
);
```

**データフロー:** Sensor → INP → WDMA2

#### sensordplib_set_hw5x5_wdma3

HW5x5デモザイクパスを設定します。

```c
void sensordplib_set_hw5x5_wdma3(
    HW5x5_CFG_T hw5x5_cfg,              // HW5x5設定
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** Sensor → INP → HW5x5 → WDMA3

#### sensordplib_set_HW2x2_wdma1

HW2x2フィルタパスを設定します。

```c
void sensordplib_set_HW2x2_wdma1(
    HW2x2_CFG_T hw2x2_cfg,              // HW2x2設定
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** Sensor → INP → HW2x2 → WDMA1

#### sensordplib_set_CDM

CDM（動き検出）パスを設定します。

```c
void sensordplib_set_CDM(
    CDM_CFG_T cdm_cfg,                  // CDM設定
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** Sensor → INP → CDM → WDMA1

#### sensordplib_set_HW2x2_CDM

HW2x2 + CDMパスを設定します。

```c
void sensordplib_set_HW2x2_CDM(
    HW2x2_CFG_T hw2x2_cfg,
    CDM_CFG_T cdm_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** Sensor → INP → HW2x2 → CDM → WDMA1

#### sensordplib_set_hw5x5_jpeg_wdma2

HW5x5 + JPEG出力パスを設定します。

```c
void sensordplib_set_hw5x5_jpeg_wdma2(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,          // サイクリックバッファ数
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** Sensor → INP → HW5x5 → JPEG → WDMA2

### 統合パス設定

#### sensordplib_set_INT1_HWACC

**完全統合パス** - CDM + YUV + JPEG同時出力。

```c
void sensordplib_set_INT1_HWACC(
    HW2x2_CFG_T hw2x2_cfg,              // HW2x2設定
    CDM_CFG_T cdm_cfg,                  // CDM設定
    HW5x5_CFG_T hw5x5_cfg,              // HW5x5設定
    JPEG_CFG_T jpeg_cfg,                // JPEG設定
    uint8_t cyclic_buffer_cnt,          // JPEGサイクリックバッファ数
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:**
- Sensor → INP → HW2x2 → CDM → WDMA1
- Sensor → INP → HW5x5(YUV) → JPEG → WDMA2
- Sensor → INP → HW5x5(YUV) → WDMA3

#### sensordplib_set_INTNoJPEG_HWACC

JPEG無し統合パス。

```c
void sensordplib_set_INTNoJPEG_HWACC(
    HW2x2_CFG_T hw2x2_cfg,
    CDM_CFG_T cdm_cfg,
    HW5x5_CFG_T hw5x5_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:**
- Sensor → INP → HW2x2 → CDM → WDMA1
- Sensor → INP → HW5x5 → WDMA3

#### sensordplib_set_int_hw5x5_jpeg_wdma23

**推奨パス** - YUV + JPEG同時出力（TFLite推論向け）。

```c
void sensordplib_set_int_hw5x5_jpeg_wdma23(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:**
- Sensor → INP → HW5x5(YUV) → JPEG → WDMA2
- Sensor → INP → HW5x5(YUV) → WDMA3

#### sensordplib_set_int_hw5x5rgb_jpeg_wdma23

RGB出力 + JPEG同時出力。

```c
void sensordplib_set_int_hw5x5rgb_jpeg_wdma23(
    HW5x5_CFG_T hw5x5_cfg,
    JPEG_CFG_T jpeg_cfg,
    uint8_t cyclic_buffer_cnt,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:**
- Sensor → INP → HW5x5(RGB) → RGB2YUV → JPEG → WDMA2
- Sensor → INP → HW5x5(RGB) → WDMA3

#### sensordplib_set_int_raw_hw5x5_wdma23

RAW + YUV同時出力。

```c
void sensordplib_set_int_raw_hw5x5_wdma23(
    uint16_t width,
    uint16_t height,
    HW5x5_CFG_T hw5x5_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:**
- Sensor → INP → WDMA2 (RAW)
- Sensor → INP → HW5x5 → WDMA3 (YUV)

### JPEG デコーダパス

#### sensordplib_set_jpegdec

JPEGデコードパスを設定します。

```c
void sensordplib_set_jpegdec(
    JPEG_CFG_T jpegdec_cfg,
    uint16_t in_width,                  // 入力幅
    uint16_t in_height,                 // 入力高さ
    uint32_t frame_no,                  // フレーム番号
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** RDMA → JPEG Dec → WDMA3

### TPGパス

#### sensordplib_tpg_jpegenc_wdma2

TPGからJPEGエンコードパスを設定します。

```c
void sensordplib_tpg_jpegenc_wdma2(
    JPEG_CFG_T jpeg_cfg,
    uint32_t wdma2_startaddr,           // WDMA2出力アドレス
    uint8_t jpegfilesize_fillen,        // ファイルサイズ保存有効化
    uint32_t jpegfilesize_filladdr,     // ファイルサイズ保存アドレス
    SENSORDPLIB_RDMA_CFG_T dplib_rdma_cfg,
    sensordplib_CBEvent_t dplib_cb
);
```

**データフロー:** RDMA → TPG → JPEG → WDMA2

---

## 7. xDMA管理API

### sensordplib_set_xDMA_baseaddrbyapp

xDMAベースアドレスを設定します。

```c
void sensordplib_set_xDMA_baseaddrbyapp(
    uint32_t wdma1_addr,                // WDMA1ベースアドレス
    uint32_t wdma2_addr,                // WDMA2ベースアドレス
    uint32_t wdma3_addr                 // WDMA3ベースアドレス
);
```

**デフォルト値:**
- WDMA1: 0x20050000 (HW2x2/CDM用)
- WDMA2: 0x2009B000 (JPEG用)
- WDMA3: 0x200E6000 (HW5x5用)

### sensordplib_get_xDMA_baseaddr

現在のxDMAベースアドレスを取得します。

```c
void sensordplib_get_xDMA_baseaddr(
    uint32_t *wdma1_addr,
    uint32_t *wdma2_addr,
    uint32_t *wdma3_addr
);
```

### sensordplib_set_jpegfilesize_addrbyapp

JPEG自動ファイルサイズ保存アドレスを設定します。

```c
void sensordplib_set_jpegfilesize_addrbyapp(uint32_t jpegfilesize_autoaddr);
```

**デフォルト:** 0x2015FE70

### sensordplib_get_jpegfilesize_addrbyapp

JPEG自動ファイルサイズ保存アドレスを取得します。

```c
void sensordplib_get_jpegfilesize_addrbyapp(uint32_t *jpegfilesize_autoaddr);
```

### sensordplib_get_xdma_fin

xDMA完了フラグを取得します（デバッグ用）。

```c
void sensordplib_get_xdma_fin(
    uint8_t *wdma1_fin,                 // WDMA1完了フラグ
    uint8_t *wdma2_fin,                 // WDMA2完了フラグ
    uint8_t *wdma3_fin,                 // WDMA3完了フラグ
    uint8_t *rdma_fin                   // RDMA完了フラグ
);
```

### sensordplib_get_xdma_sc_finflag

xDMAとセンサーコントロールの完了フラグを取得します。

```c
void sensordplib_get_xdma_sc_finflag(
    uint8_t *xdma_fin_flag,             // xDMA完了フラグ
    uint8_t *sc_fin_flag                // センサーコントロール完了フラグ
);
```

---

## 8. MIPI CSI-RX API

### sensordplib_csirx_enable

MIPI CSI-RXを有効化します。

```c
void sensordplib_csirx_enable(uint8_t lane_nb);  // レーン数
```

### sensordplib_csirx_disable

MIPI CSI-RXを無効化します。

```c
void sensordplib_csirx_disable(void);
```

### sensordplib_csirx_set_vcnum

バーチャルチャネル番号を設定します。

```c
void sensordplib_csirx_set_vcnum(uint8_t vc_num);
```

### sensordplib_csirx_set_hscnt

HS-Count設定を行います。

```c
void sensordplib_csirx_set_hscnt(MIPIRX_DPHYHSCNT_CFG_T hs_cnt);
```

### sensordplib_csirx_set_deskew

DESKEW機能を設定します。

```c
void sensordplib_csirx_set_deskew(uint8_t enable);
```

### sensordplib_csirx_set_pixel_depth

ピクセル深度を設定します。

```c
void sensordplib_csirx_set_pixel_depth(uint8_t depth);  // 8 or 10
```

### sensordplib_csirx_set_fifo_fill

FIFO FILLを設定します。

```c
void sensordplib_csirx_set_fifo_fill(uint16_t fifo_fill);
```

### sensordplib_csirx_set_lnswap_enable

レーンスワップを有効化します。

```c
void sensordplib_csirx_set_lnswap_enable(uint8_t enable);
```

---

## 9. MIPI CSI-TX API

### sensordplib_csitx_enable

MIPI CSI-TXを有効化します。

```c
void sensordplib_csitx_enable(
    uint8_t lane_nb,                    // レーン数
    uint16_t bit_rate,                  // ビットレート
    uint16_t line_len,                  // ライン長
    uint16_t frame_len                  // フレーム長
);
```

### sensordplib_csitx_disable

MIPI CSI-TXを無効化します。

```c
void sensordplib_csitx_disable(void);
```

### sensordplib_csitx_set_dphy_clkmode

クロックモードを設定します。

```c
void sensordplib_csitx_set_dphy_clkmode(CSITX_DPHYCLKMODE_E clkmode);
```

### sensordplib_csitx_set_fifo_fill

TX FIFO FILLを設定します。

```c
void sensordplib_csitx_set_fifo_fill(uint16_t fifo_fill);
```

### sensordplib_csitx_set_pixel_depth

TXピクセル深度を設定します。

```c
void sensordplib_csitx_set_pixel_depth(uint8_t depth);
```

---

## 10. AUTO I2C API

PMUモードでのセンサー自動制御用。

### sensordplib_autoi2c_cfg

AUTO I2C設定を行います。

```c
void sensordplib_autoi2c_cfg(
    HXAUTOI2CHC_STATIC_CFG_T scfg,      // 静的設定
    HXAUTOI2CHC_INT_CFG_T icfg,         // 割り込み設定
    HXAUTOI2CHC_CMD_CFG_T trig_cfg,     // トリガーコマンド設定
    HXAUTOI2CHC_CMD_CFG_T stop_cfg      // 停止コマンド設定
);
```

### sensordplib_autoi2c_trigcmd

トリガーコマンドを設定します。

```c
void sensordplib_autoi2c_trigcmd(
    HXAUTOI2CHC_CMD_T cmd1,
    HXAUTOI2CHC_CMD_T cmd2,
    HXAUTOI2CHC_CMD_T cmd3,
    HXAUTOI2CHC_CMD_T cmd4
);
```

### sensordplib_autoi2c_stopcmd

停止コマンドを設定します。

```c
void sensordplib_autoi2c_stopcmd(
    HXAUTOI2CHC_CMD_T cmd1,
    HXAUTOI2CHC_CMD_T cmd2,
    HXAUTOI2CHC_CMD_T cmd3,
    HXAUTOI2CHC_CMD_T cmd4
);
```

### sensordplib_autoi2c_enable / disable

AUTO I2Cを有効化/無効化します。

```c
void sensordplib_autoi2c_enable(void);
void sensordplib_autoi2c_disable(void);
```

---

## 11. ユーティリティAPI

### sensordplib_get_version

ライブラリバージョンを取得します。

```c
void sensordplib_get_version(uint32_t *version);
```

### sensordplib_get_cur_dp_path

現在のデータパスを取得します。

```c
void sensordplib_get_cur_dp_path(SENSORDPLIB_PATH_E *dplib_case);
```

### sensorlib_get_cur_sensortype

現在のセンサータイプを取得します。

```c
void sensorlib_get_cur_sensortype(SENSORDPLIB_SENSOR_E *cursensorId);
```

### sensordplib_set_readyflag

準備フラグを設定します（RTCタイマー使用時）。

```c
void sensordplib_set_readyflag(uint8_t ready_flag);
// ready_flag = 1: タイマー発火時にキャプチャ実行
// ready_flag = 0: タイマー発火時にキャプチャ一時停止
```

### sensordplib_get_readyflag

準備フラグを取得します。

```c
void sensordplib_get_readyflag(uint8_t *ready_flag);
```

### sensordplib_get_status

ライブラリステータスを取得します（デバッグ用）。

```c
void sensordplib_get_status(
    uint8_t *ready_flag,                // 準備フラグ
    uint8_t *nframe_end,                // NFrame End ステータス
    uint8_t *xdmadone                   // xDMA完了フラグ
);
```

### sensordplib_edm_wdt_config

EDMウォッチドッグを設定します。

```c
void sensordplib_edm_wdt_config(
    uint8_t wdt1_en,                    // WDMA1 WDT有効化
    uint8_t wdt2_en,                    // WDMA2 WDT有効化
    uint8_t wdt3_en                     // WDMA3 WDT有効化
);
```

### sensordplib_inp_set_crop_area

INPクロップ領域を設定します。

```c
void sensordplib_inp_set_crop_area(INP_CROP_T crop);
```

### hx_dplib_register_cb

コールバック関数を登録します。

```c
void hx_dplib_register_cb(
    sensordplib_CBEvent_t cb_event,
    SENSORDPLIB_CB_FUNTYPE_E type       // DP, RS, HOG, JPEG_DEC
);
```

### sensordplib_gated_dp_clk_bycase / ungated

データパスクロックをゲート/アンゲートします。

```c
void sensordplib_gated_dp_clk_bycase(SENSORDPLIB_PATH_E dplib_case);
void sensordplib_ungated_dp_clk_bycase(SENSORDPLIB_PATH_E dplib_case);
```

---

## 12. 使用例

### 基本的なキャプチャフロー

```c
#include "sensor_dp_lib.h"
#include "hx_drv_hw5x5.h"
#include "hx_drv_jpeg.h"

// グローバル変数
static volatile uint8_t g_frame_ready = 0;

// コールバック関数
void dp_callback(SENSORDPLIB_STATUS_E event) {
    if(event == SENSORDPLIB_STATUS_XDMA_FRAME_READY) {
        g_frame_ready = 1;
    }
}

int main(void) {
    // 1. ライブラリ初期化
    sensordplib_init();

    // 2. xDMAアドレス設定
    sensordplib_set_xDMA_baseaddrbyapp(
        0x20050000,  // WDMA1
        0x2009B000,  // WDMA2 (JPEG)
        0x200E6000   // WDMA3 (YUV)
    );
    sensordplib_set_jpegfilesize_addrbyapp(0x2015FE70);

    // 3. センサー設定
    sensordplib_set_sensorctrl_inp(
        SENSORDPLIB_SENSOR_HM2130,       // OV5647等
        SENSORDPLIB_STREAM_NONEAOS,
        640, 480,
        INP_SUBSAMPLE_DISABLE
    );

    // 4. HW5x5設定
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

    // 5. JPEG設定
    JPEG_CFG_T jpeg_cfg = {
        .jpeg_path = JPEG_PATH_ENCODER_EN,
        .enc_width = 640,
        .enc_height = 480,
        .jpeg_enctype = JPEG_ENC_TYPE_YUV420,
        .jpeg_encqtable = JPEG_ENC_QTABLE_10X
    };

    // 6. データパス設定 (YUV + JPEG同時出力)
    sensordplib_set_int_hw5x5_jpeg_wdma23(
        hw5x5_cfg,
        jpeg_cfg,
        1,           // サイクリックバッファ数
        dp_callback
    );

    // 7. MCLKとxSleep制御設定
    sensordplib_set_mclkctrl_xsleepctrl_bySCMode();

    // 8. キャプチャ開始
    sensordplib_set_sensorctrl_start();

    // 9. メインループ
    while(1) {
        if(g_frame_ready) {
            g_frame_ready = 0;

            // フレーム処理
            process_yuv_frame();

            // 次フレーム要求
            sensordplib_retrigger_capture();
        }
    }

    return 0;
}
```

### RTCタイマーによる周期キャプチャ

```c
// 周期キャプチャ開始 (500ms間隔)
sensordplib_set_sensorctrl_start();
sensordplib_set_rtc_start(500);

// 一時停止
sensordplib_set_readyflag(0);

// 再開
sensordplib_set_readyflag(1);
```

### データパスの停止とリセット

```c
// 停止
sensordplib_stop_capture();

// リセット
sensordplib_start_swreset();
sensordplib_stop_swreset_WoSensorCtrl();
```

---

## 付録: 依存ヘッダ

```c
#include "hx_drv_hw2x2.h"       // HW2x2_CFG_T
#include "hx_drv_hw5x5.h"       // HW5x5_CFG_T
#include "hx_drv_cdm.h"         // CDM_CFG_T
#include "hx_drv_jpeg.h"        // JPEG_CFG_T
#include "hx_drv_dp.h"          // DPマルチプレクサ
#include "hx_drv_xdma.h"        // DMA
#include "hx_drv_tpg.h"         // TPG
#include "hx_drv_inp.h"         // INP
#include "hx_drv_sensorctrl.h"  // センサー制御
#include "hx_drv_csirx.h"       // MIPI CSI-RX
#include "hx_drv_csitx.h"       // MIPI CSI-TX
#include "hx_drv_hxautoi2c_mst.h" // AUTO I2C
```

---

*ドキュメント生成日: 2025-12-29*
*対象ライブラリ: sensordplib (Himax WE2)*
