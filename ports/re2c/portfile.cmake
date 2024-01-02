vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO skvadrik/re2c
    REF 3.1
    SHA512 7528d78e1354c774783e63e05553b7a772f8185b43b988cddf79a527ed63316f18e6f9fb3a63ae4d5c83c9f4de2b672b0e61898d96bdd6f15a1eaa7b4d47c757
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

vcpkg_fixup_pkgconfig()
