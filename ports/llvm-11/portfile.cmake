set(LLVM_VERSION "11.0.1")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 f5e6ef0b3111aae08a89cd01adb2ff4abfa9ef779c68b9190421d0447efd25c2cc00e5aae9f4764805f5fa31434866043d1510ae7389817e28ae53a5442e2fdf
    HEAD_REF main
    PATCHES
        0001-add-msvc-options.patch
        0002-fix-install-paths.patch
        0003-fix-openmp-debug.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0006-workaround-msvc-bug.patch
        0007-fix-compiler-rt-install-path.patch
        0008-fix-libcxx-install.patch
        0009-fix-tools-install-path.patch
        0020-remove-FindZ3.cmake.patch
        0021-fix-FindZ3.cmake.patch
        0022-llvm-config-bin-path.patch
        0023-fix-macos-libcxx-header-handling.patch
        0024-vcpkg-fix-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
