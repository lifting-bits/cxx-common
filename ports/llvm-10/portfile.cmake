set(LLVM_VERSION "10.0.1")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 48078fff9293a87f1a973f3348f79506f04c3da774295f5eb67d74dd2d1aa94f0973f8ced3f4ab9e8339902071f82c603b43d5608ad7227046c4da769c5d2151
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
        0023-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
