set(LLVM_VERSION "9.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 2ad844f2d85d6734178a4ad746975a03ea9cda1454f7ea436f0ef8cc3199edec15130e322b4372b28a3178a8033af72d0a907662706cbd282ef57359235225a5
    HEAD_REF master
    PATCHES
        0001-add-msvc-options.patch
        0002-fix-install-paths.patch
        0003-openmp-debug.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0006-workaround-msvc-bug.patch
        0007-remove-FindZ3.cmake.patch
        0008-fix-FindZ3.cmake.patch
        0009-clang-sys-include-dir-path.patch
        0020-fix-vs2019-v16.6.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
