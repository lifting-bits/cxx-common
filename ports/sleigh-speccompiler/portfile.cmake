# NOTE: A large part of this file is the same as sleigh port
set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

set(ghidra_version "10.2.2")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/sleigh
    REF "v${ghidra_version}"
    SHA512 40a75cf4c57a751c45c5401881646aae94c22d5c047b86647372240a81abb79870275a4ba8874d0bd3c1d5aec7d13141abfa091893abecdeeb77d33a579390ad
    HEAD_REF master
)

vcpkg_from_github(
    OUT_SOURCE_PATH GHIDRA_SOURCE_PATH
    REPO NationalSecurityAgency/ghidra
    REF "Ghidra_${ghidra_version}_build"
    SHA512 443cc6a3b5883c612d81883399dc32147245a4a7b501d4ddd1a559874e22d6ff074530d011f1994892a9f2c05eed02304f2accc61b017d7f01d1bf75c57aea0a
    HEAD_REF master
)

# Apply sleigh project's patches to ghidra
z_vcpkg_apply_patches(
    SOURCE_PATH "${GHIDRA_SOURCE_PATH}"
    PATCHES
        "${SOURCE_PATH}/src/patches/stable/0001-Small-improvements-to-C-decompiler-testing-from-CLI.patch"
        "${SOURCE_PATH}/src/patches/stable/0002-Add-include-guards-to-decompiler-C-headers.patch"
        "${SOURCE_PATH}/src/patches/stable/0003-Fix-UBSAN-errors-in-decompiler.patch"
        "${SOURCE_PATH}/src/patches/stable/0004-Use-stroull-instead-of-stroul-to-parse-address-offse.patch"
)

set(VCPKG_BUILD_TYPE release) # we only need release here!
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/tools/spec-compiler"
    OPTIONS
        "-DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=${GHIDRA_SOURCE_PATH}"
)
vcpkg_cmake_install()
vcpkg_copy_tools(
    TOOL_NAMES sleigh
    DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}"
    AUTO_CLEAN
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-port-config.cmake"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
