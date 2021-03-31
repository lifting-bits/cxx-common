set(LLVM_VERSION "12.0.0-rc2")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 d8f9b3dfeb0fe9b91eb7f49da393784333044db2653373fbb168afd3c8d50f3e3ec7a7b8f44df522d0facafbfe4cfc4d9e2906d19f1e6feb0bdc569b6c10a17d
    HEAD_REF main
    PATCHES
        0001-fix-install-paths.patch
        0002-fix-openmp-debug.patch
        0003-fix-dr-1734.patch
        0004-fix-tools-path.patch
        0005-remove-FindZ3.cmake.patch
        0006-fix-FindZ3.cmake.patch
        0007-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
