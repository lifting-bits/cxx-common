vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO intelxed/xed
    REF v2023.04.16
    SHA512 fbba729427debe4c670af502a2e58f2e388d44216aa001333dcc3a5703346b7da475bf9027fb1c17f5404dc9ef687e40168387749f87cacbdd80460ba6e13cd9
    HEAD_REF main
)

vcpkg_from_github(
    OUT_SOURCE_PATH MBUILD_SOURCE_PATH
    REPO intelxed/mbuild
    REF v2022.07.28
    SHA512 3f7b4337a101f9c31735184aa81f521c18ddb571f8d8504cfab09733b8cd01ff0c3a286bfec0e09d0527d9e1ad518ff7444bf2eb29e068587da72320bd6ffe3a
    HEAD_REF main
    PATCHES
        # For arm cross compilation
        0001-mbuild-remove-m64.patch
)

# Xed has its own compiler detection, and will readily guess wrong.
# Help it out by finding the correct compiler
z_vcpkg_get_cmake_vars(cmake_vars_file)
include("${cmake_vars_file}")
message(STATUS "Detected CXX compiler: ${VCPKG_DETECTED_CMAKE_CXX_COMPILER}")
message(STATUS "Detected C compiler: ${VCPKG_DETECTED_CMAKE_C_COMPILER}")

# Copy mbuild sources.
message(STATUS "Copying mbuild to parallel source directory...")
file(COPY ${MBUILD_SOURCE_PATH}/ DESTINATION ${SOURCE_PATH}/../mbuild)
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

  # Not entirely sure if we actually repeat any of the build work if we do
  # separate build and install phases, so just combine them for now
  message(STATUS "Building and installing ${RELEASE_TRIPLET}")
  file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET})
  file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET})
  vcpkg_execute_required_process(
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --no-werror "--cc=${VCPKG_DETECTED_CMAKE_C_COMPILER}" "--cxx=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}" --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR} --build-dir "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_DETECTED_CMAKE_C_FLAGS} ${VCPKG_DETECTED_CMAKE_C_FLAGS_RELEASE} ${EXTRA_C_FLAGS_RELEASE}" "--extra-cxxflags=${VCPKG_DETECTED_CMAKE_CXX_FLAGS} ${VCPKG_DETECTED_CMAKE_CXX_FLAGS_RELEASE} ${EXTRA_CXX_FLAGS_RELEASE}" "--extra-linkflags=${VCPKG_DETECTED_CMAKE_LINKER_FLAGS} ${VCPKG_DETECTED_CMAKE_LINKER_FLAGS_RELEASE}" --verbose=9
    WORKING_DIRECTORY ${SOURCE_PATH}
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

  # Not entirely sure if we actually repeat any of the build work if we do
  # separate build and install phases, so just combine them for now
  message(STATUS "Building and installing ${DEBUG_TRIPLET}")
  file(REMOVE_RECURSE ${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET})
  file(MAKE_DIRECTORY ${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET})
  vcpkg_execute_required_process(
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --no-werror "--cc=${VCPKG_DETECTED_CMAKE_C_COMPILER}" "--cxx=${VCPKG_DETECTED_CMAKE_CXX_COMPILER}" --debug --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR}/debug --build-dir "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_DETECTED_CMAKE_C_FLAGS} ${VCPKG_DETECTED_CMAKE_C_FLAGS_DEBUG} ${EXTRA_C_FLAGS_DEBUG}" "--extra-cxxflags=${VCPKG_DETECTED_CMAKE_CXX_FLAGS} ${VCPKG_DETECTED_CMAKE_CXX_FLAGS_DEBUG} ${EXTRA_CXX_FLAGS_DEBUG}" "--extra-linkflags=${VCPKG_DETECTED_CMAKE_LINKER_FLAGS} ${VCPKG_DETECTED_CMAKE_LINKER_FLAGS_DEBUG}" --verbose=9
    WORKING_DIRECTORY ${SOURCE_PATH}
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

file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/XEDConfig.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL ${CMAKE_CURRENT_LIST_DIR}/usage DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
file(INSTALL ${MBUILD_SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME mbuild.copyright)
