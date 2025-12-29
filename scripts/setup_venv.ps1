# Setup Python virtual environment for Grove Vision AI V2
# This script creates a venv and installs required packages for flashing

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$VenvDir = Join-Path $ProjectDir ".venv"
$RequirementsFile = Join-Path $ProjectDir "external\Seeed_Grove_Vision_AI_Module_V2\xmodem\requirements.txt"

Write-Host "=== Grove Vision AI V2 - Python Environment Setup ===" -ForegroundColor Cyan
Write-Host "Project directory: $ProjectDir"
Write-Host "Virtual environment: $VenvDir"

# Check Python3
$pythonCmd = $null
foreach ($cmd in @("python3", "python")) {
    try {
        $version = & $cmd --version 2>&1
        if ($version -match "Python 3") {
            $pythonCmd = $cmd
            break
        }
    }
    catch {
        continue
    }
}

if (-not $pythonCmd) {
    Write-Host "Error: Python 3 is required but not found" -ForegroundColor Red
    exit 1
}

$pythonVersion = & $pythonCmd --version
Write-Host "Python version: $pythonVersion"

# Check if submodule is initialized
if (-not (Test-Path $RequirementsFile)) {
    Write-Host ""
    Write-Host "Error: requirements.txt not found at $RequirementsFile" -ForegroundColor Red
    Write-Host "Please ensure git submodules are initialized:"
    Write-Host "  git submodule update --init --recursive"
    exit 1
}

# Create virtual environment
if (Test-Path $VenvDir) {
    Write-Host ""
    Write-Host "Virtual environment already exists at $VenvDir"
    $response = Read-Host "Do you want to recreate it? [y/N]"
    if ($response -match "^[Yy]") {
        Write-Host "Removing existing virtual environment..."
        Remove-Item -Recurse -Force $VenvDir
    }
    else {
        Write-Host "Using existing virtual environment"
    }
}

if (-not (Test-Path $VenvDir)) {
    Write-Host ""
    Write-Host "Creating virtual environment..."
    & $pythonCmd -m venv $VenvDir
}

# Get Python executable path in venv
$VenvPython = Join-Path $VenvDir "Scripts\python.exe"
$VenvPip = Join-Path $VenvDir "Scripts\pip.exe"

# Upgrade pip
Write-Host ""
Write-Host "Upgrading pip..."
& $VenvPython -m pip install --upgrade pip

# Install requirements
Write-Host ""
Write-Host "Installing requirements..."
& $VenvPip install -r $RequirementsFile

# Install additional useful packages
Write-Host ""
Write-Host "Installing additional packages..."
& $VenvPip install pyserial-asyncio

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "To activate the virtual environment:"
Write-Host "  $VenvDir\Scripts\Activate.ps1"
Write-Host ""
Write-Host "To flash firmware to device:"
Write-Host "  python $ProjectDir\external\Seeed_Grove_Vision_AI_Module_V2\xmodem\xmodem_send.py ``"
Write-Host "    --port=COM3 ``"
Write-Host "    --baudrate=921600 ``"
Write-Host "    --protocol=xmodem ``"
Write-Host "    --file=$ProjectDir\output\firmware.img"
Write-Host ""
Write-Host "Or use CMake target:"
Write-Host "  cmake --build build --target flash -- -DGROVE_SERIAL_PORT=COM3"
