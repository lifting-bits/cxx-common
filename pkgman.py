#!/usr/bin/env python2

import argparse
import sys
import os
import platform
import types
import inspect
import importlib

from distutils.dir_util import copy_tree

installer_modules = []
for module_name in ["unix", "windows", "common"]:
  module = importlib.import_module("pkgman.installers." + module_name)
  installer_modules.append(module)

def main():
  package_list = get_package_list()

  # parse the command line
  if sys.platform == "win32":
    default_llvm_version=501
  else:
    default_llvm_version=900

  arg_parser = argparse.ArgumentParser(description="This utility is used to build common libraries for various Trail of Bits products.")
  arg_parser.add_argument("--llvm_version", type=int, help="LLVM version, specified as a single integer (i.e.: 352, 380, 390, 401, ...).", default=default_llvm_version)
  arg_parser.add_argument("--additional_paths", type=str, help="A list of (comma separated) paths to use when looking for commands.")
  arg_parser.add_argument('--verbose', help="True if the script should print to stdout the compilation output. Useful to prevent Travis from timing out due to inactivity.", action='store_true')
  arg_parser.add_argument('--debug', help="Build debug versions.", action='store_true')

  arg_parser.add_argument("--cxx_compiler", type=str, help="The C++ compiler to use.")
  arg_parser.add_argument("--c_compiler", type=str, help="The C compiler to use.")
  arg_parser.add_argument("--exclude_libcxx", help="Exclude libc++ from the build", action='store_true')
  arg_parser.add_argument("--use_no_ssl_requests", help="Use the requests library to download files, and do so without SSL verification. If behind a firewall/proxy, this can help", action='store_true')

  default_repository_path = ""
  if get_platform_type() == "windows":
    default_repository_path = "C:\\TrailOfBits\\libraries"
  else:
    default_repository_path = "/opt/trailofbits";

  arg_parser.add_argument("--repository_path", type=str, help="This is where the repository is installed", default=default_repository_path)

  package_list_description = "The packages to build, separated by commas. Available packages: " + str(package_list)
  arg_parser.add_argument("--packages", type=str, help=package_list_description, required=True)

  args = arg_parser.parse_args()

  print("Build type:"),
  if args.debug:
    print("Debug")
  else:
    print("Release")

  print("Platform type:"),
  print(get_platform_type())

  # update the PATH environment variable; this is done here to work around a Travis issue
  if args.additional_paths is not None:
    print("Updating the PATH environment...")

    for path in args.additional_paths.split(","):
      os.environ["PATH"] = path + ":" + os.environ["PATH"]
  
  # set the compilers
  if args.c_compiler is not None:
    print("Setting the C compiler: " + args.c_compiler)
    os.environ["CMAKE_C_COMPILER"] = args.c_compiler

  if args.cxx_compiler is not None:
    print("Setting the C++ compiler: " + args.cxx_compiler)
    os.environ["CMAKE_CXX_COMPILER"] = args.cxx_compiler
  
  # acquire the package list
  packages_to_install = args.packages.split(",")

  for package in packages_to_install:
    if package not in package_list:
      print("Invalid package: " + package)
      return False

  # get the llvm version
  llvm_version = str(args.llvm_version)
  if len(llvm_version) < 3:
    print("Invalid LLVM version: " + str(llvm_version))
    return False

  properties = dict()
  properties["cxx_common_dir"] = os.path.dirname(os.path.abspath(__file__))
  properties["llvm_version"] = llvm_version
  properties["long_llvm_version"] = llvm_version[0:-2] + "." + llvm_version[-2] + "." + llvm_version[-1]
  properties["repository_path"] = args.repository_path
  properties["verbose"] = args.verbose
  properties["debug"] = args.debug

  # Make sure that file downloading will work.
  if args.use_no_ssl_requests:
    properties["use_requests_for_downloading"] = True
    try:
      import requests
    except ImportError:
      print(" ! Unable to import `requests`; try `pip install requests`")
      return False
  else:
    properties["use_requests_for_downloading"] = False
  
  properties["include_libcxx"] = not args.exclude_libcxx

  # print a summary of what we are about to do
  print("Repository path: " + args.repository_path)

  if "llvm" in packages_to_install:
    if sys.platform == "win32":
      supported_llvm_version_list = [501]
    else:
      supported_llvm_version_list = [352, 362, 371, 381, 391, 401, 500, 501, 600, 601, 700, 800, 900, 901, 1000]

    if int(llvm_version) < 501:
      if not os.path.isfile("/usr/include/xlocale.h") and not args.exclude_libcxx:        
        print("===")
        print("The 'xlocale.h' include file is missing.")
        print("If you are using Ubuntu <= 16.04.5 LTS then you can install")
        print("the libc6-dev package to fix the error. If you are on a more")
        print("recent distribution, this include header has been deprecated.")
        print("Consider building LLVM >= 5.0.1 instead. If your build doesn't")
        print("work then consider also trying with --exclude_libcxx")
        print("===")

        raw_input("Press return to continue or CTRL-C to abort")

    print("LLVM version: " + llvm_version),
    if args.llvm_version not in supported_llvm_version_list:
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

  cmake_modules_folder = os.path.join(properties["repository_path"], "cmake_modules")
  try:
    print("Installing the CMake modules...")
    cmake_modules_dir = os.path.join(properties["cxx_common_dir"], "cmake_modules")
    copy_tree(cmake_modules_dir, os.path.join(properties["repository_path"], "cmake_modules"))

  except:
    import traceback
    print(traceback.format_exc())
    print(" x Failed to copy the CMake modules")
    return False

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

if __name__ == "__main__":
  if not main():
    sys.exit(1)

  sys.exit(0)
