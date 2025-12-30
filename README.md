# Grove Vision AI V2 - CMake Build System

Seeed Grove Vision AI Module V2のCMakeビルドシステムです。

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

## CMakeオプション

| オプション | デフォルト | 説明 |
|-----------|----------|------|
| `GROVE_SERIAL_PORT` | `/dev/ttyACM0` | 書き込み用シリアルポート |
| `GROVE_SERIAL_BAUDRATE` | `921600` | シリアルボーレート |

## ビルドターゲット

| ターゲット | 説明 |
|-----------|------|
| `all` | ファームウェアをビルド（.elf, .bin, .img を生成） |
| `flash` | デバイスに書き込み |

## ディレクトリ構造

```
grove-vision-ai-v2/
├── README.md
├── apps/
│   └── hello_world/          # サンプルアプリケーション
│       ├── CMakeLists.txt
│       └── main.c
├── cmake/
│   ├── setup.cmake           # 開発環境セットアップ
│   ├── arm-none-eabi-gcc.cmake  # ツールチェーンファイル
│   └── sdk/
│       ├── sdk_base.cmake    # SDK基本設定
│       ├── device.cmake      # デバイスライブラリ
│       ├── board.cmake       # ボードライブラリ
│       ├── interface.cmake   # インターフェースライブラリ
│       ├── prebuilt_libs.cmake  # プリビルトライブラリ
│       ├── linker.cmake      # リンカー設定
│       ├── image.cmake       # イメージ生成
│       └── flash.cmake       # 書き込み設定
├── scripts/
│   ├── download_toolchain.sh    # ツールチェーンダウンロード (Linux/macOS)
│   └── download_toolchain.ps1   # ツールチェーンダウンロード (Windows)
├── external/
│   └── sdk/                  # Seeed Grove Vision AI Module V2 サブモジュール
├── toolchain/                # ダウンロードされたツールチェーン
└── .venv/                    # Python仮想環境
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
