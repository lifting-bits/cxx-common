set(LLVM_VERSION "10.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 baa182d62fef1851836013ae8a1a00861ea89769778d67fb97b407a9de664e6c85da2af9c5b3f75d2bf34ff6b00004e531ca7e4b3115a26c0e61c575cf2303a0
    HEAD_REF master
    PATCHES
        0001-add-msvc-options.patch
        0002-fix-install-paths.patch
        0003-fix-openmp-debug.patch
        0003-fix-vs2019-v16.6.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0005-remove-FindZ3.cmake.patch
        0006-fix-FindZ3.cmake.patch
        0006-workaround-msvc-bug.patch
        0009-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
