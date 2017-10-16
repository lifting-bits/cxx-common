import shutil
from utils import *

def common_installer_glog(properties):
  repository_path = properties["repository_path"]

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

  cmake_command = ["cmake",
                   "-DCMAKE_CXX_STANDARD=11",
                   "-DCMAKE_BUILD_TYPE=Release",
                   "-DBUILD_TESTING=OFF",
                   "-DWITH_GFLAGS=OFF",
                   "-DCMAKE_EXE_LINKER_FLAGS=-g",
                   "-DCMAKE_C_FLAGS=-g",
                   "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "glog"),
                   source_folder]

  if not run_program("Configuring...", cmake_command, build_folder):
    return False

  cmake_command = ["cmake", "--build", "."]
  if not run_program("Building...", cmake_command, build_folder):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder):
    return False

  return True

def common_installer_capstone(properties):
  repository_path = properties["repository_path"]

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

  cmake_command = ["cmake",
                   "-DCMAKE_EXE_LINKER_FLAGS=-g",
                   "-DCMAKE_C_FLAGS=-g",
                   "-DCAPSTONE_ARM_SUPPORT=1",
                   "-DCAPSTONE_ARM64_SUPPORT=1",
                   "-DCAPSTONE_BUILD_SHARED=OFF",
                   "-DCAPSTONE_BUILD_TESTS=OFF",
                   "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "capstone"),
                   source_folder]

  if not run_program("Configuring...", cmake_command, build_folder):
    return False

  cmake_command = ["cmake", "--build", "."]
  if not run_program("Building...", cmake_command, build_folder):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder):
    return False

  return True

def common_installer_xed(properties):
  repository_path = properties["repository_path"]

  # out of source builds are not supported, so we'll have to build
  # inside the source directory
  xed_source_folder = download_github_source_archive("intelxed", "xed")
  if xed_source_folder is None:
    return False

  mbuild_source_folder = download_github_source_archive("intelxed", "mbuild")
  if mbuild_source_folder is None:
    return False
  
  mbuild_script = ["python", "mfile.py",
                   "--prefix=" + os.path.join(repository_path, "xed")]

  if not run_program("Building and installing...", mbuild_script, xed_source_folder):
    return False

  return True
