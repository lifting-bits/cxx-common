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

def macos_installer_cmake(properties):
  return unix_installer_cmake(properties)

def linux_installer_cmake(properties):
  return unix_installer_cmake(properties)

def macos_installer_boost(properties):
  return unix_installer_boost(properties, "clang")

def linux_installer_boost(properties):
  return unix_installer_boost(properties, "cc")
