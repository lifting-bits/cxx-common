vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/remill
  REF 36b1901eacb1564f62c8fe9205b59825a03e3ae2
  SHA512 0c8d5bd8bd291adb9ea369574fee7a8a3629e12030270da77f541d1d8b531ce1305d061616c582ec734ee8ee7ba917ab0e3a1e688204aab4b486360fb5adb814
  HEAD_REF vcpkg-manifest-llvm-16
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
