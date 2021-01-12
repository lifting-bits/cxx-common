set(LLVM_VERSION "9.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 2ad844f2d85d6734178a4ad746975a03ea9cda1454f7ea436f0ef8cc3199edec15130e322b4372b28a3178a8033af72d0a907662706cbd282ef57359235225a5
    HEAD_REF master
    PATCHES
        0001-allow-to-use-commas.patch
        0002-fix-install-paths.patch
        0004-fix-dr-1734.patch
        0005-remove-FindZ3.cmake.patch
        0006-fix-FindZ3.cmake.patch
)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    tools LLVM_BUILD_TOOLS
    tools LLVM_INCLUDE_TOOLS
    utils LLVM_BUILD_UTILS
    utils LLVM_INCLUDE_UTILS
    enable-rtti LLVM_ENABLE_RTTI
    enable-z3 LLVM_ENABLE_Z3_SOLVER
)

# Linking with gold is better than /bin/ld
# Linking with lld is better than gold
# MacOS just has LLD, so only set explicit linker on Linux
if(VCPKG_TARGET_IS_LINUX)
    # Use lld when building with clang
    if (CMAKE_CXX_COMPILER_ID MATCHES "Clang")
      list(APPEND FEATURE_OPTIONS
          -DLLVM_USE_LINKER=lld
      )
    # Use GNU Gold when building with not clang (likely, g++)
    else()
      list(APPEND FEATURE_OPTIONS
          -DLLVM_USE_LINKER=gold
      )
    endif()
endif()

# By default assertions are enabled for Debug configuration only.
if("enable-assertions" IN_LIST FEATURES)
    # Force enable assertions for all configurations.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ENABLE_ASSERTIONS=ON
    )
elseif("disable-assertions" IN_LIST FEATURES)
    # Force disable assertions for all configurations.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ENABLE_ASSERTIONS=OFF
    )
endif()

if("enable-terminfo" IN_LIST FEATURES)
    # Force enable terminfo for all configurations.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ENABLE_TERMINFO=ON
    )
elseif("disable-terminfo" IN_LIST FEATURES)
    # Force disable terminfo for all configurations.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ENABLE_TERMINFO=OFF
    )
endif()

# LLVM_ABI_BREAKING_CHECKS can be WITH_ASSERTS (default), FORCE_ON or FORCE_OFF.
# By default abi-breaking checks are enabled if assertions are enabled.
if("enable-abi-breaking-checks" IN_LIST FEATURES)
    # Force enable abi-breaking checks.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ABI_BREAKING_CHECKS=FORCE_ON
    )
elseif("disable-abi-breaking-checks" IN_LIST FEATURES)
    # Force disable abi-breaking checks.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ABI_BREAKING_CHECKS=FORCE_OFF
    )
endif()

set(LLVM_ENABLE_PROJECTS)
if("clang" IN_LIST FEATURES OR "clang-tools-extra" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "clang")
    if("disable-clang-static-analyzer" IN_LIST FEATURES)
        list(APPEND FEATURE_OPTIONS
            # Disable ARCMT
            -DCLANG_ENABLE_ARCMT=OFF
            # Disable static analyzer
            -DCLANG_ENABLE_STATIC_ANALYZER=OFF
        )
    endif()
    if(VCPKG_TARGET_IS_WINDOWS)
        list(APPEND FEATURE_OPTIONS
            # Disable dl library on Windows
            -DDL_LIBRARY_PATH:FILEPATH=
        )
    elseif(VCPKG_TARGET_IS_OSX)
        list(APPEND FEATURE_OPTIONS
            -DDEFAULT_SYSROOT:FILEPATH=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk
            -DLLVM_CREATE_XCODE_TOOLCHAIN=ON
        )
    endif()
endif()
if("clang-tools-extra" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "clang-tools-extra")
endif()
if("compiler-rt" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "compiler-rt")
endif()
if("libcxx" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "libcxx")
    list(APPEND FEATURE_OPTIONS
        -DLIBCXX_ENABLE_STATIC=YES
        -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=YES
        -DLIBCXX_ENABLE_FILESYSTEM=YES
        -DLIBCXX_INCLUDE_BENCHMARKS=NO
    )
    if(VCPKG_TARGET_IS_LINUX)
        list(APPEND FEATURE_OPTIONS
            # Broken on Linux when set to YES
            # Error on installing shared debug lib
            -DLIBCXX_ENABLE_SHARED=NO
            )
    else()
        list(APPEND FEATURE_OPTIONS
            -DLIBCXX_ENABLE_SHARED=YES
            )
    endif()
