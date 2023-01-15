vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO Z3Prover/z3
  REF z3-4.12.0
  SHA512 53a51c8304fa4356d13293f68b14d9d9eef57a0771c6698d38aea5fac62c4e52c41ff003cb6d771a32645d2aa4ef59be5f792f2efbee927d06ac8280094976e5
  HEAD_REF master
  PATCHES
      fix-install-path.patch
      remove-flag-overrides.patch
)

if (VCPKG_LIBRARY_LINKAGE STREQUAL "static")
  set(BUILD_STATIC "-DZ3_BUILD_LIBZ3_SHARED=OFF")
endif()

vcpkg_cmake_configure(
  SOURCE_PATH ${SOURCE_PATH}
  OPTIONS
    ${BUILD_STATIC}
    -DZ3_BUILD_TEST_EXECUTABLES=OFF
    -DZ3_ENABLE_EXAMPLE_TARGETS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/z3)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${SOURCE_PATH}/LICENSE.txt" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

vcpkg_fixup_pkgconfig()
