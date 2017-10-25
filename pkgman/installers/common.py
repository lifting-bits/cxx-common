import shutil

from utils import *
from distutils import spawn
from distutils.dir_util import copy_tree

def get_python_path(version):
  # some distributions have choosen to set python 3 as the default version
  # always request the exact executable name first
  if version != 2 and version != 3:
    return None

  path = spawn.find_executable("python" + str(version))
  if path is not None:
    return path

  path = spawn.find_executable("python")
  if path is not None:
    return path

  return None

def common_installer_glog(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DBUILD_TESTING=OFF",
                    "-DWITH_GFLAGS=OFF",
                    "-DCMAKE_EXE_LINKER_FLAGS=-g",
                    "-DCMAKE_C_FLAGS=-g",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "glog"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_capstone(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

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

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_EXE_LINKER_FLAGS=-g",
                    "-DCMAKE_C_FLAGS=-g",
                    "-DCAPSTONE_ARM_SUPPORT=1",
                    "-DCAPSTONE_ARM64_SUPPORT=1",
                    "-DCAPSTONE_BUILD_SHARED=OFF",
                    "-DCAPSTONE_BUILD_TESTS=OFF",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "capstone"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + ["--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_xed(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  # out of source builds are not supported, so we'll have to build
  # inside the source directory
  xed_source_folder = download_github_source_archive("intelxed", "xed")
  if xed_source_folder is None:
    return False

  mbuild_source_folder = download_github_source_archive("intelxed", "mbuild")
  if mbuild_source_folder is None:
    return False

  python_executable = get_python_path(2)
  if python_executable is None:
    return False
  
  mbuild_script = [python_executable, "mfile.py",
                   "--prefix=" + os.path.join(repository_path, "xed")]
  if debug:
    mbuild_script.append("--debug")

  if not run_program("Building and installing...", mbuild_script, xed_source_folder, verbose=verbose_output):
    return False

  return True

def common_installer_gflags(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("gflags", "gflags")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "gflags")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False


  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "gflags"),
                    "-DCMAKE_CXX_STANDARD=11",
                    "-DGFLAGS_BUILD_TESTING=OFF",
                    "-DGFLAGS_BUILD_SHARED_LIBS=OFF",
                    "-DGFLAGS_BUILD_STATIC_LIBS=ON",
                    "-DGFLAGS_NAMESPACE=google",
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_googletest(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("google", "googletest")
  if source_folder is None:
    return False

  build_folder = os.path.join("build", "googletest")
  if not os.path.isdir(build_folder):
    try:
      os.mkdir(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DCMAKE_CXX_STANDARD=11",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "googletest"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True

def common_installer_protobuf(properties):
  repository_path = properties["repository_path"]
  verbose_output = properties["verbose"]
  debug = properties["debug"]

  source_folder = download_github_source_archive("google", "protobuf")
  if source_folder is None:
    return False

  source_folder = os.path.realpath(os.path.join(source_folder, "cmake"))

  # protobuf does not support out of source builds!
  build_folder = os.path.join("sources", "protobuf", "cmake", "build", "release")
  if not os.path.isdir(build_folder):
    try:
      os.makedirs(build_folder)

    except:
      print(" x Failed to create the build folder")
      return False

  cmake_command = ["cmake"] + get_env_compiler_settings() + get_cmake_build_type(debug)
  cmake_command += ["-DBUILD_SHARED_LIBS=False",
                    "-Dprotobuf_BUILD_TESTS=False",
                    "-Dprotobuf_WITH_ZLIB=False",
                    "-DCMAKE_INSTALL_PREFIX=" + os.path.join(repository_path, "protobuf"),
                    source_folder]

  if not run_program("Configuring...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", "."] + get_cmake_build_configuration(debug) + [ "--", get_parallel_build_options()]
  if not run_program("Building...", cmake_command, build_folder, verbose=verbose_output):
    return False

  cmake_command = ["cmake", "--build", ".", "--target", "install"]
  if not run_program("Installing...", cmake_command, build_folder, verbose=verbose_output):
    return False

  return True
