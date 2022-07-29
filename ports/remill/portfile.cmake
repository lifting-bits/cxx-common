vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/remill
  REF e7c0e3f9f7f482b6bcc336cd98b8afd4129c6e3b
  SHA512 49ee8db4dbf097e89046f3fce3de85ea35703d329f44b3388af992664760044aa8a9e7d0dac1c71e914b0fe0293f5ec10cc8ef4de5e5a118a492b6b2581b9b8c
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
