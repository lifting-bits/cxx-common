vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/remill
    REF v4.0.13
    SHA512 b7d491d6f93efc6639077163b7ffa2452b09d5383f6fdc6fff4b774217e9f7d446759e21223ddf327431b02889eba54165a096838540e08fd2399d67556f85d4
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
