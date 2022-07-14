vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/gap
  REF 62954efaf660991ee489394f238ffa1ae82f5f72
  SHA512 75148940a9c9888085533176eb29e4a4efa1859bf8a18316c7ae8dc4a7b1918c1077d30662db51e2abe1fd1f4ae3e6369060dafbdcd01e06655efd48db95f155
  HEAD_REF main
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  OPTIONS
    -DGAP_ENABLE_COROUTINES=ON
    -DGAP_ENABLE_TESTING=OFF
    -DGAP_ENABLE_EXAMPLES=OFF
    -DGAP_INSTALL=ON
    -DUSE_SYSTEM_DEPENDENCIES=ON
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(
  PACKAGE_NAME "gap"
  CONFIG_PATH lib/cmake/gap
)

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug" )

# we do not populate lib folder yet
file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib" )

file(
  INSTALL "${SOURCE_PATH}/LICENSE"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright
)

if ( EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage" )
  file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}"
    RENAME usage
  )
endif()