vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO protocolbuffers/upb
    REF  e5c1583452e3b84f943d2caa338799f02a7e054c # 2021-10-06
    SHA512 982426c42850e62c734b12d5268385782699f4e0895082dd5b1abc451d8ba79cd2fbff4147696098b05df51f69c53b4dac1c79db8cbe864dbcec377c50e42f2e
    HEAD_REF master
    PATCHES
        add-cmake-install.patch
        fix-uwp.patch
        add-all-libs-target.patch
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/cmake
    PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets()
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share ${CURRENT_PACKAGES_DIR}/debug/include)

file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
