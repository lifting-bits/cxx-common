vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO ekilmer/remill
    REF abebf20a29456ed2f5229277b575ca4d6859b0b6
    SHA512 d23a653bbbb2a9d0a36eb8425651154df0bd3339f8286d9e7449b128b6ae045c0aaefc864613910c2cda548d395b1f3c926bbb9b7b58e46657aa6572fa8179f3
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
