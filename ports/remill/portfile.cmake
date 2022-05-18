vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO lifting-bits/remill
  REF 3de75e999299c6b7a071febfd1e74271c7004adc
  SHA512 d2d9aa1762ac2c866b2788c842afabf25ce91bb6bc92870b74362fb0e698a49f8949625026e185d4b7d161b2eee051e4f7ed19a6e023139239829d6266f7a0aa
  HEAD_REF vcpkg-manifest
)

vcpkg_configure_cmake(
  SOURCE_PATH "${SOURCE_PATH}"
  PREFER_NINJA
)

vcpkg_install_cmake()
vcpkg_cmake_config_fixup()

file( REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include" )

file(
  INSTALL "${SOURCE_PATH}/LICENSE"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
  RENAME copyright
)

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage")
  file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}" RENAME usage)
endif()
