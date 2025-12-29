# ARM GNU Toolchain download script for Windows
# Supports ARM GNU Toolchain 13.2.rel1

param(
    [string]$ToolchainDir = ""
)

$ErrorActionPreference = "Stop"

$TOOLCHAIN_VERSION = "13.2.rel1"

if ($ToolchainDir -eq "") {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ToolchainDir = Join-Path (Split-Path -Parent $ScriptDir) "toolchain"
}

function Get-DownloadUrl {
    $baseUrl = "https://developer.arm.com/-/media/Files/downloads/gnu/$TOOLCHAIN_VERSION/binrel"
    return "$baseUrl/arm-gnu-toolchain-$TOOLCHAIN_VERSION-mingw-w64-i686-arm-none-eabi.zip"
}

function Get-ToolchainName {
    return "arm-gnu-toolchain-$TOOLCHAIN_VERSION-mingw-w64-i686-arm-none-eabi"
}

function Main {
    Write-Host "=== ARM GNU Toolchain Downloader ===" -ForegroundColor Cyan
    Write-Host "Version: $TOOLCHAIN_VERSION"
    Write-Host "Platform: Windows"

    $url = Get-DownloadUrl
    $toolchainName = Get-ToolchainName
    $archiveName = "$toolchainName.zip"

    Write-Host "Download URL: $url"
    Write-Host "Install directory: $ToolchainDir"

    # Create toolchain directory
    if (-not (Test-Path $ToolchainDir)) {
        New-Item -ItemType Directory -Path $ToolchainDir -Force | Out-Null
    }

    $toolchainPath = Join-Path $ToolchainDir $toolchainName

    # Check if already installed
    if (Test-Path $toolchainPath) {
        Write-Host ""
        Write-Host "Toolchain already installed at: $toolchainPath" -ForegroundColor Green
        Write-Host "To reinstall, delete the directory and run this script again."
        Write-Host ""
        Write-Host "Add to PATH (PowerShell):"
        Write-Host "  `$env:PATH = `"$toolchainPath\bin;`$env:PATH`""
        return
    }

    $archivePath = Join-Path $ToolchainDir $archiveName

    # Download
    Write-Host ""
    Write-Host "Downloading toolchain..."

    # Use TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try {
        Invoke-WebRequest -Uri $url -OutFile $archivePath -UseBasicParsing
    }
    catch {
        Write-Host "Error downloading toolchain: $_" -ForegroundColor Red
        exit 1
    }

    # Extract
    Write-Host ""
    Write-Host "Extracting toolchain..."

    try {
        Expand-Archive -Path $archivePath -DestinationPath $ToolchainDir -Force
    }
    catch {
        Write-Host "Error extracting toolchain: $_" -ForegroundColor Red
        exit 1
    }

    # Cleanup
    Remove-Item -Path $archivePath -Force

    # Verify installation
    $gccPath = Join-Path $toolchainPath "bin\arm-none-eabi-gcc.exe"

    if (Test-Path $gccPath) {
        Write-Host ""
        Write-Host "=== Installation Complete ===" -ForegroundColor Green
        Write-Host "Toolchain installed at: $toolchainPath"
        Write-Host ""
        Write-Host "Add to PATH (PowerShell):"
        Write-Host "  `$env:PATH = `"$toolchainPath\bin;`$env:PATH`""
        Write-Host ""
        Write-Host "Or add to system PATH permanently:"
        Write-Host "  [Environment]::SetEnvironmentVariable(`"PATH`", `"$toolchainPath\bin;`" + [Environment]::GetEnvironmentVariable(`"PATH`", `"User`"), `"User`")"
        Write-Host ""
        Write-Host "Or set GNU_TOOLPATH:"
        Write-Host "  `$env:GNU_TOOLPATH = `"$toolchainPath\bin`""

        # Verify version
        Write-Host ""
        Write-Host "Installed GCC version:"
        & $gccPath --version | Select-Object -First 1
    }
    else {
        Write-Host "Error: Installation verification failed" -ForegroundColor Red
        exit 1
    }
}

Main
