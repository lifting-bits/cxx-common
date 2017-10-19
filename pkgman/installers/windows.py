import shutil
from utils import *

def windows_installer_cmake(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]

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
  llvm_version = ""

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

  short_llvm_vers = str(properties["llvm_version"])
  if len(short_llvm_vers) != 2:
    print(" x Invalid LLVM version")
    return True

  for char in short_llvm_vers:
    if len(llvm_version) > 0:
      llvm_version += "."

    llvm_version += char

  llvm_version += ".0"
  installer_name = "LLVM-" + llvm_version + "-win32.exe"
  url = "http://releases.llvm.org/" + llvm_version + "/" + installer_name

  installer_path = download_file(url, "temp", installer_name)
  if installer_path is None:
    return False

  if not run_program("Installing...", [installer_path, "/S"], "temp", verbose=verbose_output):
    return False

  return False
