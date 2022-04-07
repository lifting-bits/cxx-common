set(LLVM_VERSION "14.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 eb5acf96b5e2c59bd07579f7ebe73018b0dd6e2f2d9a5a3c7986320e88febd837d1084b9e5313a2264310342193044629d228337cc76dd2b8527dc0a8bdda999
    HEAD_REF main
    PATCHES
    0002-fix-install-paths.patch    # This patch fixes paths in ClangConfig.cmake, LLVMConfig.cmake, LLDConfig.cmake etc.
    0004-fix-dr-1734.patch
    0005-fix-tools-path.patch
    0007-fix-compiler-rt-install-path.patch
    0009-fix-tools-install-path.patch
    0010-fix-libffi.patch
    0011-fix-install-bolt.patch
    0020-fix-FindZ3.cmake.patch
    0023-clang-sys-include-dir-path.patch
    0024-remove-elf_relocation-checks.patch)

include("${CURRENT_INSTALLED_DIR}/share/llvm-vcpkg-common/llvm-common-build.cmake")


