#!/usr/bin/env bash

DEFAULT_LLVM_VERSION=40

function main
{
  local llvm_version="${DEFAULT_LLVM_VERSION}"
  local build_type="Release"
  while [[ $# -gt 0 ]] ; do
    key="$1"

    case $key in

      # Change the default installation prefix.
      --prefix)
        local root_install_directory=$(python -c \
            "import os; import sys; sys.stdout.write(os.path.abspath('${2}'))")
        shift # past argument
      ;;

      # Change the default LLVM version.
      --llvm-version)
        llvm_version="${2//./}"
        shift
      ;;

      # Change the build type.
      --build-type)
        build_type="$2"
        shift
      ;;

      *)
        # unknown option
        printf "Unknown option: ${key}\n"
        return 1
      ;;
    esac

    shift # past argument or value
  done

  if [ -z "$root_install_directory" ] ; then
    printf "Please enter a full path to the install directory using --prefix.\n"
    return 1
  fi

  local install_folder_name=`basename "$root_install_directory"`
  if [[ "$install_folder_name" != "libraries" ]] ; then
    printf "Please enter the full path of a folder named 'libraries'\n"
    return 1
  fi

  if [ -d "$root_install_directory" ] ; then
    rm -rf "$root_install_directory" 2> /dev/null
    if [ $? -ne 0 ] ; then
      printf "Failed to erase the following folder: ${root_install_directory}\n"
      return 1
    fi
  fi

  mkdir -p "$root_install_directory" 2> /dev/null
  if [ $? -ne 0 ] ; then
    printf "Failed to create the install directory\n"
    return 1
  fi

  printf "Checking dependencies...\n"
  CheckDependencies || return 1

  local root_build_directory=`pwd`

  export BUILD_TYPE="${build_type}"

  # First, build LLVM using the system compiler.
  InstallLLVM "$llvm_version" "${root_build_directory}/llvm-system" || return 1

  export CC="${root_build_directory}/llvm-system/bin/clang"
  export CXX="${root_build_directory}/llvm-system/bin/clang++"

  # Kill the old LLVM build dir.
  rm -rf "${root_build_directory}/llvm-build"

  # Recompile LLVM, self-hosting it.
  InstallLLVM "$llvm_version" "${root_install_directory}/llvm" || return 1
  
  # Use the self-hosted LLVM to build the rest of the stuff.
  export CC="${root_install_directory}/llvm/bin/clang"
  export CXX="${root_install_directory}/llvm/bin/clang++"

  InstallCMake "${root_install_directory}/cmake" || return 1
  InstallCapstone "${root_install_directory}/capstone" || return 1
  InstallGoogleGlog "${root_install_directory}/glog" || return 1
  InstallGoogleGflags "${root_install_directory}/gflags" || return 1
  InstallGoogleTest "${root_install_directory}/googletest" || return 1
  InstallGoogleProtocolBuffers "${root_install_directory}/protobuf" || return 1
  InstallXED "${root_install_directory}/xed" || return 1

  if [ $? -eq 1 ] ; then
      return 1
  fi

  InstallCMakeModules "${root_install_directory}/cmake" || return 1

  rm "$LOG_FILE" 2> /dev/null

  printf "\nAdd the following lines to your .bashrc/.zshenv file:\n"
  printf "  export TRAILOFBITS_LIBRARIES=${root_install_directory}\n"

  printf "\nAdd the following to your CMakeLists.txt file:\n"
  printf "  set(LIBRARY_REPOSITORY_ROOT \$ENV{TRAILOFBITS_LIBRARIES})\n"
  printf "  include(\"\${LIBRARY_REPOSITORY_ROOT}/cmake/repository.cmake\")\n"

  printf "\nYou can clean up this folder using git clean -ffdx!\n"
  return 0
}

function ShowUsage
{
    printf "Usage:\n"
    printf "\tbuild.sh [--llvm-version MAJOR.MINOR] /path/to/libraries\n"
    printf "\tbuild.sh --help\n\n"
    return 0
}

function CheckDependencies
{
    # todo
    return 0
}

function ShowLog
{
    printf "An error as occurred and the script has terminated.\n"

    if [ ! -f "$LOG_FILE" ] ; then
        printf "No output log found\n"
        return 1
    fi

    printf "Output log follow\n================\n"
    cat "$LOG_FILE"
    printf "\n================\n"

    return 0
}

