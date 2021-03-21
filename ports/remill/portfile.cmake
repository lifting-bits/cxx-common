vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/remill
    # Latest commit after v4.0.22 at this time
    REF 021b799efc07a38d5f910bb41bdb7e60e4406f23
    SHA512 10a33d785be69bda54f08ab9f89ccfd9e71bab632d90541eef2ce1122b1161b690cfb5068ee4ae036152a5ebefe8d53dde7f8bb5f99310f678365e9962a417ff
    HEAD_REF master
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
