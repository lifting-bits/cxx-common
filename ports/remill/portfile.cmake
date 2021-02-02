vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/remill
    REF v4.0.15
    SHA512 cc67cac03b88a0a34e918945fde0d0df0c7c69fd0445281d4f4fd9d1c2648450c3fe91ef2cae3fdb513bd62e99f96aca94d0054d1e7815eed680f3c416486f1c
    HEAD_REF vcpkg
)

# Configure and Build
vcpkg_configure_cmake(
    SOURCE_PATH "${SOURCE_PATH}"
    PREFER_NINJA
    OPTIONS
        -DUSE_SYSTEM_DEPENDENCIES=ON
)

# Install
vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/${PORT})
vcpkg_copy_pdbs()

# Cleanup
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

# Don't fail if the bin folder exists.
set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
