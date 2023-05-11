vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/glog
    # Latest commit as of May 11, 2023
    REF aca9a23c83838997f22b9f6e6f9b6fc98f8b4705
    SHA512 4b5761dca6ecbcb3e84e433999ba44e68de85571137d8a0db0b7dc6cff6df0580a23fd095746da8806dac0c1eb48134ae4f16cf2907325106bc20e7bd12693e2
    HEAD_REF master
    PATCHES
      fix_glog_CMAKE_MODULE_PATH.patch
      glog_disable_debug_postfix.patch
      fix_crosscompile_symbolize.patch
      fix_cplusplus_macro.patch
)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        unwind          WITH_UNWIND
        customprefix    WITH_CUSTOM_PREFIX
)
file(REMOVE "${SOURCE_PATH}/glog-modules.cmake.in")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTING=OFF
        ${FEATURE_OPTIONS}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/glog)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

vcpkg_copy_pdbs()
vcpkg_fixup_pkgconfig()

file(INSTALL "${SOURCE_PATH}/COPYING" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
