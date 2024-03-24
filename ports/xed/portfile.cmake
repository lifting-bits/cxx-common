vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO intelxed/xed
    REF v2023.12.19
    SHA512 a19865fac9d287b8599bd6b990a8faa1b2f39b4f0057b9d8828e1b8c200013e6794a8f3e7bf3592d59277c4c4f7c2a85aa7e9e62ff3546e43bd1855aa8678bf4
    HEAD_REF main
)

# Use latest commit from when xed is last released
vcpkg_from_github(
    OUT_SOURCE_PATH MBUILD_SOURCE_PATH
    REPO intelxed/mbuild
    REF c07bd90b71c608c615a7fa643d373f11ba355a24
    SHA512 753dcbf1546733ff621ca87244622cae0294ae535476b1fcd334cff35d1d61004b6d5d1508c7c1e9594a34d1333d183fd90fdd2a2cdb7309b67e4a49c5d3e278
    HEAD_REF main
    PATCHES
        # For arm cross compilation
        0001-mbuild-remove-m64.patch
)

# Xed has its own compiler detection, and will easily guess wrong.
# Help it out by finding the correct compiler, linker, archiver
z_vcpkg_get_cmake_vars(cmake_vars_file)
include("${cmake_vars_file}")
message(STATUS "Detected CXX compiler: ${VCPKG_DETECTED_CMAKE_CXX_COMPILER}")
message(STATUS "Detected C compiler: ${VCPKG_DETECTED_CMAKE_C_COMPILER}")

# Copy mbuild sources.
message(STATUS "Copying mbuild to parallel source directory...")
file(COPY "${MBUILD_SOURCE_PATH}/" DESTINATION "${SOURCE_PATH}/../mbuild")
message(STATUS "Copied mbuild")

set(EXTRA_CXX_FLAGS_RELEASE "")
set(EXTRA_C_FLAGS_RELEASE "")
set(EXTRA_CXX_FLAGS_DEBUG "")
set(EXTRA_C_FLAGS_DEBUG "")

set(LINK_TYPE shared)
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
  set(LINK_TYPE static)
  # Windows static library and dynamic crt linkage
  if (NOT VCPKG_CMAKE_SYSTEM_NAME AND VCPKG_CRT_LINKAGE STREQUAL dynamic)
    set(EXTRA_CXX_FLAGS_RELEASE "${EXTRA_CXX_FLAGS_RELEASE} /MD")
    set(EXTRA_C_FLAGS_RELEASE "${EXTRA_C_FLAGS_RELEASE} /MD")
    set(EXTRA_CXX_FLAGS_DEBUG "${EXTRA_CXX_FLAGS_DEBUG} /MDd")
    set(EXTRA_C_FLAGS_DEBUG "${EXTRA_C_FLAGS_DEBUG} /MDd")
  endif()
endif()

set(RELEASE_TRIPLET ${TARGET_TRIPLET}-rel)
set(DEBUG_TRIPLET ${TARGET_TRIPLET}-dbg)

# Build
vcpkg_find_acquire_program(PYTHON3)
if (NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL release)
  # Not sure if separate build and install phases repeat any of the build work,
  # so just combine them for now
  message(STATUS "Building and installing ${RELEASE_TRIPLET}")
  file(REMOVE_RECURSE "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}")
  file(MAKE_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}")
  vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "${SOURCE_PATH}/mfile.py" install
      --install-dir "${CURRENT_PACKAGES_DIR}"
      --build-dir "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}"
      "--extra-ccflags=${VCPKG_DETECTED_CMAKE_C_FLAGS} ${VCPKG_DETECTED_CMAKE_C_FLAGS_RELEASE} ${EXTRA_C_FLAGS_RELEASE}"
      "--extra-cxxflags=${VCPKG_DETECTED_CMAKE_CXX_FLAGS} ${VCPKG_DETECTED_CMAKE_CXX_FLAGS_RELEASE} ${EXTRA_CXX_FLAGS_RELEASE}"
      "--extra-linkflags=${VCPKG_DETECTED_CMAKE_LINKER_FLAGS} ${VCPKG_DETECTED_CMAKE_LINKER_FLAGS_RELEASE}"
      # All other options should be the same for release
      "--cc=${VCPKG_DETECTED_CMAKE_C_COMPILER}"
      "--cxx=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}"
      "--linker=${VCPKG_DETECTED_CMAKE_LINKER}"
      "--ar=${VCPKG_DETECTED_CMAKE_AR}"
      "--as=${VCPKG_DETECTED_CMAKE_AS}"
      --${LINK_TYPE}
      -j ${VCPKG_CONCURRENCY}
      --verbose=9
      --no-werror
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME python-${TARGET_TRIPLET}-build-install-rel
  )

  # Cleanup
  file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin"
                      "${CURRENT_PACKAGES_DIR}/extlib"
                      "${CURRENT_PACKAGES_DIR}/doc"
                      "${CURRENT_PACKAGES_DIR}/examples"
                      "${CURRENT_PACKAGES_DIR}/mbuild"
                      )
endif()

if (NOT VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL debug)
  # Not sure if separate build and install phases repeat any of the build work,
  # so just combine them for now
  message(STATUS "Building and installing ${DEBUG_TRIPLET}")
  file(REMOVE_RECURSE "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}")
  file(MAKE_DIRECTORY "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}")
  vcpkg_execute_required_process(
    COMMAND "${PYTHON3}" "${SOURCE_PATH}/mfile.py" install
      --debug
      --install-dir "${CURRENT_PACKAGES_DIR}/debug"
      --build-dir "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}"
      "--extra-ccflags=${VCPKG_DETECTED_CMAKE_C_FLAGS} ${VCPKG_DETECTED_CMAKE_C_FLAGS_DEBUG} ${EXTRA_C_FLAGS_DEBUG}"
      "--extra-cxxflags=${VCPKG_DETECTED_CMAKE_CXX_FLAGS} ${VCPKG_DETECTED_CMAKE_CXX_FLAGS_DEBUG} ${EXTRA_CXX_FLAGS_DEBUG}"
      "--extra-linkflags=${VCPKG_DETECTED_CMAKE_LINKER_FLAGS} ${VCPKG_DETECTED_CMAKE_LINKER_FLAGS_DEBUG}"
      # All other options should be the same for release
      "--cc=${VCPKG_DETECTED_CMAKE_C_COMPILER}"
      "--cxx=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}"
      "--linker=${VCPKG_DETECTED_CMAKE_LINKER}"
      "--ar=${VCPKG_DETECTED_CMAKE_AR}"
      "--as=${VCPKG_DETECTED_CMAKE_AS}"
      --${LINK_TYPE}
      -j ${VCPKG_CONCURRENCY}
      --no-werror
      --verbose=9
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME python-${TARGET_TRIPLET}-build-install-dbg
  )

  # Cleanup
  file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin"
                      "${CURRENT_PACKAGES_DIR}/debug/include"
                      "${CURRENT_PACKAGES_DIR}/debug/extlib"
                      "${CURRENT_PACKAGES_DIR}/debug/doc"
                      "${CURRENT_PACKAGES_DIR}/debug/examples"
                      "${CURRENT_PACKAGES_DIR}/debug/mbuild"
                      )
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/XEDConfig.cmake" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
file(INSTALL "${SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
file(INSTALL "${MBUILD_SOURCE_PATH}/LICENSE" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME mbuild.copyright)
