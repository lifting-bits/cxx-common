# NOTE: A large part of this file is the same as sleigh-speccompiler port
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

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
FEATURES
    "specs"     sleigh_BUILD_SLEIGHSPECS  # compiled sla files
    "support"   sleigh_BUILD_SUPPORT      # support libraries
)

vcpkg_find_acquire_program(GIT)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        ${FEATURE_OPTIONS}
        "-DGIT_EXECUTABLE=${GIT}"
        "-DSLEIGH_EXECUTABLE=${SLEIGH_SPECCOMPILER}"
        "-DFETCHCONTENT_SOURCE_DIR_GHIDRASOURCE=${GHIDRA_SOURCE_PATH}"
        -Dsleigh_BUILD_TOOLS=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/sleigh)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
if(VCPKG_LIBRARY_LINKAGE STREQUAL "static" OR NOT VCPKG_TARGET_IS_WINDOWS)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin")
endif()

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
