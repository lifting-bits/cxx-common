#!/usr/bin/env python2

import argparse
import sys
import os
import platform
import types
import inspect
import importlib

installer_modules = []
for module_name in ["linux", "windows", "common"]:
  module = importlib.import_module("pkgman.installers." + module_name)
  installer_modules.append(module)

def main():
  package_list = get_package_list()

  # parse the command line
  arg_parser = argparse.ArgumentParser(description="This utility is used to build common libraries for various Trail of Bits products.")
  arg_parser.add_argument("--llvm_version", type=int, help="LLVM version, specified as a single integer (i.e.: 38, 39, 40, ...)", default=40)

  default_repository_path = ""
  if get_platform_type() == "windows":
    default_repository_path = "C:\\TrailOfBits\\libraries"
  else:
    default_repository_path = os.path.join("/opt/trailofbits/libraries")

  arg_parser.add_argument("--repository_path", type=str, help="This is where the repository is installed", default=default_repository_path)

  package_list_description = "The packages to build, separated by commas. Available packages: " + str(package_list)
  arg_parser.add_argument("--packages", type=str, help=package_list_description, required=True)

  args = arg_parser.parse_args()

  # acquire the package list
  packages_to_install = args.packages.split(",")

  for package in packages_to_install:
    if package not in package_list:
      print("Invalid package: " + package)
      return False

  # get the llvm version
  llvm_version = str(args.llvm_version)
  if len(llvm_version) != 2:
    print("Invalid LLVM version: " + str(llvm_version))
    return False

  properties = dict()
  properties["llvm_version"] = llvm_version
  properties["repository_path"] = args.repository_path

  # print a summary of what we are about to do
  print("Repository path: " + args.repository_path)

  print("LLVM version: " + llvm_version),
  if args.llvm_version < 36 or args.llvm_version >= 50:
    print("(unsupported)")
  else:
    print("(supported)")

  print("Package list: " + str(packages_to_install) + "\n")

  # build each package
  if not os.path.exists("sources"):
    os.makedirs("sources")

  if not os.path.exists("temp"):
    os.makedirs("temp")

  if not os.path.exists("build"):
    os.makedirs("build")

  for package in packages_to_install:
    print(package)

    package_installer = get_package_installer(package)
    if package_installer is None:
      print(" x The package installer procedure is missing")
      continue

    if not package_installer(properties):
      print(" x Exiting due to failure")
      return False

    print(" > Done!\n")

  return True

def get_package_list():
  """
  Returns the available package list, depending on the current system
  """

  package_list = []

  for module in installer_modules:
    packages = get_module_package_list(module)
    package_list += packages

  return package_list

def get_module_package_list(module):
  package_list = []
  package_installer_prefixes = [get_platform_type() + "_installer_", "common_installer_"]

  module_functions = inspect.getmembers(module, inspect.isfunction)
  for function in module_functions:
    function_name = function[0]

    package_name = ""
    for prefix in package_installer_prefixes:
      if function_name.startswith(prefix):
        package_name = function_name[len(prefix):]

    if not package_name:
      continue

    if package_name in package_list:
      print("ERROR: The following package has more than one installer: " + package_name)
      sys.exit(1)

    package_list.append(package_name)

  return package_list

def get_package_installer(package_name):
  """
  Returns the specified package installer
  """

  system_name = get_platform_type()
  if system_name == None:
    return None

  prefixes = [system_name, "common"]
  for prefix in prefixes:
    function_name = prefix + "_installer_" + package_name

    for module in installer_modules:
      try:
        function = getattr(module, function_name)
        return function

      except:
        pass

  return None

def get_platform_type():
  """
  Returns the platform type (linux, windows, macos or None in case of error)
  """

  if sys.platform == "linux" or sys.platform == "linux2":
    return "linux"

  elif sys.platform == "darwin":
    return "macos"

  elif sys.platform == "win32" or sys.platform == "cygwin":
    return "windows"

  else:
    return None

  name = distribution_info[0]
  if not name:
    return None

  return name

if __name__ == "__main__":
  if not main():
    sys.exit(1)

  sys.exit(0)
