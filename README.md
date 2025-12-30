# Grove Vision AI V2 - CMake Build System

Seeed Grove Vision AI Module V2のCMakeビルドシステムラッパーです。

## 必要条件

- CMake 3.16以上
- Python 3.x
- Git

### macOS

```bash
# Homebrewでgmakeをインストール（推奨）
brew install cmake make

# makeのバージョンが古い場合はgmakeを使用
# CMakeは自動的にgmakeを検出します
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

既存のクローンでサブモジュールを初期化する場合：

```bash
git submodule update --init --recursive
```

### 2. ツールチェーンのダウンロード

#### Linux/macOS

```bash
./scripts/download_toolchain.sh
```

#### Windows (PowerShell)

```powershell
.\scripts\download_toolchain.ps1
```

CMakeが自動的にツールチェーンをダウンロードすることもできます（`GROVE_DOWNLOAD_TOOLCHAIN=ON`がデフォルト）。

### 3. ビルド

```bash
# ビルドディレクトリの作成と設定
cmake -B build

# ファームウェアのビルド
cmake --build build
```

### 4. 書き込みイメージの生成

```bash
cmake --build build --target image
```

生成されたイメージは `output/firmware.img` に出力されます。

### 5. デバイスへの書き込み

```bash
# Python環境のセットアップ（初回のみ）
./scripts/setup_venv.sh  # Linux/macOS
# または
.\scripts\setup_venv.ps1  # Windows

# 仮想環境の有効化
source .venv/bin/activate  # Linux/macOS
# または
.\.venv\Scripts\Activate.ps1  # Windows

# 書き込み
python external/sdk/xmodem/xmodem_send.py \
    --port=/dev/ttyACM0 \
    --baudrate=921600 \
    --protocol=xmodem \
    --file=output/firmware.img
```

## CMakeオプション

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `GROVE_APP_TYPE` | `allon_sensor_tflm` | アプリケーションタイプ |
| `GROVE_OLEVEL` | `O2` | 最適化レベル (O0, O1, O2, O3, Os, Ofast, Og) |
| `GROVE_DOWNLOAD_TOOLCHAIN` | `ON` | ツールチェーンが見つからない場合に自動ダウンロード |
| `GROVE_VERBOSE` | `OFF` | 詳細なビルド出力を表示 |

### 使用例

```bash
# YOLOv8 物体検出アプリケーションをビルド
cmake -B build -DGROVE_APP_TYPE=tflm_yolov8_od

# デバッグビルド（最適化なし）
cmake -B build -DGROVE_OLEVEL=O0

# 詳細出力でビルド
cmake -B build -DGROVE_VERBOSE=ON
cmake --build build
```

## 利用可能なアプリケーション

| APP_TYPE | 説明 |
|----------|------|
| `allon_sensor_tflm` | センサー + TensorFlow Lite Micro (デフォルト) |
| `allon_sensor_tflm_freertos` | センサー + TFLM + FreeRTOS |
| `allon_jpeg_encode` | JPEGエンコード |
| `tflm_fd_fm` | 顔検出 + 顔認識 |
| `tflm_yolov8_od` | YOLOv8 物体検出 |
| `tflm_yolov8_pose` | YOLOv8 ポーズ推定 |
| `tflm_peoplenet` | PeopleNet |
| `tflm_yolo11_od` | YOLO11 物体検出 |
| `edge_impulse_firmware` | Edge Impulse ファームウェア |

## ビルドターゲット

| ターゲット | 説明 |
|-----------|------|
| `firmware` | ファームウェアをビルド（デフォルト） |
| `firmware_clean` | ビルドをクリーン |
| `image` | 書き込みイメージを生成 |
| `setup_venv` | Python仮想環境をセットアップ |
| `flash` | デバイスに書き込み（GROVE_SERIAL_PORTを設定） |

## ディレクトリ構造

```
grove-vision-ai-v2/
├── CMakeLists.txt              # メインCMake設定
├── README.md                   # このファイル
├── scripts/
│   ├── download_toolchain.sh   # ツールチェーンダウンロード (Linux/macOS)
│   ├── download_toolchain.ps1  # ツールチェーンダウンロード (Windows)
│   ├── setup_venv.sh           # Python venv セットアップ (Linux/macOS)
│   └── setup_venv.ps1          # Python venv セットアップ (Windows)
├── external/
│   └── sdk/  # Seeed Grove Vision AI Module V2 サブモジュール
├── toolchain/                  # ダウンロードされたツールチェーン
├── build/                      # CMakeビルドディレクトリ
├── output/                     # 生成されたイメージ
└── .venv/                      # Python仮想環境
```

## トラブルシューティング

### macOSでmakeのバージョンエラー

macOSのデフォルトのmakeは古い場合があります。gmakeをインストールしてください：

```bash
brew install make
```

CMakeは自動的にgmakeを検出して使用します。

### サブモジュールが見つからない

```bash
git submodule update --init --recursive
```

### ツールチェーンが見つからない

```bash
./scripts/download_toolchain.sh
```

または、CMakeを実行すると自動的にダウンロードされます。

### Python パッケージのインストールエラー

```bash
# 仮想環境を再作成
rm -rf .venv
./scripts/setup_venv.sh
```

## ライセンス

このプロジェクトのビルドシステムはMITライセンスで提供されています。
Seeed Grove Vision AI Module V2のソースコードは元のリポジトリのライセンスに従います。
