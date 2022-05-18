vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/gap
  REF 11989486fa95db0f66fb339fad485f5b6cb725c2
  SHA512 acce919437fbb0fc7aed346514aafcd1772468a23838f2208494403edaf7afbb02396d5546ce18cb50b955b1d24569f2b83e3f8e5b8a6413e54985f3273e537d
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
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/gap)

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" )

file(
  INSTALL "${SOURCE_PATH}/LICENSE"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright
)

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage")
  file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}" RENAME usage)
endif()
