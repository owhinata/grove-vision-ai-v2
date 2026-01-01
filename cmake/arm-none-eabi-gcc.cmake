# ARM Cortex-M55 Toolchain File for Grove Vision AI V2
# Cross-compilation toolchain for bare-metal ARM

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Always generate compile_commands.json for IDE integration
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Determine project root (go up from cmake/ directory)
get_filename_component(TOOLCHAIN_FILE_DIR "${CMAKE_CURRENT_LIST_FILE}" DIRECTORY)
get_filename_component(PROJECT_ROOT "${TOOLCHAIN_FILE_DIR}/.." ABSOLUTE)

# Toolchain path (can be overridden via -DARM_TOOLCHAIN_PATH=...)
if(NOT DEFINED ARM_TOOLCHAIN_PATH)
    # Auto-detect based on platform
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
        execute_process(COMMAND uname -m OUTPUT_VARIABLE HOST_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(HOST_ARCH STREQUAL "aarch64")
            set(TOOLCHAIN_SUFFIX "aarch64")
        else()
            set(TOOLCHAIN_SUFFIX "x86_64")
        endif()
    elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        execute_process(COMMAND uname -m OUTPUT_VARIABLE HOST_ARCH OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(HOST_ARCH STREQUAL "arm64")
            set(TOOLCHAIN_SUFFIX "darwin-arm64")
        else()
            set(TOOLCHAIN_SUFFIX "darwin-x86_64")
        endif()
    else()
        set(TOOLCHAIN_SUFFIX "mingw-w64-i686")
    endif()
    set(ARM_TOOLCHAIN_PATH "${PROJECT_ROOT}/toolchain/arm-gnu-toolchain-13.2.Rel1-${TOOLCHAIN_SUFFIX}-arm-none-eabi/bin")
endif()

# Executable extension (Windows needs .exe)
if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows" OR MINGW)
    set(EXE_SUFFIX ".exe")
else()
    set(EXE_SUFFIX "")
endif()

# Set compilers directly (required for cross-compilation)
set(CMAKE_C_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-gcc${EXE_SUFFIX}" CACHE FILEPATH "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-g++${EXE_SUFFIX}" CACHE FILEPATH "C++ compiler" FORCE)
set(CMAKE_ASM_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-gcc${EXE_SUFFIX}" CACHE FILEPATH "ASM compiler" FORCE)
set(CMAKE_AR "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-ar${EXE_SUFFIX}" CACHE FILEPATH "Archiver" FORCE)
set(CMAKE_OBJCOPY "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-objcopy${EXE_SUFFIX}" CACHE FILEPATH "Objcopy" FORCE)
set(CMAKE_OBJDUMP "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-objdump${EXE_SUFFIX}" CACHE FILEPATH "Objdump" FORCE)
set(CMAKE_SIZE "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-size${EXE_SUFFIX}" CACHE FILEPATH "Size" FORCE)

# Cortex-M55 specific flags with FPU support
# The prebuilt SDK libraries use hard float ABI, so we must match
set(CPU_FLAGS "-mthumb -mcpu=cortex-m55 -mfloat-abi=hard")

# Common compile flags
# Note: -flax-vector-conversions is required for CMSIS-NN/TFLM MVE vector type compatibility
# Note: -specs=nano.specs enables newlib-nano for reduced code size
# Note: -O2 optimization level matches SDK build
set(COMMON_FLAGS "${CPU_FLAGS} -ffunction-sections -fdata-sections -Wall -fstack-usage -flax-vector-conversions -specs=nano.specs -O2")

# C flags
set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS} -std=gnu11")
set(CMAKE_C_FLAGS_DEBUG_INIT "-g")
set(CMAKE_C_FLAGS_RELEASE_INIT "")

# C++ flags
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS} -std=c++17 -fno-rtti -fno-exceptions -fno-threadsafe-statics")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "")

# ASM flags
set(CMAKE_ASM_FLAGS_INIT "${COMMON_FLAGS} -x assembler-with-cpp")

# Linker flags
# Note: -specs=nano.specs is already in compile flags (propagates to linker)
# Note: -Wl,--no-warn-rwx-segments suppresses RWX segment warnings on GCC 12+
# Note: -Wl,-print-memory-usage shows memory usage after linking
# Note: -Wl,--cref generates cross-reference table
set(CMAKE_EXE_LINKER_FLAGS_INIT "${CPU_FLAGS} -Wl,--gc-sections -Wl,--sort-section=alignment -Wl,--no-warn-rwx-segments -Wl,-print-memory-usage -Wl,--cref")

# Don't try to run test executables on host
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Search paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