function InstallXED
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallXED /path/to/libraries"

        return 1
    fi

    printf "\nXED\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "xed" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/intelxed/xed.git" xed >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "xed" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # acquire or update the build system for xed
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "mbuild" ] ; then
        printf " > Acquiring the build system...\n"
        git clone "https://github.com/intelxed/mbuild.git" mbuild >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the mbuild source code...\n"
        ( cd "mbuild" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install the library
    printf " > Installing...\n"
    rm "$LOG_FILE" 2> /dev/null
    ( cd xed && python2 mfile.py "--prefix=${install_directory}" install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallLLVM
{
    if [ $# -ne 2 ] ; then
        printf "Usage:\n"
        printf "\tInstallLLVM <version> /path/to/libraries\n\n"
        printf "version: the major and minor release without separators (i.e.: 38, 39)\n"
        return 1
    fi

    printf "\nLLVM\n"

    local version="$1"
    local install_directory="$2"

    printf " > Version: ${version}\n"
    printf " > Install directory: ${install_directory}\n"

    # Make the install directory.
    mkdir -p "${install_directory}"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "llvm" ] ; then
        printf " > Acquiring the source code for LLVM...\n"
        git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/llvm.git" llvm >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code for LLVM...\n"
        ( cd "llvm" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "llvm/tools/clang" ] ; then
        printf " > Acquiring the source code for Clang...\n"
        git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/clang.git" llvm/tools/clang >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code for Clang...\n"
        ( cd "llvm/tools/clang" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
    fi

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "llvm/projects/libcxx" ] ; then
        printf " > Acquiring the source code for libc++...\n"
        git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/libcxx.git" llvm/projects/libcxx >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code for libc++...\n"
        ( cd "llvm/projects/libcxx" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
    fi

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "llvm/projects/libcxxabi" ] ; then
        printf " > Acquiring the source code for libc++ ABI...\n"
        git clone --depth 1 -b "release_${version}" "https://github.com/llvm-mirror/libcxxabi.git" llvm/projects/libcxxabi >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code for libc++ ABI...\n"
        ( cd "llvm/projects/libcxxabi" && git pull origin "release_${version}" ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "llvm-build" ] ; then
        mkdir "llvm-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for LLVM: llvm-build\n"
            return 1
        fi
    fi

    local compiler_flags=""
    if [ ! -z "${CC}" ] ; then
      printf " > CC = ${CC}\n"
      compiler_flags="${compiler_flags} -DCMAKE_C_COMPILER=${CC}"
    fi

    if [ ! -z "${CXX}" ] ; then
      printf " > CXX = ${CC}\n"
      compiler_flags="${compiler_flags} -DCMAKE_CXX_COMPILER=${CXX}"
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" \
                               -DCMAKE_CXX_STANDARD=11 \
                               -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
                               -DLLVM_TARGETS_TO_BUILD="X86;AArch64" \
                               -DLLVM_INCLUDE_EXAMPLES=OFF \
                               -DLLVM_INCLUDE_TESTS=OFF \
                               -DLIBCXX_ENABLE_STATIC=YES \
                               -DLIBCXX_ENABLE_SHARED=YES \
                               -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=NO \
                               -LIBCXX_INCLUDE_BENCHMARKS=NO \
                               -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                               "${compiler_flags}" \
                               "../llvm" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "llvm-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Done\n"

    return 0
}

function InstallGoogleGflags
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleGflags /path/to/libraries"

        return 1
    fi

    printf "\nGoogle gflags\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "gflags" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/gflags/gflags.git" gflags >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "gflags" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "gflags-build" ] ; then
        mkdir "gflags-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google gflags: gflags-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null

    ( cd "gflags-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" \
                                 -DCMAKE_CXX_STANDARD=11 \
                                 -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
                                 -DGFLAGS_BUILD_TESTING=OFF \
                                 -DGFLAGS_BUILD_SHARED_LIBS=OFF \
                                 -DGFLAGS_BUILD_STATIC_LIBS=ON \
                                 -DGFLAGS_NAMESPACE="google" \
                                 -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                                 "../gflags" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "gflags-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "gflags-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleTest
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleTest /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Test\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "googletest" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/google/googletest.git" googletest >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "googletest" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "googletest-build" ] ; then
        mkdir "googletest-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google googletest: googletest-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" \
                                     -DCMAKE_CXX_STANDARD=11 \
                                     -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
                                     -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                                     "../googletest" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "googletest-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallGoogleProtocolBuffers
{
    local protobuf_version="2.6.1"
    local gtest_version="1.5.0"

    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleProtocolBuffers /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Protocol Buffers\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire the source code
    if [ ! -f "protobuf-v${protobuf_version}.tar.gz" ] ; then
        printf " > Acquiring the source code for protobuf...\n"

        rm "$LOG_FILE" 2> /dev/null
        wget "https://github.com/google/protobuf/archive/v${protobuf_version}.tar.gz" -O "protobuf-v${protobuf_version}.tar.gz" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm "protobuf-v${protobuf_version}.tar.gz" 2> /dev/null

            ShowLog
            return 1
        fi
    fi

    if [ ! -d "protobuf-${protobuf_version}" ] ; then
        printf " > Extracting the protobuf source code...\n"

        rm "$LOG_FILE" 2> /dev/null
        tar xzf "protobuf-v${protobuf_version}.tar.gz" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm -rf "v${protobuf_version}" 2> /dev/null
            rm "protobuf-v${protobuf_version}.tar.gz" 2> /dev/null

            ShowLog
            return 1
        fi
    fi

    # autogen.sh will attempt to fetch gtest from a broken link
    # we can work around the issue by downloading it manually
    if [ ! -f "gtest-${gtest_version}.tar.gz" ] ; then
        printf " > Acquiring the source code for protobuf/gtest...\n"

        rm "$LOG_FILE" 2> /dev/null
        wget "https://codeload.github.com/google/googletest/tar.gz/release-${gtest_version}" -O "gtest-${gtest_version}.tar.gz">> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm "gtest-${gtest_version}.tar.gz" 2> /dev/null

            ShowLog
            return 1
        fi
    fi

    if [ ! -d "protobuf-${protobuf_version}/gtest" ] ; then
        printf " > Extracting the protobuf/gtest source code...\n"

        rm "$LOG_FILE" 2> /dev/null
        tar xzf "gtest-${gtest_version}.tar.gz" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm -rf "googletest-release-${gtest_version}" 2> /dev/null
            rm "gtest-${gtest_version}.tar.gz" 2> /dev/null

            ShowLog
            return 1
        fi

        mv "googletest-release-${gtest_version}" "protobuf-${protobuf_version}/gtest" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to copy the gtest folder inside the protobuf source tree\n"
            return 1
        fi
    fi

    # configure
    printf " > Configuring...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}" && ./autogen.sh ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}" && \
      CXXFLAGS="-fPIC" CFLAGS="-fPIC" ./configure "--prefix=${install_directory}" \
                                                  --disable-shared \
                                                  --enable-static ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    export LIBRARY_PATH="${install_directory}/lib"
    export LD_LIBRARY_PATH="$LIBRARY_PATH"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}/python" && python2 setup.py build ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "protobuf-${protobuf_version}/python" && python2 setup.py build ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    mkdir -p "${install_directory}/python" 2> /dev/null
    if [ $? -ne 0 ] ; then
        printf "Failed to create the installation directory for the protobuf python module.\n"
        return 1
    fi

    cp -r "protobuf-${protobuf_version}/python/build/lib.linux-$(uname -p)-2.7/google" "${install_directory}/python" 2> /dev/null
    if [ $? -ne 0 ] ; then
        printf "Failed to install the protobuf python module.\n"
        return 1
    fi

    unset LIBRARY_PATH
    unset LD_LIBRARY_PATH

    return 0
}

