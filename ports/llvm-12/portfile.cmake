set(LLVM_VERSION "12.0.1")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 6eb0dc18e2c25935fabfdfc48b0114be0939158dfdef7b85b395fe2e71042672446af0e68750aae003c9847d10d1f63316fe95d3df738d18f249174292b1b9e1
    HEAD_REF main
    PATCHES
        0002-fix-install-paths.patch
        0003-fix-openmp-debug.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0007-fix-compiler-rt-install-path.patch
        0008-fix-libcxx-install.patch
        0009-fix-tools-install-path.patch
        0010-fix-libffi.patch
        0011-fix-libxml2.patch
        0020-remove-FindZ3.cmake.patch
        0021-fix-FindZ3.cmake.patch
        0022-llvm-config-bin-path.patch
        0023-clang-sys-include-dir-path.patch
        0024-install-clang-tblgen.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
