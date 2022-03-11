set(LLVM_VERSION "13.0.1")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 9a8cb5d11964ba88b7624f19ec861fb28701f23956ea3c92f6ac644332d5f41fde97bd8933dd3ee70ed378058c252fa3a3887c8d1af90d219970c2b27691166f
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
        0024-remove-elf_relocation-checks.patch
)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")
