# Grove Vision AI V2 - CMake Build System

CMake build system for Seeed Grove Vision AI Module V2.

[日本語版はこちら](README_ja.md)

## Requirements

- CMake 3.16 or later
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

- Install [CMake](https://cmake.org/download/)
- Install [Python](https://www.python.org/downloads/)
- Install Git for Windows

## Quick Start

### 1. Clone Repository

```bash
git clone --recursive https://github.com/yourusername/grove-vision-ai-v2.git
cd grove-vision-ai-v2
```

### 2. Build

```bash
# Configure build directory
cmake -B build -S apps/hello_world

# Build firmware (.img is auto-generated)
cmake --build build
```

On first run, the following are automatically set up:
- Git submodule initialization
- ARM toolchain download
- Python virtual environment creation

### 3. Flash to Device

```bash
cmake --build build --target flash
```

Default serial port is `/dev/ttyACM0`. To change:

```bash
cmake -B build -S apps/hello_world -DGROVE_SERIAL_PORT=/dev/ttyUSB0
cmake --build build --target flash
```

## Available Applications

| Application | Description |
|-------------|-------------|
| `hello_world` | Basic hello world example |
| `hello_world_freertos` | FreeRTOS hello world example |
| `hello_world_cmsis_dsp` | CMSIS-DSP hello world example |
| `hello_world_cmsis_cv` | CMSIS-CV (Helium) computer vision example |
| `allon_sensor_tflm` | Camera sensor with TensorFlow Lite Micro |
| `allon_sensor_tflm_freertos` | Camera sensor with TFLM and FreeRTOS |
| `allon_sensor_tflm_fatfs` | Camera sensor with TFLM and FatFS (SD card) |
| `allon_sensor_tflm_cmsis_nn` | Camera sensor with TFLM and CMSIS-NN |
| `allon_jpeg_encode` | JPEG encoding with SPI output |
| `tflm_yolo11_od` | YOLO11 object detection with model flash |
| `tflm_yolov8_pose` | YOLOv8 pose estimation with model flash |

### Building an Application

```bash
cmake -B build -S apps/<app_name>
cmake --build build
cmake --build build --target flash
```

### Applications with Model Flash Support

`tflm_yolo11_od` and `tflm_yolov8_pose` require model flashing:

```bash
# Flash firmware and model together
cmake --build build --target flash

# Flash model only
cmake --build build --target flash-model
```

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `GROVE_SERIAL_PORT` | `/dev/ttyACM0` | Serial port for flashing |
| `GROVE_SERIAL_BAUDRATE` | `921600` | Serial baudrate |
| `CIS_SENSOR_MODEL` | (app dependent) | Camera sensor model |
| `SDK_TFLM_VERSION` | (app dependent) | TFLM library version |
| `SDK_TFLM_FORCE_PREBUILT` | `OFF` | Use prebuilt TFLM library |
| `SDK_CMSIS_NN_FORCE_PREBUILT` | `OFF` | Use prebuilt CMSIS-NN library |

### Camera Sensor Options

```bash
cmake -B build -S apps/allon_sensor_tflm -DCIS_SENSOR_MODEL=cis_ov5647
```

Available sensors: `cis_hm0360`, `cis_ov5647`, `cis_imx219`, `cis_imx477`, `cis_imx708`

### TFLM Version Options

```bash
cmake -B build -S apps/allon_sensor_tflm -DSDK_TFLM_VERSION=tflmtag2209_u55tag2205
```

Available versions:
- `tflmtag2209_u55tag2205` - Sep 2022 TFLM + May 2022 U55
- `tflmtag2212_u55tag2205` - Dec 2022 TFLM + May 2022 U55
- `tflmtag2412_u55tag2411` - Dec 2024 TFLM + Nov 2024 U55 (latest)

## Build Targets

| Target | Description |
|--------|-------------|
| `all` | Build firmware (.elf, .bin, .img) |
| `flash` | Flash firmware to device |
| `flash-model` | Flash model only (YOLO apps) |

## Directory Structure

```
grove-vision-ai-v2/
├── README.md
├── README_ja.md
├── apps/
│   ├── hello_world/              # Basic example
│   ├── hello_world_freertos/     # FreeRTOS example
│   ├── hello_world_cmsis_dsp/    # CMSIS-DSP example
│   ├── hello_world_cmsis_cv/     # CMSIS-CV example
│   ├── allon_sensor_tflm/        # Camera + TFLM
│   ├── allon_sensor_tflm_freertos/  # Camera + TFLM + FreeRTOS
│   ├── allon_sensor_tflm_fatfs/  # Camera + TFLM + FatFS
│   ├── allon_sensor_tflm_cmsis_nn/  # Camera + TFLM + CMSIS-NN
│   ├── allon_jpeg_encode/        # JPEG encoding
│   ├── tflm_yolo11_od/           # YOLO11 object detection
│   └── tflm_yolov8_pose/         # YOLOv8 pose estimation
├── cmake/
│   ├── setup.cmake               # Development environment setup
│   ├── arm-none-eabi-gcc.cmake   # Toolchain file
│   └── sdk/
│       ├── device.cmake          # Device library
│       ├── board.cmake           # Board library
│       ├── interface.cmake       # Interface library
│       ├── common.cmake          # Common library
│       ├── trustzone.cmake       # TrustZone configuration
│       ├── library.cmake         # SDK libraries
│       ├── tflm.cmake            # TensorFlow Lite Micro
│       ├── cmsis_nn.cmake        # CMSIS-NN library
│       ├── cmsis_dsp.cmake       # CMSIS-DSP library
│       ├── cmsis_cv.cmake        # CMSIS-CV library
│       ├── freertos.cmake        # FreeRTOS support
│       ├── fatfs.cmake           # FatFS support
│       ├── event_handler.cmake   # Event handler
│       ├── linker.cmake          # Linker settings
│       ├── image.cmake           # Image generation
│       └── flash.cmake           # Flash settings
├── scripts/
│   ├── download_toolchain.sh     # Toolchain download (Linux/macOS)
│   └── download_toolchain.ps1    # Toolchain download (Windows)
├── external/
│   └── sdk/                      # Seeed SDK submodule
├── toolchain/                    # Downloaded toolchain
└── .venv/                        # Python virtual environment
```

## Creating a New Application

Use `apps/hello_world/` as a template:

```bash
cp -r apps/hello_world apps/my_app
```

Edit `apps/my_app/CMakeLists.txt` to change the `project()` name and build:

```bash
cmake -B build -S apps/my_app
cmake --build build
```

## Troubleshooting

### Submodule Not Found

CMake auto-initializes, but for manual initialization:

```bash
git submodule update --init --recursive
```

### Toolchain Not Found

CMake auto-downloads, but for manual download:

```bash
./scripts/download_toolchain.sh
```

### Python Package Installation Error

```bash
# Recreate virtual environment
rm -rf .venv
cmake -B build -S apps/hello_world  # Auto-recreates
```

### Serial Port Permission Error (Linux)

```bash
sudo usermod -a -G dialout $USER
# Logout and login again
```

## License

The build system of this project is provided under the MIT License.
The Seeed Grove Vision AI Module V2 source code follows the original repository's license.
