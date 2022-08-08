vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/remill
  REF 6752679638d04400e26b91efb9c5641b93d4df52
  SHA512 b4c7ba1edb04c23d13ec62d5ec02c620dcc32c93efaf2b1dbd2a2865db55d3e77a7f275e195710d23cc79fb44d43e2c5184f1845c70de3376b78f1303aaaa144
  HEAD_REF vcpkg-manifest
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DUSE_SYSTEM_DEPENDENCIES=ON
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(
  PACKAGE_NAME "remill"
  CONFIG_PATH lib/cmake/remill
)

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" )
file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share" )

if ( VCPKG_LIBRARY_LINKAGE STREQUAL "static" )
  file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin" "${CURRENT_PACKAGES_DIR}/debug/bin" )
endif()

file(
  INSTALL "${SOURCE_PATH}/LICENSE"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright
)

file(
  INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
)
