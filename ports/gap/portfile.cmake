vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/gap
  REF 971ac626e49e5508f6b488661120bd8cacbc0e72
  SHA512 fe8422f0d7c695eca4f17b1252bdfa22fa612312dda570754ae3def4acaa61b65ee6ff9eb3de8758b051535164fee6b6f94135dfc061db628b8816d29bb856e4
  HEAD_REF main
)

vcpkg_configure_cmake(
  SOURCE_PATH "${SOURCE_PATH}"
  PREFER_NINJA
  OPTIONS
    -DGAP_ENABLE_COROUTINES=OFF
    -DGAP_INSTALL=ON
)

vcpkg_install_cmake()
vcpkg_cmake_config_fixup(
  PACKAGE_NAME "gap"
  CONFIG_PATH lib/cmake
)

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" )
file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share" )

file(
  INSTALL "${SOURCE_PATH}/LICENSE"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright
)

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage")
  file(
    INSTALL "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}"
    RENAME usage
  )
endif()
