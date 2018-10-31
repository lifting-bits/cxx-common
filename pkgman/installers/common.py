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
import glob
import subprocess

from utils import *
from distutils import spawn
from distutils.dir_util import copy_tree

PATCHES_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "patches")

def patch_file(file_path, patch_name):
  if sys.platform == "win32":
    patch_executable = spawn.find_executable("patch.exe")
    if patch_executable is None:
      patch_executable = os.path.join(os.environ["ProgramFiles"], "Git", "usr", "bin", "patch.exe")
      if not os.path.exists(patch_executable):
        print " x The patch.exe executable could not be found"
        print " i Install Git for Windows to solve this error"

        return False

  else:
    patch_executable = "patch"

  patch_path = os.path.join(PATCHES_DIR, "{}.patch".format(patch_name))
  if not os.path.exists(patch_path):
    print(" x Failed to find patch file {}".format(patch_name))
    return False

  if not run_program("Patching {}".format(file_path), [patch_executable, file_path, patch_path], os.getcwd()):
    return False

  return True

def get_python_path(version):
  # some distributions have choosen to set python 3 as the default version
  # always request the exact executable name first

  if version == 2:
    return sys.executable

  elif version == 3:
    extension = ""
    if sys.platform == "win32":
      extension = ".exe"

    path = spawn.find_executable("python" + str(version) + extension)
    if path is not None:
      return path

    path = spawn.find_executable("python" + extension)
    if path is not None:
      return path

    return None

  else:
    return None

def google_installer_glog(properties):
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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator()
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DBUILD_TESTING=OFF",
                    "-DWITH_GFLAGS=OFF",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=True",
                    "-DCMAKE_EXE_LINKER_FLAGS=-g",
                    "-DCMAKE_C_FLAGS=-g",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "glog"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator()
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

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_xed(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  xed_source_folder = os.path.join("sources", "xed")
  if os.path.isdir(xed_source_folder):
    shutil.rmtree(xed_source_folder)

  mbuild_source_folder = os.path.join("sources", "mbuild")
  if os.path.isdir(mbuild_source_folder):
    shutil.rmtree(mbuild_source_folder)

  # out of source builds are not supported, so we'll have to build
  # inside the source directory
  xed_source_folder = download_github_source_archive("intelxed", "xed")
  if xed_source_folder is None:
    return False

  mbuild_source_folder = download_github_source_archive("intelxed", "mbuild")
  if mbuild_source_folder is None:
    return False

  env_file_path = os.path.realpath(os.path.join("sources", "mbuild", "mbuild", "env.py"))
  if not patch_file(env_file_path, "mbuild"):
    return False

  python_executable = get_python_path(2)
  if python_executable is None:
    return False

  mbuild_script = [python_executable, "mfile.py", "install", "--extra-flags=-fPIC"]
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

  kit_folder_name += "-{}".format("x86-64")
  kit_folder_path = os.path.realpath(os.path.join("sources", "xed", "kits", kit_folder_name))

  try:
    copy_tree(kit_folder_path, os.path.join(repository_path, "xed"))
  except Exception as e:
    print(" x Failed to install the XED library: {}".format(str(e)))
    return False

  return True

def google_installer_gflags(properties):
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


  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator()
  cmake_command += ["-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "gflags"),
                    "-DCMAKE_CXX_STANDARD=11",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=True",
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

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def google_installer_googletest(properties):
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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator(False)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=True",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "googletest"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_google(properties):
  if not google_installer_gflags(properties):
    return False

  print ""
  if not google_installer_glog(properties):
    return False

  print ""
  if not google_installer_googletest(properties):
    return False

  print ""
  if not google_installer_protobuf(properties):
    return False

  return True

def google_installer_protobuf(properties):
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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator(False)
  cmake_command += ["-DPROTOBUF_ROOT=" + source_folder,
                    "-DBUILD_SHARED_LIBS=False",
                    "-Dprotobuf_BUILD_TESTS=False",
                    "-DCMAKE_POSITION_INDEPENDENT_CODE=True",
                    "-Dprotobuf_WITH_ZLIB=False",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "protobuf"),
                    os.path.join(source_folder, "cmake")]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + get_cmake_generator()
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

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_llvm(properties):
  if sys.platform == "darwin":
    if not os.path.exists("/usr/include/stdio.h"):
      print(" ! Can't find /usr/include directory; please run the following command: ")
      print(" !     xcode-select --install && sudo installer -pkg /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg -target /")
      print(" x Compiling clang failed.")
      return False

  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  llvm_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/llvm-" + properties["long_llvm_version"] + ".src.tar.xz"
  llvm_tarball_name = "llvm-" + str(properties["llvm_version"]) + ".tar.xz"

  clang_tarball_url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/cfe-" + properties["long_llvm_version"] + ".src.tar.xz"
  clang_tarball_name = "clang-" + str(properties["llvm_version"]) + ".tar.xz"

  if sys.platform != "win32":
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

  if sys.platform != "win32":
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

  if sys.platform != "win32":
    if not extract_archive(libcxx_tarball_path, "sources"):
      return False

    if not extract_archive(libcxxabi_tarball_path, "sources"):
      return False

  llvm_root_folder = os.path.realpath(os.path.join("sources", "llvm-" + str(properties["long_llvm_version"] + ".src")))

  try:
    print(" > Moving the project folders in the LLVM source tree...")

    if sys.platform != "win32":
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

  arch_list = "'X86"
  if sys.platform != "win32":
    arch_list += ";AArch64"
  arch_list += "'"

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug) + ["-DCMAKE_INSTALL_PREFIX=" + destination_path,
                                                                                           "-DCMAKE_CXX_STANDARD=11",
                                                                                           "-DLLVM_TARGETS_TO_BUILD=" + arch_list,
                                                                                           "-DLLVM_ENABLE_RTTI=ON",
                                                                                           "-DLLVM_ENABLE_PIC=ON",
                                                                                           "-DLLVM_ENABLE_THREADS=ON",
                                                                                           "-DLLVM_BUILD_EXAMPLES=OFF",
                                                                                           "-DLLVM_INCLUDE_EXAMPLES=OFF",
                                                                                           "-DLLVM_BUILD_TESTS=OFF",
                                                                                           "-DLLVM_INCLUDE_TESTS=OFF",
                                                                                           "-DLLVM_OPTIMIZED_TABLEGEN=ON",
                                                                                           "-DLLVM_BUILD_DOCS=OFF",
                                                                                           "-DLLVM_ENABLE_DOXYGEN=OFF",
                                                                                           "-DLLVM_DOXYGEN_SVG=OFF",
                                                                                           "-DLLVM_ENABLE_SPHINX=OFF",
                                                                                           "-DSPHINX_OUTPUT_HTML=OFF",
                                                                                           "-DSPHINX_OUTPUT_MAN=OFF",]

  if sys.platform != "win32":
    if int(properties["llvm_version"]) < 371:
      cmake_command += ["-DLIBCXX_ENABLE_SHARED=NO"]
    else:
      cmake_command += ["-DLIBCXX_ENABLE_STATIC=YES",
                        "-DLIBCXX_ENABLE_SHARED=YES",
                        "-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=NO",
                        "-LIBCXX_INCLUDE_BENCHMARKS=NO"]

  cmake_command += [llvm_root_folder] + get_cmake_generator()

  if not run_program("Configuring...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] +  get_cmake_build_configuration(debug) + ["--target", "install"]
  if not run_program("Installing...", cmake_command, llvm_build_path, verbose=verbose_output):
    return False

  return True
