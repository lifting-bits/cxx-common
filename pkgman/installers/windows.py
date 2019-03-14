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

  version = "3.10.2"

  version_components = version.split(".")
  short_version = "v" + version_components[0] + "." + version_components[1]

  url = "https://cmake.org/files/" + short_version + "/cmake-" + version + "-win64-x64.zip"

  zip_path = download_file(properties, url, "sources")
  if zip_path is None:
    return False

  if not extract_archive(zip_path, "build"):
    return False

  binary_folder = os.path.join("build", "cmake-" + version + "-win64-x64")
  destination_path = os.path.join(repository_path, "cmake")

  return install_folder(binary_folder, destination_path)
