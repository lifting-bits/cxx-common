set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# ASAN
# Make sure this value matches up with https://llvm.org/docs/CMake.html "LLVM_USE_SANITIZER"
set(VCPKG_USE_SANITIZER "Address")

# If the following flags cause errors during build, you might need to manually
# ignore the PORT and check VCPKG_USE_SANITIZER
set(VCPKG_CXX_FLAGS "-fsanitize=address")
set(VCPKG_C_FLAGS "-fsanitize=address")

# Always apply sanitizer to linker flags
set(VCPKG_LINKER_FLAGS "-fsanitize=address")

# This is where we override default CMake compiler/linker flags
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${CMAKE_CURRENT_LIST_DIR}/../toolchain/vcpkg_unix_sanitizer_toolchain.cmake")

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
