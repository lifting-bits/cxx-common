#NOTE(Artem): Modified not to fail on arm64
vcpkg_fail_port_install(ON_TARGET "UWP")

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO Z3Prover/z3
  REF feadfbfba4642cd81d36c30cb901f605c48712ad # z3-4.8.13
  SHA512 22c1ef42c2bddc50507f914c2eefd2caa0ee961ef1c216c9724a9c7e6da3927bcaaf70b6e1a44428e0e27b57f1d20854347ced6500dcdc042763e0ef2762d377
  HEAD_REF master
  PATCHES
         fix-install-path.patch
         fix-cmake-flags.patch
)

if (VCPKG_LIBRARY_LINKAGE STREQUAL "static")
  set(BUILD_STATIC "-DZ3_BUILD_LIBZ3_SHARED=OFF")
endif()

vcpkg_configure_cmake(
  SOURCE_PATH ${SOURCE_PATH}
  PREFER_NINJA
  OPTIONS
    ${BUILD_STATIC}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/z3 TARGET_PATH share/Z3)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)

file(INSTALL ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
