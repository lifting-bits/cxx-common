vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/remill
    REF v4.0.24
    SHA512 bd1cd52a45174a9f033a490277974fb303dfa8cc4823a51366e9afc31e57d73fb787da98af7efe22675095214a90d14d644714756b8808beec5eb2c648276f82
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
