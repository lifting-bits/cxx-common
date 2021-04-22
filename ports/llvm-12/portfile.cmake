set(LLVM_VERSION "12.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 0cff02155c5ac0d6db2b72d60d9819d5b5dd859663b45f721b1c7540239c2fceb1f57d9173f6870c49de851c242ed8e85c5c6d6577a1f8092a7c5dcd12513b26
    HEAD_REF main
    PATCHES
        0001-fix-install-paths.patch
        0002-fix-openmp-debug.patch
        0003-fix-dr-1734.patch
        0004-fix-tools-path.patch
        0005-fix-compiler-rt-install-path.patch
        0006-fix-libcxx-install.patch
        0007-fix-tools-install-path.patch
        0020-remove-FindZ3.cmake.patch
        0021-fix-FindZ3.cmake.patch
        0022-llvm-config-bin-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
