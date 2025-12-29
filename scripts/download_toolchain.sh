#!/bin/bash
# ARM GNU Toolchain download script for Linux and macOS
# Supports ARM GNU Toolchain 13.2.rel1

set -e

TOOLCHAIN_VERSION="13.2.rel1"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$(dirname "$0")/../toolchain}"
TOOLCHAIN_DIR=$(cd "$(dirname "$0")" && cd .. && pwd)/toolchain

# Detect OS and architecture
detect_platform() {
    local os=$(uname -s)
    local arch=$(uname -m)

    case "$os" in
        Linux)
            case "$arch" in
                x86_64)
                    echo "x86_64-linux"
                    ;;
                aarch64)
                    echo "aarch64-linux"
                    ;;
                *)
                    echo "Unsupported Linux architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                x86_64)
                    echo "darwin-x86_64"
                    ;;
                arm64)
                    echo "darwin-arm64"
                    ;;
                *)
                    echo "Unsupported macOS architecture: $arch" >&2
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported OS: $os" >&2
            exit 1
            ;;
    esac
}

# Get download URL based on platform
get_download_url() {
    local platform=$1
    local base_url="https://developer.arm.com/-/media/Files/downloads/gnu/${TOOLCHAIN_VERSION}/binrel"

    case "$platform" in
        x86_64-linux)
            echo "${base_url}/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz"
            ;;
        aarch64-linux)
            echo "${base_url}/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-aarch64-arm-none-eabi.tar.xz"
            ;;
        darwin-x86_64)
            echo "${base_url}/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-x86_64-arm-none-eabi.tar.xz"
            ;;
        darwin-arm64)
            echo "${base_url}/arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-arm64-arm-none-eabi.tar.xz"
            ;;
    esac
}

# Get expected directory name after extraction
get_toolchain_name() {
    local platform=$1

    case "$platform" in
        x86_64-linux)
            echo "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-x86_64-arm-none-eabi"
            ;;
        aarch64-linux)
            echo "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-aarch64-arm-none-eabi"
            ;;
        darwin-x86_64)
            echo "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-x86_64-arm-none-eabi"
            ;;
        darwin-arm64)
            echo "arm-gnu-toolchain-${TOOLCHAIN_VERSION}-darwin-arm64-arm-none-eabi"
            ;;
    esac
}

main() {
    echo "=== ARM GNU Toolchain Downloader ==="
    echo "Version: ${TOOLCHAIN_VERSION}"

    local platform=$(detect_platform)
    echo "Detected platform: ${platform}"

    local url=$(get_download_url "$platform")
    local toolchain_name=$(get_toolchain_name "$platform")
    local archive_name="${toolchain_name}.tar.xz"

    echo "Download URL: ${url}"
    echo "Install directory: ${TOOLCHAIN_DIR}"

    # Create toolchain directory
    mkdir -p "${TOOLCHAIN_DIR}"
    cd "${TOOLCHAIN_DIR}"

    # Check if already installed
    if [ -d "${toolchain_name}" ]; then
        echo "Toolchain already installed at: ${TOOLCHAIN_DIR}/${toolchain_name}"
        echo "To reinstall, delete the directory and run this script again."
        echo ""
        echo "Add to PATH:"
        echo "  export PATH=\"${TOOLCHAIN_DIR}/${toolchain_name}/bin:\$PATH\""
        exit 0
    fi

    # Download
    echo ""
    echo "Downloading toolchain..."
    if command -v curl &> /dev/null; then
        curl -L -o "${archive_name}" "${url}"
    elif command -v wget &> /dev/null; then
        wget -O "${archive_name}" "${url}"
    else
        echo "Error: curl or wget is required" >&2
        exit 1
    fi

    # Extract
    echo ""
    echo "Extracting toolchain..."
    tar -xJf "${archive_name}"

    # Cleanup
    rm -f "${archive_name}"

    # Verify installation
    if [ -x "${toolchain_name}/bin/arm-none-eabi-gcc" ]; then
        echo ""
        echo "=== Installation Complete ==="
        echo "Toolchain installed at: ${TOOLCHAIN_DIR}/${toolchain_name}"
        echo ""
        echo "Add the following to your shell profile (.bashrc, .zshrc, etc.):"
        echo "  export PATH=\"${TOOLCHAIN_DIR}/${toolchain_name}/bin:\$PATH\""
        echo ""
        echo "Or set GNU_TOOLPATH in your environment:"
        echo "  export GNU_TOOLPATH=\"${TOOLCHAIN_DIR}/${toolchain_name}/bin\""

        # Verify version
        echo ""
        echo "Installed GCC version:"
        "${toolchain_name}/bin/arm-none-eabi-gcc" --version | head -1
    else
        echo "Error: Installation verification failed" >&2
        exit 1
    fi
}

main "$@"
