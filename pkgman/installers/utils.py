import urllib
import os
import sys
import tarfile
import zipfile
import shutil
import subprocess
import tempfile

def download_to_file(url, destination):
  try:
    urllib.urlretrieve(url, destination)
    return True

  except:
    return False

def download_file(url, folder, output_file=None):
  print(" > Downloading file: '" + url + "'")

  if output_file is not None:
    destination = os.path.join(folder, output_file)
  else:
    destination = os.path.join(folder, url.split("/")[-1])

  if os.path.isfile(destination) :
    return destination

  if not download_to_file(url, destination):
    print(" x Download failed")
    return None

  return destination

def download_github_source_archive(organization, repository, format="tar.gz", branch="master"):
  url = "https://codeload.github.com/" + organization + "/" + repository + "/" + format + "/" + branch

  base_file_name = repository + "-" + branch
  tarball_path = os.path.join("sources", base_file_name + "." + format)

  if not os.path.isfile(tarball_path):
    temp_path = download_file(url, "sources")
    if temp_path is None:
      return None

    try:
      print(" > Renaming the tarball file...")
      shutil.move(temp_path, tarball_path)

    except:
      print(" > Failed to rename the tarball file")
      return None

  else:
    print(" > " + organization + "/" + repository + " has already been downloaded")

  source_folder = os.path.realpath(os.path.join("sources", repository))
  if not os.path.isdir(source_folder):
    if not extract_archive(tarball_path, "sources"):
      return None

    try:
      shutil.move(os.path.join("sources", base_file_name), source_folder)
    except:
      print(" x Failed to rename the " + base_file_name + " folder")
      return None

  else:
    print(" > The source folder for " + repository + " already exists")

  return os.path.realpath(source_folder)

def extract_tarball(path, folder):
  try:
    tarball = tarfile.open(path)
    tarball.extractall(path=folder)
    tarball.close()
    return True

  except:
    return False

def extract_zip(path, folder):
  try:
    zip_file = zipfile.ZipFile(path, "r")
    zip_file.extractall(folder)
    zip_file.close()
    return True

  except:
    return False

def extract_archive(path, folder):
  print(" > Extracting: '" + path + "' in '" + folder + "'...")

  succeeded = False
  if ".tar.gz" in path:
    succeeded = extract_tarball(path, folder)
  elif ".zip" in path:
    succeeded = extract_zip(path, folder)
  else:
    print(" x Unsupported archive type")
    return False

  if not succeeded:
    print(" x Extraction failed")
    os.remove(path)
    return False

  return True

def install_folder(path, destination):
  print(" > Installing folder '" + path + "'...")

  try:
    shutil.copytree(path, destination)
    return True

  except:
    print(" x Installation has failed")
    return False

def run_program(description, command, working_directory):
  print(" > " + description)

  try:
    log_file = tempfile.NamedTemporaryFile(delete=True)
    exit_code = subprocess.call(command, cwd=working_directory, stdout=log_file, stderr=subprocess.STDOUT)
    log_file.flush()

    if exit_code == 0:
      return True

    log_file.seek(0)
    log_contents = log_file.read()
    log_file.close()
   
    print(" x The command has exited with error code " + str(exit_code) + "\n")
    print("===\n")
    print(log_contents)
    print("===\n")

    return False

  except:
    print(" x Failed to start the command")
    return False
