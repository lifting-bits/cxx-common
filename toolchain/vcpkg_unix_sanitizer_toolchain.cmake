# This toolchain only sets up override compiler flags for CMake's 'Release' and
# 'Debug' build types. You _must_ set your sanitizer flag(s)
# ('-fsanitize=address') in the vcpkg triplet. These flags aren't globally
# applied because some programs like LLVM don't play nice with global
# sanitizers and have their own buildsystem options to enable compilation with
# those flags.
get_property(_CMAKE_IN_TRY_COMPILE GLOBAL PROPERTY IN_TRY_COMPILE)
if(NOT _CMAKE_IN_TRY_COMPILE)
  # Our override flags for sanitization, but does not include sanitizer flags,
  # that comes from vcpkg flags
  set(common_flags "-O1 -g -fno-omit-frame-pointer -fno-optimize-sibling-calls")

  # Copied from vcpkg's 'scripts/toolchain/linux.cmake'. Don't use the `_INIT`
  # suffix because we want to _override_ any flags that CMake would use
  set(CMAKE_C_FLAGS " -fPIC ${common_flags} ${VCPKG_C_FLAGS} ")
  set(CMAKE_CXX_FLAGS " -fPIC ${common_flags} ${VCPKG_CXX_FLAGS} ")
  set(CMAKE_C_FLAGS_DEBUG " ${VCPKG_C_FLAGS_DEBUG} ")
  set(CMAKE_CXX_FLAGS_DEBUG " ${VCPKG_CXX_FLAGS_DEBUG} ")
  set(CMAKE_C_FLAGS_RELEASE " -DNDEBUG ${VCPKG_C_FLAGS_RELEASE} ")
  set(CMAKE_CXX_FLAGS_RELEASE " -DNDEBUG ${VCPKG_CXX_FLAGS_RELEASE} ")

  set(CMAKE_SHARED_LINKER_FLAGS " ${VCPKG_LINKER_FLAGS} ")
  set(CMAKE_EXE_LINKER_FLAGS " ${VCPKG_LINKER_FLAGS} ")
  if(VCPKG_CRT_LINKAGE STREQUAL "static")
    string(APPEND CMAKE_SHARED_LINKER_FLAGS "-static ")
    string(APPEND CMAKE_EXE_LINKER_FLAGS APPEND "-static ")
  endif()
  set(CMAKE_SHARED_LINKER_FLAGS_DEBUG " ${VCPKG_LINKER_FLAGS_DEBUG} ")
  set(CMAKE_EXE_LINKER_FLAGS_DEBUG " ${VCPKG_LINKER_FLAGS_DEBUG} ")
  set(CMAKE_SHARED_LINKER_FLAGS_RELEASE " ${VCPKG_LINKER_FLAGS_RELEASE} ")
  set(CMAKE_EXE_LINKER_FLAGS_RELEASE " ${VCPKG_LINKER_FLAGS_RELEASE} ")
endif()
