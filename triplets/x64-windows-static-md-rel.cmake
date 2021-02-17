# Modified from upstream's triplet of a similar name to only build Release
# build-types

set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

# Keep commented since a blank VCPKG_CMAKE_SYSTEM_NAME is default Windows but 
# setting explicitly to "Windows" is wrong.
# https://github.com/microsoft/vcpkg/blob/3f7b6777560cc9006aa43b3c4587e4d95bac7c40/scripts/cmake/vcpkg_common_definitions.cmake#L30
# set(VCPKG_CMAKE_SYSTEM_NAME Windows)

set(VCPKG_BUILD_TYPE release)
