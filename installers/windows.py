import shutil
from utils import *

def windows_installer_cmake(properties):
  repository_path = properties["repository_path"]

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
