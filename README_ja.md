# Grove Vision AI V2 - CMake Build System

Seeed Grove Vision AI Module V2のCMakeビルドシステムです。

[English version](README.md)

## 必要条件

- CMake 3.16以上
- Python 3.x
- Git

### macOS

```bash
brew install cmake
```

### Linux (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install cmake build-essential python3 python3-venv git
```

### Windows

- [CMake](https://cmake.org/download/) をインストール
- [Python](https://www.python.org/downloads/) をインストール
- Git for Windows をインストール

## クイックスタート

### 1. リポジトリのクローン

```bash
git clone --recursive https://github.com/yourusername/grove-vision-ai-v2.git
cd grove-vision-ai-v2
```

### 2. ビルド

```bash
# ビルドディレクトリの作成と設定
cmake -B build -S apps/hello_world

# ファームウェアのビルド（.img も自動生成）
cmake --build build
```

初回実行時に以下が自動的にセットアップされます：
- Git サブモジュールの初期化
- ARM ツールチェーンのダウンロード
- Python 仮想環境の作成

### 3. デバイスへの書き込み

```bash
cmake --build build --target flash
```

デフォルトのシリアルポートは `/dev/ttyACM0` です。変更する場合：

```bash
cmake -B build -S apps/hello_world -DGROVE_SERIAL_PORT=/dev/ttyUSB0
cmake --build build --target flash
```

## 利用可能なアプリケーション

| アプリケーション | 説明 |
|-----------------|------|
| `hello_world` | 基本的なHello Worldサンプル |
| `hello_world_freertos` | FreeRTOS Hello Worldサンプル |
| `hello_world_cmsis_dsp` | CMSIS-DSP Hello Worldサンプル |
| `hello_world_cmsis_cv` | CMSIS-CV (Helium) コンピュータビジョンサンプル |
| `allon_sensor_tflm` | カメラセンサー + TensorFlow Lite Micro |
| `allon_sensor_tflm_freertos` | カメラセンサー + TFLM + FreeRTOS |
| `allon_sensor_tflm_fatfs` | カメラセンサー + TFLM + FatFS (SDカード) |
| `allon_sensor_tflm_cmsis_nn` | カメラセンサー + TFLM + CMSIS-NN |
| `allon_jpeg_encode` | JPEGエンコード + SPI出力 |
| `tflm_yolo11_od` | YOLO11物体検出 + モデルフラッシュ |
| `tflm_yolov8_pose` | YOLOv8姿勢推定 + モデルフラッシュ |

### アプリケーションのビルド

```bash
cmake -B build -S apps/<app_name>
cmake --build build
cmake --build build --target flash
```

### モデルフラッシュ対応アプリケーション

`tflm_yolo11_od` と `tflm_yolov8_pose` はモデルの書き込みが必要です：

```bash
# ファームウェアとモデルを一緒に書き込み
cmake --build build --target flash

