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
  sudo apt-get install -qqy python2.7 build-essential realpath
  if [ $? -ne 0 ] ; then
    printf " x Could not install the required dependencies\n"
    return 1
  fi

  printf " > The system has been successfully initialized\n"
  return 0
}

osx_initialize() {
  printf "Initializing platform: osx\n"

  printf " x This platform is not yet supported\n"
  return 1
}

linux_build() {
  printf "Building platform: linux\n"

  printf " > Creating the repository folder...\n"
  if [ ! -d "repository" ] ; then
    mkdir "repository"
    if [ $? -ne 0 ] ; then
      printf " x Failed to create the folder\n"
      return 1
    fi
  fi

  printf " > Launching the build script for CMake...\n"

  printf "\n===\n"
  local repository_path=`realpath repository`
  python2 pkgman.py --verbose "--repository_path=${repository_path}" "--packages=cmake"
  local pkgman_error=$?
  printf "===\n\n"

  if [ "$pkgman_error" -ne 0 ] ; then
    printf " x Build failed\n"
    return 1
  fi

  printf " > Launching the build script for LLVM...\n"  

  printf "\n===\n"
  local repository_path=`realpath repository`
  python2 pkgman.py --verbose "--additional_paths=${repository_path}/cmake/bin" "--repository_path=${repository_path}" "--packages=llvm"
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
    ln -s "${repository_path}/llvm/bin/clang" "temp/bin/gcc"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang symbolic link"
      return 1
    fi
  fi

  if [ ! -f "temp/bin/g++" ] ; then
    ln -s "${repository_path}/llvm/bin/clang++" "temp/bin/g++"
    if [ $? -ne 0 ] ; then
      printf "Failed to create the clang++ symbolic link"
      return 1
    fi
  fi

  custom_bin_path=`realpath "temp/bin"`

  printf " > Launching the build script for the remaining packages...\n"  

  printf "\n===\n"
  local repository_path=`realpath repository`
  python2 pkgman.py "--cxx_compiler=${repository_path}/llvm/bin/clang" "--c_compiler=${repository_path}/llvm/bin/clang++" --verbose "--additional_paths=${repository_path}/cmake/bin:${repository_path}/llvm/bin:${custom_bin_path}" "--repository_path=${repository_path}" "--packages=llvm,capstone,gflags,glog,googletest,xed,protobuf"
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
  printf "Building for platform: osx\n"

  printf " x This platform is not yet supported\n"
  return 1
}

main $@
exit $?
