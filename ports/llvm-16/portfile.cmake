set(LLVM_VERSION "16.0.0")

vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO llvm/llvm-project
    REF llvmorg-${LLVM_VERSION}
    SHA512 e0f7beb0742c6d64d4c0565d6d6f150919ba833e382c4f1ec41dfa9ef2e96047582ed930d8f400f3e484ef3d3b5d60bebe80a8365f0225852b5a220c0127c249
    HEAD_REF release/16.x
    PATCHES
        0001-Fix-install-paths.patch
        0006-Fix-libffi.patch
        0007-Fix-install-bolt.patch
        0020-fix-FindZ3.cmake.patch
        0021-fix-find_dependency.patch
        0026-fix-prefix-path-calc.patch
)

if("pasta" IN_LIST FEATURES)
    z_vcpkg_apply_patches(
        SOURCE_PATH "${SOURCE_PATH}"
        PATCHES
            0025-PASTA-patches.patch
            0027-unknown-attrs-as-annotations.patch
    )
endif()

string(REPLACE "." ";" VERSION_LIST ${LLVM_VERSION})
list(GET VERSION_LIST 0 LLVM_VERSION_MAJOR)
list(GET VERSION_LIST 1 LLVM_VERSION_MINOR)
list(GET VERSION_LIST 2 LLVM_VERSION_PATCH)
# Remove anything after the first patch number (removes suffix like `-rc3`)
if("${LLVM_VERSION_PATCH}" MATCHES "^([0-9]+).*")
    set(LLVM_VERSION_PATCH "${CMAKE_MATCH_1}")
endif()

vcpkg_check_features(
    OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES
        tools LLVM_BUILD_TOOLS
        tools LLVM_INCLUDE_TOOLS
        utils LLVM_BUILD_UTILS
        utils LLVM_INCLUDE_UTILS
        utils LLVM_INSTALL_UTILS
        enable-rtti LLVM_ENABLE_RTTI
        enable-ffi LLVM_ENABLE_FFI
        enable-terminfo LLVM_ENABLE_TERMINFO
        enable-threads LLVM_ENABLE_THREADS
        enable-ios COMPILER_RT_ENABLE_IOS
        enable-eh LLVM_ENABLE_EH
        enable-bindings LLVM_ENABLE_BINDINGS
        enable-z3 LLVM_ENABLE_Z3_SOLVER
)

vcpkg_cmake_get_vars(cmake_vars_file)
include("${cmake_vars_file}")

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

if(VCPKG_USE_SANITIZER)
    list(APPEND FEATURE_OPTIONS
        -DLLVM_USE_SANITIZER=${VCPKG_USE_SANITIZER}
        )
endif()

# LLVM generates CMake error due to Visual Studio version 16.4 is known to miscompile part of LLVM.
# LLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON disables this error.
# See https://developercommunity.visualstudio.com/content/problem/845933/miscompile-boolean-condition-deduced-to-be-always.html
# and thread "[llvm-dev] Longstanding failing tests - clang-tidy, MachO, Polly" on llvm-dev Jan 21-23 2020.
list(APPEND FEATURE_OPTIONS
    -DLLVM_TEMPORARILY_ALLOW_OLD_TOOLCHAIN=ON
)

# Force enable or disable external libraries
set(llvm_external_libraries
    zlib
    zstd
    libxml2
)
foreach(external_library IN LISTS llvm_external_libraries)
    string(TOLOWER "enable-${external_library}" feature_name)
    string(TOUPPER "LLVM_ENABLE_${external_library}" define_name)
    if(feature_name IN_LIST FEATURES)
        list(APPEND FEATURE_OPTIONS
            -D${define_name}=FORCE_ON
        )
    else()
        list(APPEND FEATURE_OPTIONS
            -D${define_name}=OFF
        )
    endif()
endforeach()

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

# LLVM_ABI_BREAKING_CHECKS can be WITH_ASSERTS (default), FORCE_ON or FORCE_OFF.
# By default in LLVM, abi-breaking checks are enabled if assertions are enabled.
# however, this breaks linking with the debug versions, since the option is
# baked into the header files; thus, we always turn off LLVM_ABI_BREAKING_CHECKS
# unless the user asks for it
if("enable-abi-breaking-checks" IN_LIST FEATURES)
    # Force enable abi-breaking checks.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ABI_BREAKING_CHECKS=FORCE_ON
    )
else()
    # Force disable abi-breaking checks.
    list(APPEND FEATURE_OPTIONS
        -DLLVM_ABI_BREAKING_CHECKS=FORCE_OFF
    )
endif()

