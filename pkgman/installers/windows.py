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

import shutil
from utils import *

def windows_installer_cmake(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  if debug:
    print(" ! Debug build not supported on Windows")

  version = "3.9.3"
  url = "https://cmake.org/files/v3.9/cmake-" + version + "-win64-x64.zip"

  zip_path = download_file(url, "sources")
  if zip_path is None:
    return False

  if not extract_archive(zip_path, "build"):
    return False

  binary_folder = os.path.join("build", "cmake-" + version + "-win64-x64")
  destination_path = os.path.join(repository_path, "cmake")

  return install_folder(binary_folder, destination_path)

def windows_installer_llvm(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  if debug:
    print(" ! Debug build not supported on Windows")

  program_files_folder = os.environ["ProgramFiles(x86)"]
  llvm_install_folder = os.path.join(program_files_folder, "LLVM")
  if os.path.isdir(llvm_install_folder):
    print(" > Found an existing LLVM installation")

    llvm_uninstaller_path = os.path.join(llvm_install_folder, "Uninstall.exe")
    if not os.path.isfile(llvm_uninstaller_path):
      print(" x Could not find the LLVM uninstaller!")
      return False

    if not run_program("Uninstalling the existing LLVM installation...", [llvm_uninstaller_path, "/S"], llvm_install_folder, verbose=verbose_output):
      return False

  installer_name = "LLVM-" + properties["long_llvm_version"] + "-win32.exe"
  url = "http://releases.llvm.org/" + properties["long_llvm_version"] + "/" + installer_name

  installer_path = download_file(url, "temp", installer_name)
  if installer_path is None:
    return False

  if not run_program("Installing...", [installer_path, "/S"], "temp", verbose=verbose_output):
    return False

  return False
