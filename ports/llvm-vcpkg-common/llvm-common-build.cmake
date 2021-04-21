string(REPLACE "." ";" VERSION_LIST ${LLVM_VERSION})
list(GET VERSION_LIST 0 LLVM_VERSION_MAJOR)
list(GET VERSION_LIST 1 LLVM_VERSION_MINOR)
list(GET VERSION_LIST 2 LLVM_VERSION_PATCH)

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools LLVM_BUILD_TOOLS
        tools LLVM_INCLUDE_TOOLS
        utils LLVM_BUILD_UTILS
        utils LLVM_INCLUDE_UTILS
        utils LLVM_INSTALL_UTILS
        enable-rtti LLVM_ENABLE_RTTI
        enable-z3 LLVM_ENABLE_Z3_SOLVER
        enable-eh LLVM_ENABLE_EH
)

# Linking with gold is better than /bin/ld
# Linking with lld is better than gold
# MacOS just has LLD, so only set explicit linker on Linux
if(VCPKG_TARGET_IS_LINUX)
    # NOTE(ekilmer): This should probably be a vcpkg utility function
    file(READ "${CURRENT_BUILDTREES_DIR}/../detect_compiler/config-${TARGET_TRIPLET}-rel-err.log" _compiler_info)
    string(REGEX MATCH "#COMPILER_CXX_ID#([^\r\n]*)" _ ${_compiler_info})
    set(VCPKG_DETECTED_CXX_COMPILER_ID ${CMAKE_MATCH_1})
    # ENDNOTE

    message(STATUS "Detected Compiler ID: '${VCPKG_DETECTED_CXX_COMPILER_ID}'")
    if (VCPKG_DETECTED_CXX_COMPILER_ID MATCHES "Clang")
        list(APPEND FEATURE_OPTIONS
          -DLLVM_USE_LINKER=lld
        )
        message(STATUS "Using lld for linking")
    # Use GNU Gold when building with not clang (likely, g++)
    else()
      list(APPEND FEATURE_OPTIONS
          -DLLVM_USE_LINKER=gold
      )
      message(STATUS "Using (default) gold linker for linking")
    endif()
endif()

# LLVM generates CMake error due to Visual Studio version 16.4 is known to miscompile part of LLVM.
# LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON disables this error.
# See https://developercommunity.visualstudio.com/content/problem/845933/miscompile-boolean-condition-deduced-to-be-always.html
# and thread "[llvm-dev] Longstanding failing tests - clang-tidy, MachO, Polly" on llvm-dev Jan 21-23 2020.
list(APPEND FEATURE_OPTIONS
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON
)

if(VCPKG_USE_SANITIZER)
    list(APPEND FEATURE_OPTIONS
        -DLLVM_USE_SANITIZER=${VCPKG_USE_SANITIZER}
        )
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
    # 1) LLVM/Clang tools are relocated from ./bin/ to ./tools/llvm/ (LLVM_TOOLS_INSTALL_DIR=tools/llvm)
    # 2) Clang resource files are relocated from ./lib/clang/<version> to ./tools/llvm/lib/clang/<version> (see patch 0007-fix-compiler-rt-install-path.patch)
    # So, the relative path should be changed from ../lib/clang/<version> to ./lib/clang/<version>
    list(APPEND FEATURE_OPTIONS -DCLANG_RESOURCE_DIR=lib/clang/${LLVM_VERSION})
endif()
if("clang-tools-extra" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "clang-tools-extra")
endif()
if("compiler-rt" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "compiler-rt")
endif()
if("flang" IN_LIST FEATURES)
    # Disable Flang on Windows (see http://lists.llvm.org/pipermail/flang-dev/2020-July/000448.html).
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building Flang with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "flang")
    list(APPEND FEATURE_OPTIONS
        # Flang requires C++17
        -DCMAKE_CXX_STANDARD=17
    )
