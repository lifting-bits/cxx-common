# Copyright (c) 2017 Trail of Bits, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import multiprocessing
from utils import *

def unix_installer_boost(properties, default_toolset):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  version = "1.66.0"
  url = "https://dl.bintray.com/boostorg/release/" + version + "/source/boost_" + version.replace(".", "_") + ".tar.gz"

  source_tarball_path = download_file(url, "sources")
  if source_tarball_path is None:
    return False

  if not extract_archive(source_tarball_path, "build"):
    return False

  source_folder = os.path.realpath(os.path.join("build", "boost_" + version.replace(".", "_")))

  if os.environ.get("CMAKE_C_COMPILER") is not None:
    os.environ["CC"] = os.environ["CMAKE_C_COMPILER"]

  if os.environ.get("CMAKE_CXX_COMPILER") is not None:
    os.environ["CXX"] = os.environ["CMAKE_CXX_COMPILER"]

  if os.environ.get("CC") is not None:
    toolset_name = os.environ["CC"]
  else:
    toolset_name = default_toolset

  configure_command = [source_folder + "/bootstrap.sh", "--prefix=" + os.path.join(repository_path, "boost"), "--with-toolset=" + toolset_name]
  if not run_program("Running the bootstrap script...", configure_command, source_folder, verbose=verbose_output):
    return False

  build_command = [source_folder + "/b2", "install", "-d2", "-j" + str(multiprocessing.cpu_count()), "--layout=tagged",
                   "--disable-icu", "threading=multi", "link=static", "optimization=space", "toolset=" + toolset_name]

  if debug:
    build_command += ["--variant=debug"]
  else:
    build_command += ["--variant=release"]

  if not run_program("Building and installing...", build_command, source_folder, verbose=verbose_output):
    return False

  return True

def unix_installer_cmake(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  if debug:
    print(" ! Debug mode is not supported")

  version = "3.9.3"
  url = "https://github.com/Kitware/CMake/archive/v" + version + ".tar.gz"

  source_tarball_path = download_file(url, "sources")
  if source_tarball_path is None:
    return False

  if not extract_archive(source_tarball_path, "build"):
    return False

  source_folder = os.path.join("build", "CMake-" + version)
  destination_path = os.path.join(repository_path, "cmake")

  if os.environ.get("CMAKE_C_COMPILER") is not None:
    os.environ["CC"] = os.environ["CMAKE_C_COMPILER"]

  if os.environ.get("CMAKE_CXX_COMPILER") is not None:
    os.environ["CXX"] = os.environ["CMAKE_CXX_COMPILER"]

  if not run_program("Running the bootstrap script...", ["./bootstrap", "--parallel=" + str(multiprocessing.cpu_count()), "--prefix=" + destination_path], source_folder, verbose=verbose_output):
    return False

  if not run_program("Building the source code...", ["make", "-j" + str(multiprocessing.cpu_count())], source_folder, verbose=verbose_output):
    return False

  if not run_program("Installing...", ["make", "install"], source_folder, verbose=verbose_output):
    return False

  return True

def unix_installer_llvm(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  llvm_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/llvm-" + properties["long_llvm_version"] + ".src.tar.xz"
  llvm_tarball_name = "llvm-" + str(properties["llvm_version"]) + ".tar.xz"

  clang_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/cfe-" + properties["long_llvm_version"] + ".src.tar.xz"
  clang_tarball_name = "clang-" + str(properties["llvm_version"]) + ".tar.xz"

  libcxx_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/libcxx-" + properties["long_llvm_version"] + ".src.tar.xz"
  libcxx_tarball_name = "libcxx-" + str(properties["llvm_version"]) + ".tar.xz"

  libcxxabi_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/libcxxabi-" + properties["long_llvm_version"] + ".src.tar.xz"
  libcxxabi_tarball_name = "libcxxabi-" + str(properties["llvm_version"]) + ".tar.xz"

  # download everything we need
  llvm_tarball_path = download_file(llvm_tarball_url, "sources", llvm_tarball_name)
  if llvm_tarball_path is None:
    return False

  clang_tarball_path = download_file(clang_tarball_url, "sources", clang_tarball_name)
  if clang_tarball_path is None:
    return False

  libcxx_tarball_path = download_file(libcxx_tarball_url, "sources", libcxx_tarball_name)
  if libcxx_tarball_path is None:
    return False

  libcxxabi_tarball_path = download_file(libcxxabi_tarball_url, "sources", libcxxabi_tarball_name)
  if libcxxabi_tarball_path is None:
    return False

  # extract everything in the correct folders
  if not extract_archive(llvm_tarball_path, "sources"):
    return False

  if not extract_archive(clang_tarball_path, "sources"):
    return False

  if not extract_archive(libcxx_tarball_path, "sources"):
    return False

  if not extract_archive(libcxxabi_tarball_path, "sources"):
    return False

  llvm_root_folder = os.path.realpath(os.path.join("sources", "llvm-" + str(properties["long_llvm_version"] + ".src")))

  try:
    print(" > Moving the project folders in the LLVM source tree...")

    libcxx_destination = os.path.join(llvm_root_folder, "projects", "libcxx")
    if not os.path.isdir(libcxx_destination):
      shutil.move(os.path.join("sources", "libcxx-" + properties["long_llvm_version"] + ".src"), libcxx_destination)

    libcxxabi_destination = os.path.join(llvm_root_folder, "projects", "libcxxabi")
    if not os.path.isdir(libcxxabi_destination):
      shutil.move(os.path.join("sources", "libcxxabi-" + properties["long_llvm_version"] + ".src"), libcxxabi_destination)

    clang_destination = os.path.join(llvm_root_folder, "tools", "clang")
    if not os.path.isdir(clang_destination):
      shutil.move(os.path.join("sources", "cfe-" + properties["long_llvm_version"] + ".src"), clang_destination)

  except Exception as e:
    print(" ! " + str(e))
    print(" x Failed to build the source tree")
    return False

  # create the build directory and compile the package
  llvm_build_path = os.path.realpath(os.path.join("build", "llvm-" + str(properties["llvm_version"])))
  if not os.path.isdir(llvm_build_path):
    try:
      os.makedirs(llvm_build_path)

    except Exception as e:
      print(" ! " + str(e))
      print(" x Failed to create the build folder")
      return False

  destination_path = os.path.join(repository_path, "llvm")

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + ["-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "llvm"),
                                                                                           "-DCMAKE_CXX_STANDARD=11", "-DLLVM_TARGETS_TO_BUILD='X86;AArch64'",
                                                                                           "-DLLVM_INCLUDE_EXAMPLES=OFF", "-DLLVM_INCLUDE_TESTS=OFF"]

  if properties["llvm_version"] < 371:
    cmake_command += ["-DLIBCXX_ENABLE_SHARED=NO"]
  else:
    cmake_command += ["-DLIBCXX_ENABLE_STATIC=YES", "-DLIBCXX_ENABLE_SHARED=YES",
                      "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=NO",
                      "-LIBCXX_INCLUDE_BENCHMARKS=NO"]

  cmake_command += [llvm_root_folder]

  if not run_program("Configuring...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  return True

def macos_installer_cmake(properties):
  return unix_installer_cmake(properties)

def linux_installer_cmake(properties):
  return unix_installer_cmake(properties)

def macos_installer_llvm(properties):
  return unix_installer_llvm(properties)

def linux_installer_llvm(properties):
  return unix_installer_llvm(properties)

def macos_installer_boost(properties):
  return unix_installer_boost(properties, "clang")

def linux_installer_boost(properties):
  return unix_installer_boost(properties, "cc")
