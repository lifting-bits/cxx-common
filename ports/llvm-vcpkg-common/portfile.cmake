
file(COPY
    ${CMAKE_CURRENT_LIST_DIR}/llvm-common-build.cmake
    DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT}
)

set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
