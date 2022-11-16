set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)

set(ghidra_version "10.2.1")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO lifting-bits/sleigh
    REF v10.2.1
    SHA512 6d35717ffbbf8793e312d5da65cfbf5e74bb7d4b9ca4fc89a6cb8799fc239871ae73a92dc2b0edbc259aba5cad22b6fb199655ff0062f8b5a2d87a27d35e8eaf
    HEAD_REF master
)

vcpkg_find_acquire_program(GIT)

set(VCPKG_BUILD_TYPE release) #we only need release here!
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/tools/spec-compiler"
    OPTIONS
        "-DGIT_EXECUTABLE=${GIT}"
)
vcpkg_cmake_install()
vcpkg_copy_tools(
    TOOL_NAMES sleigh
    DESTINATION "${CURRENT_PACKAGES_DIR}/tools/sleigh"
    AUTO_CLEAN
)

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