endif()
if("libcxxabi" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "libcxxabi")
endif()
if("lld" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lld")
endif()
if("openmp" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "openmp")
    # Perl is required for the OpenMP run-time
    vcpkg_find_acquire_program(PERL)
    list(APPEND FEATURE_OPTIONS
        -DPERL_EXECUTABLE=${PERL}
    )
endif()
if("lldb" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lldb")
endif()
if("polly" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "polly")
endif()

set(known_llvm_targets
    AArch64 AMDGPU ARM BPF Hexagon Lanai Mips
    MSP430 NVPTX PowerPC RISCV Sparc SystemZ
    WebAssembly X86 XCore)

set(LLVM_TARGETS_TO_BUILD "")
foreach(llvm_target IN LISTS known_llvm_targets)
    string(TOLOWER "target-${llvm_target}" feature_name)
    if(feature_name IN_LIST FEATURES)
        list(APPEND LLVM_TARGETS_TO_BUILD "${llvm_target}")
    endif()
endforeach()

# Use comma-separated string instead of semicolon-separated string.
# See https://github.com/microsoft/vcpkg/issues/4320
string(REPLACE ";" "," LLVM_ENABLE_PROJECTS "${LLVM_ENABLE_PROJECTS}")
string(REPLACE ";" "," LLVM_TARGETS_TO_BUILD "${LLVM_TARGETS_TO_BUILD}")

vcpkg_find_acquire_program(PYTHON3)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/llvm
    PREFER_NINJA
    OPTIONS
        ${FEATURE_OPTIONS}
        -DLLVM_INCLUDE_EXAMPLES=OFF
        -DLLVM_BUILD_EXAMPLES=OFF
        -DLLVM_INCLUDE_TESTS=OFF
        -DLLVM_BUILD_TESTS=OFF
        # Disable optional dependencies to libxml2, zlib, and libedit
        -DLLVM_ENABLE_LIBXML2=OFF
        -DLLVM_ENABLE_ZLIB=OFF
        -DLLVM_ENABLE_LIBEDIT=OFF
        # From llvm-9 onwards
        -DCMAKE_CXX_STANDARD=14
        # Force TableGen to be built with optimization. This will significantly improve build time.
        -DLLVM_OPTIMIZED_TABLEGEN=ON
        # LLVM generates CMake error due to Visual Studio version 16.4 is known to miscompile part of LLVM.
        # LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON disables this error.
        # See https://developercommunity.visualstudio.com/content/problem/845933/miscompile-boolean-condition-deduced-to-be-always.html
        -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON
        -DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS}
        -DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}
        -DPACKAGE_VERSION=${LLVM_VERSION}
        -DPYTHON_EXECUTABLE=${PYTHON3}
        # Limit the maximum number of concurrent link jobs to 2. This should fix low amount of memory issue for link.
        -DLLVM_PARALLEL_LINK_JOBS=2
        # Disable build LLVM-C.dll (Windows only) due to doesn't compile with CMAKE_DEBUG_POSTFIX
        -DLLVM_BUILD_LLVM_C_DYLIB=OFF
        -DCMAKE_DEBUG_POSTFIX=d
)

vcpkg_install_cmake()
vcpkg_fixup_cmake_targets(CONFIG_PATH share/llvm TARGET_PATH share/llvm)
if("clang" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH share/clang TARGET_PATH share/clang)
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "release")
    file(GLOB_RECURSE _llvm_release_targets
        "${CURRENT_PACKAGES_DIR}/share/llvm/*-release.cmake"
    )
    set(_clang_release_targets)
    if("clang" IN_LIST FEATURES)
        file(GLOB_RECURSE _clang_release_targets
            "${CURRENT_PACKAGES_DIR}/share/clang/*-release.cmake"
        )
    endif()
    foreach(_target IN LISTS _llvm_release_targets _clang_release_targets)
        file(READ ${_target} _contents)
        # LLVM tools should be located in the bin folder because llvm-config expects to be inside a bin dir.
        # Rename `/tools/${PORT}` to `/bin` back because there is no way to avoid this in vcpkg_fixup_cmake_targets.
        string(REPLACE "{_IMPORT_PREFIX}/tools/${PORT}" "{_IMPORT_PREFIX}/bin" _contents "${_contents}")
        file(WRITE ${_target} "${_contents}")
    endforeach()
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(GLOB_RECURSE _llvm_debug_targets
        "${CURRENT_PACKAGES_DIR}/share/llvm/*-debug.cmake"
    )
    set(_clang_debug_targets)
    if("clang" IN_LIST FEATURES)
        file(GLOB_RECURSE _clang_debug_targets
            "${CURRENT_PACKAGES_DIR}/share/clang/*-debug.cmake"
        )
    endif()
    foreach(_target IN LISTS _llvm_debug_targets _clang_debug_targets)
        file(READ ${_target} _contents)
        # LLVM tools should be located in the bin folder because llvm-config expects to be inside a bin dir.
        # Rename `/tools/${PORT}` to `/bin` back because there is no way to avoid this in vcpkg_fixup_cmake_targets.
        string(REPLACE "{_IMPORT_PREFIX}/tools/${PORT}" "{_IMPORT_PREFIX}/bin" _contents "${_contents}")
        # Debug shared libraries should have `d` suffix and should be installed in the `/bin` directory.
        # Rename `/debug/bin/` to `/bin`
        string(REPLACE "{_IMPORT_PREFIX}/debug/bin/" "{_IMPORT_PREFIX}/bin/" _contents "${_contents}")
        file(WRITE ${_target} "${_contents}")
    endforeach()

    # Install debug shared libraries in the `/bin` directory
    file(GLOB _debug_shared_libs ${CURRENT_PACKAGES_DIR}/debug/bin/*${CMAKE_SHARED_LIBRARY_SUFFIX})
    file(INSTALL ${_debug_shared_libs} DESTINATION ${CURRENT_PACKAGES_DIR}/bin)

    file(REMOVE_RECURSE
        ${CURRENT_PACKAGES_DIR}/debug/bin
        ${CURRENT_PACKAGES_DIR}/debug/include
        ${CURRENT_PACKAGES_DIR}/debug/share
    )
endif()

# Handle copyright
file(INSTALL ${SOURCE_PATH}/llvm/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/llvm RENAME copyright)
if("clang" IN_LIST FEATURES)
    file(INSTALL ${SOURCE_PATH}/clang/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/clang RENAME copyright)
endif()

# Don't fail if the bin folder exists.
set(VCPKG_POLICY_EMPTY_PACKAGE enabled)
