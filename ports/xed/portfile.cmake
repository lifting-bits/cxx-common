vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO intelxed/xed
    REF 5976632eeaaaad7890c2109d0cfaf4012eaca3b8 # 12.0.1
    SHA512 9463e669cc273f55829e82d6032763221c2ba73f3c43191be847f694f6fd3609b866cc14101e8b1f88e7e44f04b4f5f7bf61bb9431b72b7e17ded1db34b7757d
    HEAD_REF master
    PATCHES 
      dont_call_evex_scan_when_error.patch
)

# Last checked Dec 9, 2020
# Commit from Dec 2, 2020
vcpkg_from_github(
    OUT_SOURCE_PATH MBUILD_SOURCE_PATH
    REPO intelxed/mbuild
    REF 3e8eb33aada4153c21c4261b35e5f51f6e2019e8
    SHA512 ed3a705204a5f9526473280fdb64820aeec23b2da850dc3c78b83e6ccc7cd72961990fab0a0188c249d967b59f3d2cb00f6dcd3f9cceb7c30aa13e378e26ccd5
    HEAD_REF master
)

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
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR} --build-dir "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_C_FLAGS} ${VCPKG_C_FLAGS_RELEASE} ${EXTRA_C_FLAGS_RELEASE}" "--extra-cxxflags=${VCPKG_CXX_FLAGS} ${VCPKG_CXX_FLAGS_RELEASE} ${EXTRA_CXX_FLAGS_RELEASE}" "--extra-linkflags=${VCPKG_LINKER_FLAGS} ${VCPKG_LINKER_FLAGS_RELEASE}" --verbose=9
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
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --debug --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR}/debug --build-dir "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_C_FLAGS} ${VCPKG_C_FLAGS_DEBUG} ${EXTRA_C_FLAGS_DEBUG}" "--extra-cxxflags=${VCPKG_CXX_FLAGS} ${VCPKG_CXX_FLAGS_DEBUG} ${EXTRA_CXX_FLAGS_DEBUG}" "--extra-linkflags=${VCPKG_LINKER_FLAGS} ${VCPKG_LINKER_FLAGS_DEBUG}" --verbose=9
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