set(LLVM_ENABLE_PROJECTS)
if("bolt" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "bolt")
endif()
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
endif()
if("clang-tools-extra" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "clang-tools-extra")
endif()
if("flang" IN_LIST FEATURES)
    if(VCPKG_DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" AND VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
        message(FATAL_ERROR "Building Flang with MSVC is not supported on x86. Disable it until issues are fixed.")
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
if("lld" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lld")
endif()
if("lldb" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "lldb")
    list(APPEND FEATURE_OPTIONS
        -DLLDB_ENABLE_CURSES=OFF
    )
endif()
if("mlir" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "mlir")
endif()
if("openmp" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "openmp")
    # Perl is required for the OpenMP run-time
    vcpkg_find_acquire_program(PERL)
    get_filename_component(PERL_PATH ${PERL} DIRECTORY)
    vcpkg_add_to_path(${PERL_PATH})
    # Skip post-build check
    set(VCPKG_POLICY_SKIP_DUMPBIN_CHECKS enabled)
endif()
if("polly" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_PROJECTS "polly")
endif()
if("pstl" IN_LIST FEATURES)
    if(VCPKG_DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(FATAL_ERROR "Building pstl with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_PROJECTS "pstl")
endif()

set(LLVM_ENABLE_RUNTIMES)
if("compiler-rt" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_RUNTIMES "compiler-rt")
endif()
if("libcxx" IN_LIST FEATURES)
    if(VCPKG_DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(FATAL_ERROR "Building libcxx with MSVC is not supported, as cl doesn't support the #include_next extension.")
    endif()
    list(APPEND LLVM_ENABLE_RUNTIMES "libcxx")
endif()
if("libcxxabi" IN_LIST FEATURES)
    if(VCPKG_DETECTED_CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        message(FATAL_ERROR "Building libcxxabi with MSVC is not supported. Disable it until issues are fixed.")
    endif()
    list(APPEND LLVM_ENABLE_RUNTIMES "libcxxabi")
endif()
if("libunwind" IN_LIST FEATURES)
    list(APPEND LLVM_ENABLE_RUNTIMES "libunwind")
endif()

# this is for normal targets
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
    VE
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

# this is for experimental targets
set(known_llvm_experimental_targets
    SPRIV
)

set(LLVM_EXPERIMENTAL_TARGETS_TO_BUILD "")
foreach(llvm_target IN LISTS known_llvm_experimental_targets)
    string(TOLOWER "target-${llvm_target}" feature_name)
    if(feature_name IN_LIST FEATURES)
        list(APPEND LLVM_EXPERIMENTAL_TARGETS_TO_BUILD "${llvm_target}")
    endif()
endforeach()

vcpkg_find_acquire_program(PYTHON3)
get_filename_component(PYTHON3_DIR ${PYTHON3} DIRECTORY)
vcpkg_add_to_path(${PYTHON3_DIR})

set(LLVM_LINK_JOBS 2)

# Cross compilation for M1
if (VCPKG_TARGET_IS_OSX)
    set(LLVM_HOST_TRIPLE "${VCPKG_OSX_ARCHITECTURES}-apple-darwin")
    list(APPEND OPTIONS "-DLLVM_HOST_TRIPLE=${LLVM_HOST_TRIPLE}")
    message(STATUS "Default host triple ${LLVM_HOST_TRIPLE}")
endif()

if (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(LLVM_TARGET_ARCH "AArch64")
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "arm")
    set(LLVM_TARGET_ARCH "ARM")
elseif (VCPKG_TARGET_ARCHITECTURE STREQUAL "x86" OR VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(LLVM_TARGET_ARCH "X86")
else()
    message(FATAL_ERROR "Target Architecture not supported.")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}/llvm
    OPTIONS
        ${FEATURE_OPTIONS}
        ${OPTIONS}
        -DLLVM_INCLUDE_EXAMPLES=OFF
        -DLLVM_BUILD_EXAMPLES=OFF
        -DLLVM_INCLUDE_DOCS=OFF
        -DLLVM_BUILD_DOCS=OFF
        -DLLVM_INCLUDE_TESTS=OFF
        -DLLVM_BUILD_TESTS=OFF
        -DLLVM_INCLUDE_BENCHMARKS=OFF
        -DLLVM_BUILD_BENCHMARKS=OFF
        "-DLLVM_TARGET_ARCH=${LLVM_TARGET_ARCH}"
        # Force TableGen to be built with optimization. This will significantly improve build time.
        -DLLVM_OPTIMIZED_TABLEGEN=ON
        "-DLLVM_ENABLE_PROJECTS=${LLVM_ENABLE_PROJECTS}"
        "-DLLVM_ENABLE_RUNTIMES=${LLVM_ENABLE_RUNTIMES}"
        "-DLLVM_TARGETS_TO_BUILD=${LLVM_TARGETS_TO_BUILD}"
        "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=${LLVM_EXPERIMENTAL_TARGETS_TO_BUILD}"
        -DPACKAGE_VERSION=${LLVM_VERSION}
        # Limit the maximum number of concurrent link jobs to 1. This should fix low amount of memory issue for link.
        "-DLLVM_PARALLEL_LINK_JOBS=${LLVM_LINK_JOBS}"
        -DCMAKE_INSTALL_PACKAGEDIR:STRING=share
        "-DRUNTIMES_CMAKE_ARGS=-DCMAKE_PREFIX_PATH=${CURRENT_INSTALLED_DIR}"
)

vcpkg_cmake_install(ADD_BIN_TO_PATH)

# 'package_name' should be the case of the package used in CMake 'find_package'
# 'FEATURE_NAME' should be the name of the vcpkg port feature
function(llvm_cmake_package_config_fixup package_name)
    cmake_parse_arguments("arg" "DO_NOT_DELETE_PARENT_CONFIG_PATH" "FEATURE_NAME" "" ${ARGN})
    string(TOUPPER "${package_name}" upper_package)
    string(TOLOWER "${package_name}" lower_package)
    if(NOT DEFINED arg_FEATURE_NAME)
        set(arg_FEATURE_NAME ${lower_package})
    endif()
    if("${lower_package}" STREQUAL "llvm" OR "${arg_FEATURE_NAME}" IN_LIST FEATURES)
        set(args)
        # Maintains case even if package_name name is case-sensitive
        list(APPEND args PACKAGE_NAME "${lower_package}")
        if(arg_DO_NOT_DELETE_PARENT_CONFIG_PATH)
            list(APPEND args "DO_NOT_DELETE_PARENT_CONFIG_PATH")
        endif()
        vcpkg_cmake_config_fixup(${args})
        file(INSTALL "${SOURCE_PATH}/${lower_package}/LICENSE.TXT" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}" RENAME copyright)

        # Remove last parent directory
        vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/${lower_package}/${package_name}Config.cmake" "get_filename_component(${upper_package}_INSTALL_PREFIX \"\${${upper_package}_INSTALL_PREFIX}\" PATH)\n\n" "\n")

        if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage")
            file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/${lower_package}_usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${lower_package}" RENAME usage)
        endif()
    endif()
endfunction()

llvm_cmake_package_config_fixup("Clang" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("Flang" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("LLD" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("MLIR" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("OpenMP" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("Polly" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("ParallelSTL" FEATURE_NAME "pstl" DO_NOT_DELETE_PARENT_CONFIG_PATH)
llvm_cmake_package_config_fixup("LLVM")

# Needed because we are doing versioned ports
file(INSTALL "${SOURCE_PATH}/llvm/LICENSE.TXT" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)

set(empty_dirs)

if("clang-tools-extra" IN_LIST FEATURES)
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/clang-tidy/plugin")
endif()

if("flang" IN_LIST FEATURES)
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/Config")
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/CMakeFiles")
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/Optimizer/CMakeFiles")
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/Optimizer/CodeGen/CMakeFiles")
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/Optimizer/Dialect/CMakeFiles")
    list(APPEND empty_dirs "${CURRENT_PACKAGES_DIR}/include/flang/Optimizer/Transforms/CMakeFiles")
endif()

if(empty_dirs)
    foreach(empty_dir IN LISTS empty_dirs)
        if(NOT EXISTS "${empty_dir}")
            message(SEND_ERROR "Directory '${empty_dir}' is not exist. Please remove it from the checking.")
        else()
            file(GLOB_RECURSE files_in_dir "${empty_dir}/*")
            if(files_in_dir)
                message(SEND_ERROR "Directory '${empty_dir}' is not empty. Please remove it from the checking.")
            else()
                file(REMOVE_RECURSE "${empty_dir}")
            endif()
        endif()
    endforeach()
endif()

if(NOT DEFINED VCPKG_BUILD_TYPE OR VCPKG_BUILD_TYPE STREQUAL "debug")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/bin"
        "${CURRENT_PACKAGES_DIR}/debug/include"
        "${CURRENT_PACKAGES_DIR}/debug/share"
        "${CURRENT_PACKAGES_DIR}/debug/lib/clang"
    )
endif()

# Use 'bin' instead of 'tools/llvm'
file(GLOB_RECURSE release_targets
    "${CURRENT_PACKAGES_DIR}/share/*/*Targets-*.cmake"
    "${CURRENT_PACKAGES_DIR}/share/*/*Exports-*.cmake"
)
foreach(release_target IN LISTS release_targets)
    file(READ "${release_target}" contents)
    string(REPLACE "${CURRENT_INSTALLED_DIR}" "\${_IMPORT_PREFIX}" contents "${contents}")
    string(REGEX REPLACE
        "\\\${_IMPORT_PREFIX}/tools/llvm-16/([^ \"]+${EXECUTABLE_SUFFIX})"
        "\${_IMPORT_PREFIX}/bin/\\1"
        contents "${contents}")
    file(WRITE "${release_target}" "${contents}")
endforeach()

if("mlir" IN_LIST FEATURES)
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/mlir/MLIRConfig.cmake" "set(MLIR_MAIN_SRC_DIR \"${SOURCE_PATH}/mlir\")" "")
    vcpkg_replace_string("${CURRENT_PACKAGES_DIR}/share/mlir/MLIRConfig.cmake" "${CURRENT_BUILDTREES_DIR}" "\${MLIR_INCLUDE_DIRS}")
endif()

# LLVM still generates a few DLLs in the static build:
# * LLVM-C.dll
# * libclang.dll
# * LTO.dll
# * Remarks.dll
set(VCPKG_POLICY_DLLS_IN_STATIC_LIBRARY enabled)
