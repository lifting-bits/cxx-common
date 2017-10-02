import os
import multiprocessing

from utils import *

def common_installer_cmake(repository_path):
  version = "3.9.3"
  url = "https://github.com/Kitware/CMake/archive/v" + version + ".tar.gz"

  source_tarball_path = download_file(url, "sources")
  if source_tarball_path is None:
    return False

  if not extract_archive(source_tarball_path, "build"):
    return False

  source_folder = os.path.join("build", "CMake-" + version)
  destination_path = os.path.join(repository_path, "cmake")

  if not run_program("Running the bootstrap script...", ["./bootstrap", "--prefix=" + destination_path], source_folder):
    return False

  if not run_program("Building the source code...", ["make", "-j" + str(multiprocessing.cpu_count())], source_folder):
    return False

  if not run_program("Installing...", ["make", "install"], source_folder):
    return False

  return True