endif()
if("libclc" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "libclc")
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
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building libcxx with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "libcxx")
endif()
if("libcxxabi" IN_LIST FEATURES)
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building libcxxabi with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "libcxxabi")
endif()
if("libunwind" IN_LIST FEATURES)
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building libunwind with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "libunwind")
endif()
if("lld" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lld")
endif()
if("lldb" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lldb")
endif()
if("mlir" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "mlir")
endif()
if("openmp" IN_LIST FEATURES)
    # Disable OpenMP on Windows (see https://bugs.llvm.org/show_bug.cgi?id=45074).
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building OpenMP with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "openmp")
    # Perl is required for the OpenMP run-time
    vcpkg_find_acquire_program(PERL)
    list(APPEND FEATURE_OPTIONS
        "-DPERL_EXECUTABLE=${PERL}"
    )
    if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
        list(APPEND FEATURE_OPTIONS
            -DLIBOMP_DEFAULT_LIB_NAME=libompd
        )
    endif()
endif()
if("parallel-libs" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "parallel-libs")
endif()
if("polly" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "polly")
endif()
if("pstl" IN_LIST FEATURES)
    if(VCPKG_TARGET_IS_WINDOWS)
        message(FATAL_ERROR "Building pstl with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "pstl")
endif()

set(known_llvm_targets
    AArch64
    AMDGPU
    ARM
    AVR
    BPF
    Hexagon
    Lanai
    Mips
    MSP430
    NVPTX
    PowerPC
    RISCV
    Sparc
    SystemZ
    WebAssembly
    X86
    XCore
)

set(LLVM_TARGETS_TO_BUILD "")
foreach(llvm_target IN LISTS known_llvm_targets)
    string(TOLOWER "target-${llvm_target}" feature_name)
    if(feature_name IN_LIST FEATURES)
        list(APPEND LLVM_TARGETS_TO_BUILD "${llvm_target}")
    endif()
endforeach()

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(${PYTHON3_DIR})

# Version-specific options
set(VERSION_OPTIONS)
if(LLVM_VERSION_MAJOR GREATER_EQUAL 9)
    list(APPEND VERSION_OPTIONS "-DCMAKE_CXX_STANDARD=14")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}/llvm
    PREFER_NINJA
    OPTIONS
        ${FEATURE_OPTIONS}
        ${VERSION_OPTIONS}
        -DLLVM_INCLUDE_EXAMPLES=OFF
        -DLLVM_BUILD_EXAMPLES=OFF
        -DLLVM_INCLUDE_TESTS=OFF
        -DLLVM_BUILD_TESTS=OFF
        # Disable optional dependencies to libxml2, zlib, and libedit.
        -DLLVM_ENABLE_LIBXML2=OFF
        -DLLVM_ENABLE_ZLIB=OFF
        -DLLVM_ENABLE_LIBEDIT=OFF
        # Disable linking to Windows PDB analysis library (hard-coded path in LLVMExports.cmake)
        -DLLVM_ENABLE_DIA_SDK=OFF
        # Force TableGen to be built with optimization. This will significantly improve build time.
        -DLLVM_OPTIMIZED_TABLEGEN=ON
        "-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS}"
        "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
        -DPACKAGE_VERSION=${LLVM_VERSION}
        # Limit the maximum number of concurrent link jobs to 1. This should fix low amount of memory issue for link.
        -DLLVM_PARALLEL_LINK_JOBS=2
        # Disable build LLVM-C.dll (Windows only) due to doesn't compile with CMAKE_DEBUG_POSTFIX
        -DLLVM_BUILD_LLVM_C_DYLIB=OFF
        # Path for binary subdirectory (defaults to 'bin')
        -DLLVM_TOOLS_INSTALL_DIR=tools/llvm
    OPTIONS_DEBUG
        -DCMAKE_DEBUG_POSTFIX=d
)

vcpkg_install_cmake()

vcpkg_fixup_cmake_targets(CONFIG_PATH "share/llvm" TARGET_PATH "share/llvm")
file(INSTALL ${SOURCE_PATH}/llvm/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)


if("clang" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/clang" TARGET_PATH "share/clang" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/clang/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/clang RENAME copyright)
endif()

if("clang-tools-extra" IN_LIST FEATURES)
    # Remove empty include directory include/clang-tidy/plugin
    file(GLOB_RECURSE INCLUDE_CLANG_TIDY_PLUGIN_FILES "${CURRENT_PACKAGES_DIR}/include/clang-tidy/plugin/*")
    if(NOT INCLUDE_CLANG_TIDY_PLUGIN_FILES)
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/clang-tidy/plugin")
    endif()
endif()

if("flang" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/flang" TARGET_PATH "share/flang" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/flang/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/flang RENAME copyright)
    # Remove empty include directory /include/flang/Config
    file(GLOB_RECURSE INCLUDE_FLANG_CONFIG_FILES "${CURRENT_PACKAGES_DIR}/include/flang/Config/*")
    if(NOT INCLUDE_FLANG_CONFIG_FILES)
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/include/flang/Config")
    endif()
endif()

if("lld" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/lld" TARGET_PATH "share/lld" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/lld/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/lld RENAME copyright)
endif()

if("mlir" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/mlir" TARGET_PATH "share/mlir" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/mlir/LICENSE.TXT DESTINATION ${CURRENT_PACKAGES_DIR}/share/mlir RENAME copyright)
endif()

if("polly" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/polly" TARGET_PATH "share/polly" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/polly/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/polly RENAME copyright)
endif()

if("pstl" IN_LIST FEATURES)
    vcpkg_fixup_cmake_targets(CONFIG_PATH "share/ParallelSTL" TARGET_PATH "share/ParallelSTL" DO_NOT_DELETE_PARENT_CONFIG_PATH)
    file(INSTALL ${SOURCE_PATH}/pstl/LICENSE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/ParallelSTL RENAME copyright)
endif()

vcpkg_copy_tool_dependencies(${CURRENT_PACKAGES_DIR}/tools/llvm)

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/include)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/share)
    file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug/tools)
endif()

# LLVM still generates a few DLLs in the static build:
# * libclang.dll
# * LTO.dll
# * Remarks.dll
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
