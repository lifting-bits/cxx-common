set(LLVM_VERSION "13.0.0-rc3")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 1401d5a4d6bb5c930d74b9cfbc8e792872f721aab7d7f0c819e2ba5cf47fb818d160c1f71784fba69827f3c9b7414aa91a585d2b813c1851b4799f9d62cebc46
    HEAD_REF main
    PATCHES
        0001-fix-install-paths.patch
        0002-fix-openmp-debug.patch
        0003-fix-dr-1734.patch
        0004-fix-tools-path.patch
        0005-fix-compiler-rt-install-path.patch
        0006-fix-tools-install-path.patch
        0020-remove-FindZ3.cmake.patch
        0021-fix-FindZ3.cmake.patch
        0022-llvm-config-bin-path.patch
        0023-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