function InstallGoogleGlog
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallGoogleGlog /path/to/libraries"

        return 1
    fi

    printf "\nGoogle Logging module\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire or update the source code
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "glog" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/google/glog.git" glog >> "$LOG_FILE" 2>&1
    else
        printf " > Updating the source code...\n"
        ( cd "glog" && git pull origin master ) >> "$LOG_FILE" 2>&1
    fi

    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # run cmake
    printf " > Configuring...\n"

    if [ ! -d "glog-build" ] ; then
        mkdir "glog-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for Google glog: glog-build\n"
            return 1
        fi
    fi

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && cmake "-DCMAKE_INSTALL_PREFIX=${install_directory}" \
                               -DCMAKE_CXX_STANDARD=11 \
                               -DCMAKE_BUILD_TYPE="${BUILD_TYPE}" \
                               -DBUILD_TESTING=OFF \
                               -DWITH_GFLAGS=OFF \
                               -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                               "../glog" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "glog-build" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallCapstone
{
    if [ $# -ne 1 ]; then
        printf "Usage:\n"
        printf "\tInstallCapstone /path/to/libraries"

        return 1
    fi
    
    printf "\nInstall capstone modules...\n"

    local TAG_VER=tags/3.0.4
    local BUILD_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local INSTALL_PATH="$1"
    local TARGET_NAME=$(basename "${INSTALL_PATH}")
    
    printf " > Install directory: ${INSTALL_PATH}\n"

    function check_error
    {
        local ERR_CODE="$1"
        if [ $ERR_CODE -ne 0 ]; then
            ShowLog
            return 1
        fi
        return 0
    }
    
    # get the source code of capstone with correct tag version
    rm "$LOG_FILE" 2> /dev/null
    if [ ! -d "$TARGET_NAME" ] ; then
        printf " > Acquiring the source code...\n"
        git clone "https://github.com/aquynh/capstone.git" "$TARGET_NAME" >> "$LOG_FILE" 2>&1
        ( cd $TARGET_NAME && git checkout $TAG_VER >> "$LOG_FILE" 2>&1 )
    fi
    check_error $? || ( rm -rf ${TARGET_NAME}* ; return 1)
    
    # configure capstone
    printf " > Configuring ${TARGET_NAME} ...\n"

    if [ ! -d "${TARGET_NAME}-build" ] ; then
        mkdir "${TARGET_NAME}-build" 2> /dev/null
        if [ $? -ne 0 ] ; then
            printf "Failed to create the build directory for dynamorio: ${TARGET_NAME}-build\n"
            return 1
        fi
    fi
    
    ( cd "${TARGET_NAME}-build" && cmake "-DCMAKE_INSTALL_PREFIX=${INSTALL_PATH}" \
                                         -DCMAKE_EXE_LINKER_FLAGS=-g \
                                         -DCMAKE_C_FLAGS=-g \
                                         -DCAPSTONE_ARM_SUPPORT=1 \
                                         -DCAPSTONE_ARM64_SUPPORT=1 \
                                         -DCAPSTONE_BUILD_SHARED=OFF \
                                         -DCAPSTONE_BUILD_TESTS=OFF \
                                         -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
                                         ../${TARGET_NAME} ) >> "$LOG_FILE" 2>&1

    check_error $? || ( rm -rf ${TARGET_NAME}* ; return 1 )

    # build and install
    printf " > Building ${TARGET_NAME}...\n"
    ( cd "${TARGET_NAME}-build" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1 
    check_error $? || ( rm -rf ${TARGET_NAME}* ; return 1 )
    
    printf " > Installing...\n"
    ( cd "${TARGET_NAME}-build" && make install ) >> "$LOG_FILE" 2>&1
    check_error $? || ( rm -rf ${TARGET_NAME}* ; return 1 )

    # cleanup and remove sources and build directories   
    printf " > Remove build directories ...\n"
    if [ -d "${TARGET_NAME}" ] ; then
        rm -rf ${TARGET_NAME}*
    fi

    return 0
}

function InstallCMake
{
    local cmake_version="3.8.2"

    if [ $# -ne 1 ]; then
        printf "Usage:\n"
        printf "\tInstallCMake /path/to/libraries"

        return 1
    fi

    printf "\nCMake\n"

    local install_directory="$1"
    printf " > Install directory: ${install_directory}\n"

    # acquire the source code
    local source_tarball_name="cmake-v${cmake_version}.tar.gz"

    if [ ! -f "${source_tarball_name}" ] ; then
        printf " > Acquiring the source tarball...\n"

        rm "$LOG_FILE" 2> /dev/null
        wget "https://github.com/Kitware/CMake/archive/v${cmake_version}.tar.gz" -O "${source_tarball_name}" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm "${source_tarball_name}" 2> /dev/null

            ShowLog
            return 1
        fi
    fi

    # extract the source
    local source_folder_name="CMake-${cmake_version}"

    if [ ! -d "${source_folder_name}" ] ; then
        printf " > Extracting the CMake source code...\n"

        rm "$LOG_FILE" 2> /dev/null
        tar xzf "${source_tarball_name}" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ] ; then
            rm -rf "${source_folder_name}" 2> /dev/null
            rm "${source_tarball_name}" 2> /dev/null

            ShowLog
            return 1
        fi
    fi

    # configure
    printf " > Configuring...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "${source_folder_name}" && ./configure "--prefix=${install_directory}" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    # build and install
    printf " > Building...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "${source_folder_name}" && make -j "$PROCESSOR_COUNT" ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    printf " > Installing...\n"

    rm "$LOG_FILE" 2> /dev/null
    ( cd "${source_folder_name}" && make install ) >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

function InstallCMakeModules
{
    if [ $# -ne 1 ] ; then
        printf "Usage:\n"
        printf "\tInstallCMakeModules /path/to/libraries"

        return 1
    fi

    printf "\nCMake modules...\n"

    local build_sh_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local install_directory="$1"

    printf " > Install directory: ${install_directory}\n"

    printf " > Copying...\n"
    rm "$LOG_FILE" 2> /dev/null
    cp -arp "$build_sh_directory/cmake/." "$install_directory" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ] ; then
        ShowLog
        return 1
    fi

    return 0
}

LOG_FILE="installer.log"

if [[ "$OSTYPE" == "darwin"* ]]; then
    PROCESSOR_COUNT=`sysctl -n hw.ncpu`
else
    PROCESSOR_COUNT=`nproc`
fi

main $@
exit $?
