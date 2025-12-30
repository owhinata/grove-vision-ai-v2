# ARM Cortex-M55 Toolchain File for Grove Vision AI V2
# Cross-compilation toolchain for bare-metal ARM

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

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

# Set compilers directly (required for cross-compilation)
set(CMAKE_C_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-gcc" CACHE FILEPATH "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-g++" CACHE FILEPATH "C++ compiler" FORCE)
set(CMAKE_ASM_COMPILER "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-gcc" CACHE FILEPATH "ASM compiler" FORCE)
set(CMAKE_AR "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-ar" CACHE FILEPATH "Archiver" FORCE)
set(CMAKE_OBJCOPY "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-objcopy" CACHE FILEPATH "Objcopy" FORCE)
set(CMAKE_OBJDUMP "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-objdump" CACHE FILEPATH "Objdump" FORCE)
set(CMAKE_SIZE "${ARM_TOOLCHAIN_PATH}/arm-none-eabi-size" CACHE FILEPATH "Size" FORCE)

# Cortex-M55 specific flags with FPU support
# The prebuilt SDK libraries use hard float ABI, so we must match
set(CPU_FLAGS "-mthumb -mcpu=cortex-m55 -mfloat-abi=hard")

# Common compile flags
set(COMMON_FLAGS "${CPU_FLAGS} -ffunction-sections -fdata-sections -Wall -fstack-usage")

# C flags
set(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS} -std=gnu11")
set(CMAKE_C_FLAGS_DEBUG_INIT "-g -DDEBUG")
set(CMAKE_C_FLAGS_RELEASE_INIT "-DNDEBUG")

# C++ flags
set(CMAKE_CXX_FLAGS_INIT "${COMMON_FLAGS} -std=c++17 -fno-rtti -fno-exceptions -fno-threadsafe-statics")
set(CMAKE_CXX_FLAGS_DEBUG_INIT "-g -DDEBUG")
set(CMAKE_CXX_FLAGS_RELEASE_INIT "-DNDEBUG")

# ASM flags
set(CMAKE_ASM_FLAGS_INIT "${COMMON_FLAGS} -x assembler-with-cpp")

# Linker flags
set(CMAKE_EXE_LINKER_FLAGS_INIT "${CPU_FLAGS} -Wl,--gc-sections -Wl,--sort-section=alignment --specs=nosys.specs")

# Don't try to run test executables on host
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Search paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
