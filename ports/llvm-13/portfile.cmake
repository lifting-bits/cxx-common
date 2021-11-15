set(LLVM_VERSION "13.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 8004c05d32b9720fb3391783621690c1df9bd1e97e72cbff9192ed88a84b0acd303b61432145fa917b5b5e548c8cee29b24ef8547dcc8677adf4816e7a8a0eb2
    HEAD_REF main
    PATCHES
        0002-fix-install-paths.patch
        0003-fix-openmp-debug.patch
        0004-fix-dr-1734.patch
        0005-fix-tools-path.patch
        0007-fix-compiler-rt-install-path.patch
        0009-fix-tools-install-path.patch
        0010-fix-libffi.patch
        0011-fix-libxml2.patch
        0020-remove-FindZ3.cmake.patch
        0021-fix-FindZ3.cmake.patch
        0022-llvm-config-bin-path.patch
        0023-clang-sys-include-dir-path.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
