#!/usr/bin/env bash

main() {
  if [ $# -ne 2 ] ; then
    printf "Usage:\n\ttravis.sh <linux|osx> <initialize|build>\n"
    return 1
  fi

  local platform_name="$1"
  local operation_type="$2"

  if [[ "${platform_name}" != "osx" && "${platform_name}" != "linux" ]] ; then
    printf "Invalid platform: ${platform_name}\n"
    return 1
  fi

  if [[ "${operation_type}" == "initialize" ]] ; then
    "${platform_name}_initialize"
    return $?

  elif [[ "$operation_type" == "build" ]] ; then
    "${platform_name}_build"
    return $?

  else
    printf "Invalid operation\n"
    return 1
  fi
}

linux_initialize() {
  printf "Initializing platform: linux\n"

  printf " > Updating the system...\n"
  sudo apt-get -qq update
  if [ $? -ne 0 ] ; then
    printf " x The package database could not be updated\n"
    return 1
  fi

  printf " > Installing the required packages...\n"
  sudo apt-get install -qqy python2.7 build-essential python3 python3-pip clang ninja-build
  if [ $? -ne 0 ] ; then
    printf " x Could not install the required dependencies\n"
    return 1
  fi

  # This may fail.
  sudo apt-get install -qqy realpath

  # This will fail on Ubuntu 14.04
  sudo apt-get install -qqy z3 >/dev/null 2>/dev/null

  # ubuntu 14.04 needs a new libstdc++ and gcc to build llvm. provide it
  # TODO(artem): Gate this for ubuntu 14.04 if it breaks newer ubuntu
  sudo apt-get install -qqy software-properties-common
  sudo add-apt-repository -q ppa:ubuntu-toolchain-r/test
  sudo apt-get update -qqy
  sudo apt-get install gcc-7 g++-7 -y && \
  sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 60 --slave /usr/bin/g++ g++ /usr/bin/g++-7

  printf " > Updating setuptools...\n"
  sudo pip3 install --upgrade setuptools > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    printf " x Could not update setuptools\n"
    return 1
  fi

  printf " > The system has been successfully initialized\n"
  return 0
}

osx_initialize() {
  printf "Initializing platform: osx\n"

  which -s brew
  if [[ $? != 0 ]] ; then
      printf " x OS X is only supported with Homebrew. Please install it: https://brew.sh/\n"
      return 1
  fi

  brew update
  if [ $? -ne 0 ] ; then
    printf " x The package database could not be updated\n"
    return 1
  fi

  printf " > Making sure XCode is installed...\n"
  xcode-select --install 2>&1 > /dev/null

  printf " > Installing the required packages...\n"
  brew install coreutils ccache
  if [ $? -ne 0 ] ; then
    printf " x Could not install the required dependencies\n"
    return 1
  fi
  pip3 install requests

  printf " > The system has been successfully initialized\n"
  return 0
}

linux_build() {
  printf "Building platform: linux\n"

  local bootstrap_repository="/opt/trailofbits/bootstrap"
  local library_repository="/opt/trailofbits/libraries"

  printf " > Creating the repository folders...\n"
  if [ ! -d "${bootstrap_repository}" ] ; then
    mkdir -p "${bootstrap_repository}"
    if [ $? -ne 0 ] ; then
      printf " x Failed to create the folder\n"
      return 1
    fi
  fi

  if [ ! -d "${library_repository}" ] ; then
    mkdir -p "${library_repository}"
    if [ $? -ne 0 ] ; then
      printf " x Failed to create the folder\n"
      return 1
    fi
  fi

  printf " > Launching the build script for CMake...\n"

  printf "\n===\n"
  python3 pkgman.py --c_compiler=$(which clang) --cxx_compiler=$(which clang++) --verbose "--repository_path=${bootstrap_repository}" "--packages=cmake"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  printf " > Launching the build script for LLVM...\n"

  printf "\n===\n"
  python3 pkgman.py --c_compiler=$(which clang) --cxx_compiler=$(which clang++) --exclude_libcxx --verbose "--additional_paths=${bootstrap_repository}/cmake/bin" "--repository_path=${bootstrap_repository}" "--packages=llvm"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  # REALLY make sure that everyone will use clang from now on
  if [ ! -d "temp/bin" ] ; then
    mkdir "temp/bin"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the temporary bin folder"
      return 1
    fi
  fi

  if [ ! -f "temp/bin/gcc" ] ; then
    ln -s "${bootstrap_repository}/llvm/bin/clang" "temp/bin/gcc"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang symbolic link"
      return 1
    fi
  fi

  if [ ! -f "temp/bin/g++" ] ; then
    ln -s "${bootstrap_repository}/llvm/bin/clang++" "temp/bin/g++"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang++ symbolic link"
      return 1
    fi
  fi

  custom_bin_path=`realpath "temp/bin"`

  printf " > Erasing the LLVM and CMake build folders...\n"
  rm -rf "build/llvm"
  rm -rf "build/CMake*"

  printf " > Re-launching the build script using the newly built clang...\n"

  printf "\n===\n"
  python3 pkgman.py "--cxx_compiler=${bootstrap_repository}/llvm/bin/clang++" "--c_compiler=${bootstrap_repository}/llvm/bin/clang" --verbose "--additional_paths=${bootstrap_repository}/cmake/bin:${bootstrap_repository}/llvm/bin:${custom_bin_path}" "--repository_path=${library_repository}" "--packages=cmake,capstone,google,xed,capnproto"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  printf " > Build succeeded\n"
  return 0
}

osx_build() {
  printf "Building platform: osx (homebrew)\n"

  local bootstrap_repository="/usr/local/share/trailofbits/bootstrap"
  local library_repository="/usr/local/share/trailofbits/libraries"

  printf " > Creating the repository folders...\n"
  if [ ! -d "${bootstrap_repository}" ] ; then
    mkdir -p "${bootstrap_repository}"
    if [ $? -ne 0 ] ; then
      printf " x Failed to create the folder\n"
      return 1
    fi
  fi

  if [ ! -d "${library_repository}" ] ; then
    mkdir -p "${library_repository}"
    if [ $? -ne 0 ] ; then
      printf " x Failed to create the folder\n"
      return 1
    fi
  fi

  printf " > Launching the build script for CMake...\n"

  printf "\n===\n"
  python3 pkgman.py --verbose "--repository_path=${bootstrap_repository}" "--packages=cmake"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  printf " > Launching the build script for LLVM...\n"

  printf "\n===\n"
  python3 pkgman.py --verbose "--additional_paths=${bootstrap_repository}/cmake/bin" "--use_ccache" "--repository_path=${library_repository}" "--packages=llvm"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  # REALLY make sure that everyone will use clang from now on
  if [ ! -d "temp/bin" ] ; then
    mkdir "temp/bin"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the temporary bin folder"
      return 1
    fi
  fi

  if [ ! -f "temp/bin/gcc" ] ; then
    ln -s "${library_repository}/llvm/bin/clang" "temp/bin/gcc"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang symbolic link"
      return 1
    fi
  fi

  if [ ! -f "temp/bin/g++" ] ; then
    ln -s "${library_repository}/llvm/bin/clang++" "temp/bin/g++"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang++ symbolic link"
      return 1
    fi
  fi

  custom_bin_path=`realpath "temp/bin"`

  printf " > Erasing the LLVM and CMake build folders...\n"
  rm -rf "build/llvm"
  rm -rf "build/CMake*"

  printf " > Re-launching the build script using the newly built clang...\n"

  printf "\n===\n"
  python3 pkgman.py "--cxx_compiler=${library_repository}/llvm/bin/clang++" "--c_compiler=${library_repository}/llvm/bin/clang" --verbose "--additional_paths=${bootstrap_repository}/cmake/bin:${library_repository}/llvm/bin:${custom_bin_path}" "--repository_path=${library_repository}" "--packages=cmake,capstone,google,xed,capnproto"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  printf " > Build succeeded\n"
  return 0
}

main $@
exit $?
