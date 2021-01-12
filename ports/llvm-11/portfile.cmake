set(LLVM_VERSION "11.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 b6d38871ccce0e086e27d35e42887618d68e57d8274735c59e3eabc42dee352412489296293f8d5169fe0044936345915ee7da61ebdc64ec10f7737f6ecd90f2
    HEAD_REF master
    PATCHES
        0001-add-msvc-options.patch
        0002-fix-install-paths.patch
        0003-fix-openmp-debug.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0006-workaround-msvc-bug.patch
        0007-remove-FindZ3.cmake.patch
        0008-fix-FindZ3.cmake.patch
        0009-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