# モデルのみ書き込み
cmake --build build --target flash-model
```

## CMakeオプション

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `GROVE_SERIAL_PORT` | `/dev/ttyACM0` | 書き込み用シリアルポート |
| `GROVE_SERIAL_BAUDRATE` | `921600` | シリアルボーレート |
| `CIS_SENSOR_MODEL` | (アプリ依存) | カメラセンサーモデル |
| `SDK_TFLM_VERSION` | (アプリ依存) | TFLMライブラリバージョン |
| `SDK_TFLM_FORCE_PREBUILT` | `OFF` | プリビルトTFLMライブラリを使用 |
| `SDK_CMSIS_NN_FORCE_PREBUILT` | `OFF` | プリビルトCMSIS-NNライブラリを使用 |

### カメラセンサーオプション

```bash
cmake -B build -S apps/allon_sensor_tflm -DCIS_SENSOR_MODEL=cis_ov5647
```

利用可能なセンサー: `cis_hm0360`, `cis_ov5647`, `cis_imx219`, `cis_imx477`, `cis_imx708`

### TFLMバージョンオプション

```bash
cmake -B build -S apps/allon_sensor_tflm -DSDK_TFLM_VERSION=tflmtag2209_u55tag2205
```

利用可能なバージョン:
- `tflmtag2209_u55tag2205` - 2022年9月 TFLM + 2022年5月 U55
- `tflmtag2212_u55tag2205` - 2022年12月 TFLM + 2022年5月 U55
- `tflmtag2412_u55tag2411` - 2024年12月 TFLM + 2024年11月 U55 (最新)

## ビルドターゲット

| ターゲット | 説明 |
|-----------|------|
| `all` | ファームウェアをビルド（.elf, .bin, .img を生成） |
| `flash` | デバイスに書き込み |
| `flash-model` | モデルのみ書き込み（YOLOアプリ用） |

## ディレクトリ構造

```
grove-vision-ai-v2/
├── README.md
├── README_ja.md
├── apps/
│   ├── hello_world/              # 基本サンプル
│   ├── hello_world_freertos/     # FreeRTOSサンプル
│   ├── hello_world_cmsis_dsp/    # CMSIS-DSPサンプル
│   ├── hello_world_cmsis_cv/     # CMSIS-CVサンプル
│   ├── allon_sensor_tflm/        # カメラ + TFLM
│   ├── allon_sensor_tflm_freertos/  # カメラ + TFLM + FreeRTOS
│   ├── allon_sensor_tflm_fatfs/  # カメラ + TFLM + FatFS
│   ├── allon_sensor_tflm_cmsis_nn/  # カメラ + TFLM + CMSIS-NN
│   ├── allon_jpeg_encode/        # JPEGエンコード
│   ├── tflm_yolo11_od/           # YOLO11物体検出
│   └── tflm_yolov8_pose/         # YOLOv8姿勢推定
├── cmake/
│   ├── setup.cmake               # 開発環境セットアップ
│   ├── arm-none-eabi-gcc.cmake   # ツールチェーンファイル
│   └── sdk/
│       ├── device.cmake          # デバイスライブラリ
│       ├── board.cmake           # ボードライブラリ
│       ├── interface.cmake       # インターフェースライブラリ
│       ├── common.cmake          # 共通ライブラリ
│       ├── trustzone.cmake       # TrustZone設定
│       ├── library.cmake         # SDKライブラリ
│       ├── tflm.cmake            # TensorFlow Lite Micro
│       ├── cmsis_nn.cmake        # CMSIS-NNライブラリ
│       ├── cmsis_dsp.cmake       # CMSIS-DSPライブラリ
│       ├── cmsis_cv.cmake        # CMSIS-CVライブラリ
│       ├── freertos.cmake        # FreeRTOSサポート
│       ├── fatfs.cmake           # FatFSサポート
│       ├── event_handler.cmake   # イベントハンドラー
│       ├── linker.cmake          # リンカー設定
│       ├── image.cmake           # イメージ生成
│       └── flash.cmake           # 書き込み設定
├── scripts/
│   ├── download_toolchain.sh     # ツールチェーンダウンロード (Linux/macOS)
│   └── download_toolchain.ps1    # ツールチェーンダウンロード (Windows)
├── external/
│   └── sdk/                      # Seeed SDKサブモジュール
├── toolchain/                    # ダウンロードされたツールチェーン
└── .venv/                        # Python仮想環境
```

## 新しいアプリケーションの作成

`apps/hello_world/` をテンプレートとして使用できます：

```bash
cp -r apps/hello_world apps/my_app
```

`apps/my_app/CMakeLists.txt` の `project()` 名を変更してビルド：

```bash
cmake -B build -S apps/my_app
cmake --build build
```

## トラブルシューティング

### サブモジュールが見つからない

CMakeが自動的に初期化しますが、手動で実行する場合：

```bash
git submodule update --init --recursive
```

### ツールチェーンが見つからない

CMakeが自動的にダウンロードしますが、手動で実行する場合：

```bash
./scripts/download_toolchain.sh
```

### Python パッケージのインストールエラー

```bash
# 仮想環境を再作成
rm -rf .venv
cmake -B build -S apps/hello_world  # 自動的に再作成されます
```

### シリアルポートのアクセス権限エラー (Linux)

```bash
sudo usermod -a -G dialout $USER
# ログアウトして再ログイン
```

## ライセンス

このプロジェクトのビルドシステムはMITライセンスで提供されています。
Seeed Grove Vision AI Module V2のソースコードは元のリポジトリのライセンスに従います。
