#NOTE(Artem): Modified not to fail on arm64
vcpkg_fail_port_install(ON_TARGET "UWP")

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR "${PYTHON3}" DIRECTORY)
vcpkg_add_to_path("${PYTHON3_DIR}")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO Z3Prover/z3
  REF 3a402ca2c14c3891d24658318406f80ce59b719f # z3-4.8.12
  SHA512 1db5a840239bdce5141286cb13944fd755c16b0681560934b9f9f98121cdc1224db49dab130eeaf2ee160fba5de660edd0a3d0ac2a8ae6a32de2c88e8388ae2d
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
