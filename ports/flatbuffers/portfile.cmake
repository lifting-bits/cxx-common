vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO google/flatbuffers
    REF 31bb0b9726b0fa4db252680e156abd44adbdf4f4  # 2021-10-06
    SHA512 12fde1c8ecc12dca5402a3272119213dffdbe247a7ae72dc36aa677f83cb28a58d9edb0f1f1630b8617d3767db28c13ee202cb7f02fbafe11277e9e3e2595b90
    HEAD_REF master
    PATCHES
        ignore_use_of_cmake_toolchain_file.patch
        no-werror.patch
        fix-uwp-build.patch
        windows-python.patch
        emscripten-nostdlib.patch
)

set(OPTIONS)
if(VCPKG_TARGET_IS_UWP OR VCPKG_TARGET_IS_IOS)
    list(APPEND OPTIONS -DFLATBUFFERS_BUILD_FLATC=OFF -DFLATBUFFERS_BUILD_FLATHASH=OFF)
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
        -DFLATBUFFERS_BUILD_TESTS=OFF
        -DFLATBUFFERS_BUILD_GRPCTEST=OFF
        ${OPTIONS}
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH lib/cmake/flatbuffers)

file(GLOB flatc_path ${CURRENT_PACKAGES_DIR}/bin/flatc*)
if(flatc_path)
    make_directory(${CURRENT_PACKAGES_DIR}/tools/flatbuffers)
    get_filename_component(flatc_executable ${flatc_path} NAME)
    file(
        RENAME
        ${flatc_path}
        ${CURRENT_PACKAGES_DIR}/tools/flatbuffers/${flatc_executable}
    )
    vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/flatbuffers)
endif()

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/bin ${CURRENT_PACKAGES_DIR}/debug/bin)

# Handle copyright
file(INSTALL ${SOURCE_PATH}/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
