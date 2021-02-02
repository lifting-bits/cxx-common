vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/remill
    REF v4.0.15
    SHA512 82cf8bd75b5570113cc2c32aff515d2eadd2dff88fba0b8981f45e6b1007aa18331d7da629e81e23242b3e17d18381d2e74929a0e7da4b3607f7b441e5c7a1b2
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
