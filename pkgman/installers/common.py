import shutil
from utils import *

def common_installer_xed(properties):
  repository_path = properties["repository_path"]

  xed_url = "https://codeload.github.com/intelxed/xed/zip/master"
  mbuild_url = "https://codeload.github.com/intelxed/mbuild/zip/master"

  xed_zip_path = os.path.join("sources", "xed-master.zip")

  if not os.path.isfile(xed_zip_path):
    zip_path = download_file(xed_url, "sources")
    if zip_path is None:
      return False

    try:
      print(" > Renaming the zip file...")
      shutil.move(zip_path, xed_zip_path)

    except:
      print(" > Failed to rename the zip file")
      return False

  else:
    print(" > XED already downloaded")
    
  mbuild_zip_path = os.path.join("sources", "mbuild-master.zip")

  if not os.path.isfile(mbuild_zip_path):
    zip_path = download_file(mbuild_url, "sources")
    if zip_path is None:
      return False

    try:
      print(" > Renaming the zip file...")
      shutil.move(zip_path, mbuild_zip_path)

    except:
      print(" > Failed to rename the zip file")
      return False

  else:
    print(" > mbuild already downloaded")

  if not os.path.isdir(os.path.join("build", "xed")):
    if not extract_archive(xed_zip_path, "build"):
      return False

    try:
      shutil.move(os.path.join("build", "xed-master"), os.path.join("build", "xed"))
    except:
      print(" x Failed to rename the XED folder")
      return False

  else:
    print(" > The build folder for XED already exists")

  if not os.path.isdir(os.path.join("build", "mbuild")):
    if not extract_archive(mbuild_zip_path, "build"):
      return False

    try:
      shutil.move(os.path.join("build", "mbuild-master"), os.path.join("build", "mbuild"))
    except:
      print(" x Failed to rename the XED folder")
      return False

  else:
    print(" > The build folder for mbuild already exists")

  xed_folder = os.path.join("build", "xed")
  if not run_program("Building and installing...", ["python", "mfile.py", "--prefix=" + os.path.join(repository_path, "xed")], xed_folder):
    return False

  return False
