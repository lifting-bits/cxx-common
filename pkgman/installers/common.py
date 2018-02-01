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

import time
import os
import platform
import sys
import shutil

from utils import *
from distutils import spawn
from distutils.dir_util import copy_tree

PATCHES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "patches")

def patch_file(file_path, patch_name):
  patch_path = os.path.join(PATCHES_DIR, "{}.patch".format(patch_name))
  if not os.path.exists(patch_path):
    print(" x Failed to find patch file {}".format(patch_name))
    return False

  run_program("Patching {}".format(file_path),
              ["patch", file_path, patch_path],
              os.getcwd())
  return True

def get_python_path(version):
  # some distributions have choosen to set python 3 as the default version
  # always request the exact executable name first
  if version != 2 and version != 3:
    return None

  path = spawn.find_executable("python" + str(version))
  if path is not None:
    return path

  path = spawn.find_executable("python")
  if path is not None:
    return path

  return None

def common_installer_glog(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("google", "glog")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "glog")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DBUILD_TESTING=OFF",
                    "-DWITH_GFLAGS=OFF",
                    "-DCMAKE_EXE_LINKER_FLAGS=-g",
                    "-DCMAKE_C_FLAGS=-g",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "glog"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_capstone(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("aquynh", "capstone")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "capstone")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_EXE_LINKER_FLAGS=-g",
                    "-DCMAKE_C_FLAGS=-g",
                    "-DCAPSTONE_ARM_SUPPORT=1",
                    "-DCAPSTONE_ARM64_SUPPORT=1",
                    "-DCAPSTONE_BUILD_SHARED=OFF",
                    "-DCAPSTONE_BUILD_TESTS=OFF",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "capstone"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_xed(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  # out of source builds are not supported, so we'll have to build
  # inside the source directory
  xed_source_folder = download_github_source_archive("intelxed", "xed")
  if xed_source_folder is None:
    return False

  mbuild_source_folder = download_github_source_archive("intelxed", "mbuild")
  if mbuild_source_folder is None:
    return False

  env_path = os.path.join("sources", "mbuild", "mbuild", "env.py")
  patch_file(env_path, "mbuild")

  python_executable = get_python_path(2)
  if python_executable is None:
    return False

  mbuild_script = [python_executable, "mfile.py", "install"]
  if debug:
    mbuild_script.append("--debug")

  if not run_program("Building...", mbuild_script, xed_source_folder, verbose=verbose_output):
    return False

  print(" > Installing...")
  kit_folder_name = "xed-install-base-" + time.strftime("%Y-%m-%d") + "-"

  if sys.platform == "linux" or sys.platform == "linux2":
    kit_folder_name += "lin"

  elif sys.platform == "darwin":
    kit_folder_name += "mac"

  elif sys.platform == "win32" or sys.platform == "cygwin":
    kit_folder_name += "win"

  else:
    print(" x Failed to determine the kit name")
    return False

  kit_folder_name += "-{}".format(platform.machine())
  kit_folder_path = os.path.realpath(os.path.join("sources", "xed", "kits", kit_folder_name))

  try:
    copy_tree(kit_folder_path, os.path.join(repository_path, "xed"))
  except:
    print(" x Failed to install the XED library")
    return False

  return True

def common_installer_gflags(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("gflags", "gflags")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "gflags")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False


  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "gflags"),
                    "-DCMAKE_CXX_STANDARD=11",
                    "-DGFLAGS_BUILD_TESTING=OFF",
                    "-DGFLAGS_BUILD_SHARED_LIBS=OFF",
                    "-DGFLAGS_BUILD_STATIC_LIBS=ON",
                    "-DGFLAGS_NAMESPACE=google",
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_googletest(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("google", "googletest")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "googletest")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "googletest"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_protobuf(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  version = "2.6.1"
  url = "https://github.com/google/protobuf/archive/v" + version + ".tar.gz"

  source_tarball_path = download_file(url, "sources")
  if source_tarball_path is None:
    return False

  if not extract_archive(source_tarball_path, "sources"):
    return False

  source_folder = os.path.realpath(os.path.join("sources", "protobuf-" + version))

  # this version is too old and doesn't support cmake out of the box
  # so we need to use an external project
  try:
    copy_tree(os.path.join("cmake", "protobuf_project"), os.path.join(source_folder, "cmake"))
    print(" > Copying the CMake project...")

  except:
    print(" x Failed to copy the CMake project")
    return False

  build_folder = os.path.join("build", "protobuf")
  if not os.path.isdir(build_folder):
    try:
      os.makedirs(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DPROTOBUF_ROOT=" + source_folder,
                    "-DBUILD_SHARED_LIBS=False",
                    "-Dprotobuf_BUILD_TESTS=False",
                    "-Dprotobuf_WITH_ZLIB=False",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "protobuf"),
                    os.path.join(source_folder, "cmake")]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  if sys.platform == "win32" or sys.platform == "cygwin":
    protoc_executable = "protoc.exe"
    module_folder = "lib"
    os.environ["PATH"] = os.path.join(repository_path, "protobuf", "lib") + ":" + os.environ["PATH"]

  else:
    os.environ["LIBRARY_PATH"] = os.path.join(repository_path, "protobuf", "lib")
    os.environ["LD_LIBRARY_PATH"] = os.environ["LIBRARY_PATH"]

    protoc_executable = "protoc"
    if sys.platform == "linux" or sys.platform == "linux2":
      module_folder = "lib.linux-{}-{}.{}".format(platform.machine(), sys.version_info.major, sys.version_info.minor)
    else:
      module_folder = "lib"

  os.environ["PROTOC"] = os.path.realpath(os.path.join(repository_path, "protobuf", "bin", protoc_executable))
  python_command = [get_python_path(2), "setup.py", "build"]
  if not run_program("Building the Python module...", python_command, os.path.join(source_folder, "python"), verbose=verbose_output):
    return False

  try:
    print(" > Copying the Python module...")
    python_package = os.path.realpath(os.path.join("sources", "protobuf-" + version, "python", "build", module_folder, "google"))
    copy_tree(python_package, os.path.join(repository_path, "protobuf", "python"))

  except:
    print(" x Failed to copy the Python module")
    return False

  return True

def common_installer_capnproto(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("capnproto", "capnproto")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "capnproto")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DCMAKE_CXX_EXTENSIONS=ON",
                    "-DBUILD_TESTING=OFF",
                    "-DEXTERNAL_CAPNP=OFF",
                    "-DCAPNP_LITE=OFF",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "capnproto"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True