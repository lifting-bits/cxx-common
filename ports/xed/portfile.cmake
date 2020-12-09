vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO intelxed/xed
    REF afbb851b5f2f2ac6cdb6e6d9bebbaf2d4e77286d
    SHA512 fe80db93d7734e318184a4fcf9737f4bc6a7169bce3e52fa59c95eaa27ba77027127964c557fcafee6b0fd490b860ee0bca6d790efa23d1a7b1b709f0c3b77ed
    HEAD_REF master
)

vcpkg_from_github(
    OUT_SOURCE_PATH MBUILD_SOURCE_PATH
    REPO intelxed/mbuild
    REF 03ee9d52adb7f01d476ced0dba1534cfc7edff36
    SHA512 8080944b3833d249828c7e86c52d997dc54779b7d236620b892affe7c364152f45d38a1434e788257a42b5ef0f324aa46a713492bf9af14c2147c34c4fdb5684
    HEAD_REF master
)

# Copy mbuild sources.
message(STATUS "Copying mbuild to parallel source directory...")
file(COPY ${MBUILD_SOURCE_PATH}/ DESTINATION ${SOURCE_PATH}/../mbuild)
message(STATUS "Copied mbuild")

set(LINK_TYPE shared)
if (VCPKG_LIBRARY_LINKAGE STREQUAL static)
  set(LINK_TYPE static)
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
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR} --build-dir "${CURRENT_BUILDTREES_DIR}/${RELEASE_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_C_FLAGS_RELEASE}" "--extra-cxxflags=${VCPKG_CXX_FLAGS_RELEASE}" "--extra-linkflags=${VCPKG_LINKER_FLAGS_RELEASE}" --verbose=9
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
    COMMAND ${PYTHON3} ${SOURCE_PATH}/mfile.py install --debug --${LINK_TYPE} --install-dir ${CURRENT_PACKAGES_DIR}/debug --build-dir "${CURRENT_BUILDTREES_DIR}/${DEBUG_TRIPLET}" -j ${VCPKG_CONCURRENCY} "--extra-ccflags=${VCPKG_C_FLAGS_DEBUG}" "--extra-cxxflags=${VCPKG_CXX_FLAGS_DEBUG}" "--extra-linkflags=${VCPKG_LINKER_FLAGS_DEBUG}" --verbose=9
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

FILE(INSTALL ${CMAKE_CURRENT_LIST_DIR}/XEDConfig.cmake DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
file(INSTALL ${MBUILD_SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME mbuild.copyright)
