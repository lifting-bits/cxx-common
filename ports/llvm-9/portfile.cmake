set(LLVM_VERSION "9.0.1")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 fa88beeaae94b6d0cd9b5ba38658d0ffed8004035d7d8a4f95c3d31a709b88b581ae9bd7761333c8e5375c44b8f6be01768b5a3be901163159d7e6c43b71da59
    HEAD_REF master
    PATCHES
        0001-add-msvc-options.patch
        0002-fix-install-paths.patch
        0003-openmp-debug.patch
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
        0024-fix-vs2019-v16.6.patch
        0025-compiler-rt-glibc-2.31.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
