#!/bin/bash
# Setup Python virtual environment for Grove Vision AI V2
# This script creates a venv and installs required packages for flashing

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="${PROJECT_DIR}/.venv"
REQUIREMENTS_FILE="${PROJECT_DIR}/external/Seeed_Grove_Vision_AI_Module_V2/xmodem/requirements.txt"

echo "=== Grove Vision AI V2 - Python Environment Setup ==="
echo "Project directory: ${PROJECT_DIR}"
echo "Virtual environment: ${VENV_DIR}"

# Check Python3
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 is required but not found" >&2
    exit 1
fi

PYTHON_VERSION=$(python3 --version)
echo "Python version: ${PYTHON_VERSION}"

# Check if submodule is initialized
if [ ! -f "${REQUIREMENTS_FILE}" ]; then
    echo ""
    echo "Error: requirements.txt not found at ${REQUIREMENTS_FILE}" >&2
    echo "Please ensure git submodules are initialized:" >&2
    echo "  git submodule update --init --recursive" >&2
    exit 1
fi

# Create virtual environment
if [ -d "${VENV_DIR}" ]; then
    echo ""
    echo "Virtual environment already exists at ${VENV_DIR}"
    read -p "Do you want to recreate it? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing existing virtual environment..."
        rm -rf "${VENV_DIR}"
    else
        echo "Using existing virtual environment"
    fi
fi

if [ ! -d "${VENV_DIR}" ]; then
    echo ""
    echo "Creating virtual environment..."
    python3 -m venv "${VENV_DIR}"
fi

# Activate virtual environment
echo ""
echo "Activating virtual environment..."
source "${VENV_DIR}/bin/activate"

# Upgrade pip
echo ""
echo "Upgrading pip..."
pip install --upgrade pip

# Install requirements
echo ""
echo "Installing requirements..."
pip install -r "${REQUIREMENTS_FILE}"

# Install additional useful packages
echo ""
echo "Installing additional packages..."
pip install pyserial-asyncio  # Useful for async serial operations

echo ""
echo "=== Setup Complete ==="
echo ""
echo "To activate the virtual environment:"
echo "  source ${VENV_DIR}/bin/activate"
echo ""
echo "To flash firmware to device:"
echo "  python ${PROJECT_DIR}/external/Seeed_Grove_Vision_AI_Module_V2/xmodem/xmodem_send.py \\"
echo "    --port=/dev/ttyACM0 \\"
echo "    --baudrate=921600 \\"
echo "    --protocol=xmodem \\"
echo "    --file=${PROJECT_DIR}/output/firmware.img"
echo ""
echo "Or use CMake target:"
echo "  cmake --build build --target flash -- -DGROVE_SERIAL_PORT=/dev/ttyACM0"
