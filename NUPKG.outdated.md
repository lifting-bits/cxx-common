# WARNING OLD and UNTESTED

Proceed with caution as this likely won't work exactly anymore.

# Dependency Management for Lifting-Bits

This repo contains scripts and custom packaging definitions for dependencies used by the `lifting-bits` organization.

The aim is to make dependency management easier and more reproducible by using [vcpkg](https://github.com/microsoft/vcpkg) to build and find the required libraries.

Currently, we try to support pre-built `Release` build-type libraries for OSX and Linux Ubuntu 18.04 and 20.04.

# Table of Contents

* [How to use](#how-to-use)
  * [Required system dependencies](#required-system-dependencies)
  * [Bootstrap and pull pre\-built dependencies natively](#bootstrap-and-pull-pre-built-dependencies-natively)
    * [Example: Building remill](#example-building-remill)
  * [Download pre\-built dependency bundle](#download-pre-built-dependency-bundle)
    * [Example: Building remill](#example-building-remill-1)
  * [Building it ALL from source](#building-it-all-from-source)
  * [Using Docker Image](#using-docker-image)
* [Common Issues](#common-issues)
  * [Packages aren't being found in NuGet](#packages-arent-being-found-in-nuget)

# How to use

If you want to download pre-built dependencies, you'll need to generate a [GitHub Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token). The permissions only require `read:packages` to download. Note the generated token, as you'll be using it where you see `GITHUB_TOKEN`.

## Required system dependencies

[Mono](https://www.mono-project.com/) is required for fetching pre-built packages from NuGet.

Linux (Ubuntu):

* `clang-10` is used as the compiler in CI and should be used when building locally if you want to pull down binaries from GitHub that match exactly to your OS/Compiler.

```bash
sudo apt-get update && sudo apt-get install --yes clang-10 lld-10
export CC=clang-10 && export CXX=clang++-10
```

OSX:

* We use the latest available (by Software Update) XCode clang compiler, which is automatically picked up by vcpkg during the build, so as long as you haven't manually overridden the default C and C++ compiler, you should be able to use the libraries built by CI.

## Bootstrap and pull pre-built dependencies natively

If on Ubuntu 18.04 or 20.04, remember to `export CC=clang-10 && export CXX=clang++-10`.

WARNING: This will write your Github token in plain text to `~/.config/NuGet/NuGet.config`.

```bash
./pull_dependencies.sh ${GITHUB_USERNAME} ${GITHUB_TOKEN}
```

If all goes well, and you are running an updated version of Mac OSX 10.15 with default Apple Compiler, and Ubuntu 18.04 or Ubuntu 20.04 with `clang-10` set as `CC` and `CXX`, then you should see that NuGet will find matching, compatible packages to download instead of building everything from source:

**Note:** pre-built libraries are only found while using the `x64-{osx,linux}-rel` vcpkg [triplet](https://vcpkg.readthedocs.io/en/latest/users/triplets/) because `Debug` builds of LLVM are too demanding of the freely available CI runners. See the next section for building all dependencies (both `Release` and `Debug` types) from source.

Sample good output for finding and using pre-built libraries:

```log
[DEBUG] system(/usr/bin/mono /workspace/vcpkg/downloads/tools/nuget-5.5.1-linux/nuget.exe install /workspace/vcpkg/buildtrees/packages.config -OutputDirectory /workspace/vcpkg/packages -Source Source -ExcludeVersion -NoCache -PreRelease -DirectDownload -PackageSaveMode nupkg -Verbosity detailed -ForceEnglishOutput -NonInteractive)
NuGet Version: 5.5.1.6542
Feeds used:
  https://nuget.pkg.github.com/ekilmer/index.json

Restoring NuGet package gflags_x64-linux-rel.2.2.2-0669208ed4e52ac76dcab743cc8159122e35a179.
  GET https://nuget.pkg.github.com/ekilmer/download/gflags_x64-linux-rel/2.2.2-0669208ed4e52ac76dcab743cc8159122e35a179/gflags_x64-linux-rel.2.2.2-0669208ed4e52ac76dcab743cc8159122e35a179.nupkg
  OK https://nuget.pkg.github.com/ekilmer/download/gflags_x64-linux-rel/2.2.2-0669208ed4e52ac76dcab743cc8159122e35a179/gflags_x64-linux-rel.2.2.2-0669208ed4e52ac76dcab743cc8159122e35a179.nupkg 492ms
```

### Example: Building remill

:exclamation: **Still in the root of this repo:** :exclamation:

```bash
git clone --branch vcpkg https://github.com/ekilmer/remill.git
cd remill
mkdir build && cd build
cmake -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DVCPKG_TARGET_TRIPLET=x64-linux-rel \
    -DCMAKE_TOOLCHAIN_FILE="$(pwd)/../../vcpkg/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -G Ninja \
    ..
cmake --build .
cmake --build . --target install
cmake --build . --target test_dependencies
env CTEST_OUTPUT_ON_FAILURE=1 cmake --build . --target test
```

These commands should be repeated in a similar manner for any other lifting-bits repositories.

Change the `-DVCPKG_TARGET_TRIPLET=x64-linux-rel` to `x64-osx-rel` if on MacOS.

**NOTE:** If you don't want to build the tools within this repo, you will need to modify the following line:

```text
-DCMAKE_TOOLCHAIN_FILE="PATH_TO_THIS_REPO/vcpkg/scripts/buildsystems/vcpkg.cmake"
```

## Download pre-built dependency bundle

If you are having trouble getting NuGet to find the correct packages automatically, you may also try to download a zipped archive of the dependencies.

Check out the release artifacts or CI run artifacts for your OS and download the zip corresponding to the LLVM version you'd like. You will need 7zip to extract the contents.

:exclamation: **NOTE:** :exclamation: If you are not using Ubuntu, you can still try to download the artifacts and experiment with whether they work. There are no guarantees that they will work or be stable (even if tests pass). The only way to ensure the best stability is by compiling everything yourself.

### Example: Building remill

Anywhere on your computer:

```bash
git clone --branch vcpkg https://github.com/ekilmer/remill.git
cd remill
mv ~/Downloads/vcpkg_ubuntu-18.04_llvm.7z .
7z x vcpkg_ubuntu-18.04_llvm.7z
mkdir build && cd build
cmake -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DVCPKG_TARGET_TRIPLET=x64-linux-rel \
    -DCMAKE_TOOLCHAIN_FILE="$(pwd)/../vcpkg_ubuntu-18.04_llvm/scripts/buildsystems/vcpkg.cmake" \
    -DCMAKE_INSTALL_PREFIX="$(pwd)/install" \
    -G Ninja \
    ..
cmake --build .
cmake --build . --target install
cmake --build . --target test_dependencies
env CTEST_OUTPUT_ON_FAILURE=1 cmake --build . --target test
```

There is always a chance that some incompatibility with the pre-built libraries has crept in, so please post your errors along with all of your build steps and their outputs.

Or, build everything yourself.

## Building it ALL from source

This is required for Linux distributions other than Ubuntu 18.04, 20.04, and MacOS; _or_ if you don't want to use the `clang-10` compiler to compile the dependencies on Linux.

The build types produced by vcpkg are controlled through triplet files. The `x64-{linux,os}-rel` triplet stands for `64-bit`, `linux` or `mac` system, `Release` build type.

By default, vcpkg will choose a triplet based on your system, however this builds both `Release` and `Debug` builds of all dependencies, including LLVM. Our `x64-{linux-osx}-rel` triplet is not chosen by default, and it is in fact a custom (["overlay"](https://vcpkg.readthedocs.io/en/latest/examples/overlay-triplets-linux-dynamic/)) triplet that is in the `triplets` directory of this repo, therefore, we must specify it manually whenever we use vcpkg.

Interestingly, triplets of different names (and configurations) can exist next to each other! However, if not using the default, you must specify which triplet (_universe_) of dependencies you want to build/link against.

To build everything from source, including both `Release` and `Debug` build types, we can simply run the following (after checkout out the correct version of vcpkg), which should work on any vcpkg-supported OS:

```bash
$ ./vcpkg/bootstrap.sh
$ ./vcpkg/vcpkg install \
  --debug \
  llvm-10 \
  @dependencies.txt
```

Where `@dependencies.txt` is a file that contains pre-populated, unchanging options and packages required to build the lifting tools. Feel free to inspect that file to get a better idea of what is happening.

If you don't want to use the default triplet, specify it with `--triplet my-triplet`.

Then, follow the same exact steps in [building remill](#example-building-remill) when pulling the pre-built dependencies.

## Using Docker Image

If you want to test in a Docker image, run the following to pull dependencies from GitHub NuGet:

```bash
cd docker
docker build -t vcpkg-base -f Dockerfile.vcpkg .
cd ..
docker run --rm -t -i -v "$(pwd):/workspace" \
    -u $(id -u ${USER}):$(id -g ${USER}) \
    vcpkg-base ./pull_dependencies.sh ${GITHUB_USERNAME} ${GITHUB_TOKEN}
```

Note that you should rebuild a fresh Docker image frequently to make sure you obtain the latest versions of the supported system dependencies to better match what is being run in CI.

You could also use the built Docker image and follow any of the other steps to download the built dependency bundle or build everything from source.

# Common Issues

If reading through this doesn't help solve your problem, please open an issue.

## Packages aren't being found in NuGet

Barring any authentication issues, a message like the following means that there is a hash mismatch between CI and your machine:

```log
NuGet Version: 5.5.1.6542
Feeds used:
  https://nuget.pkg.github.com/ekilmer/index.json

Restoring NuGet package gflags_x64-osx-rel.2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff.
  GET https://nuget.pkg.github.com/ekilmer/download/gflags_x64-osx-rel/2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff/gflags_x64-osx-rel.2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff.nupkg
  NotFound https://nuget.pkg.github.com/ekilmer/download/gflags_x64-osx-rel/2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff/gflags_x64-osx-rel.2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff.nupkg 173ms
WARNING: Unable to find version '2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff' of package 'gflags_x64-osx-rel'.
  https://nuget.pkg.github.com/ekilmer/index.json: Package 'gflags_x64-osx-rel.2.2.2-53884e51813100affbbcfbb754b564c1d9b9ddff' is not found on source 'https://nuget.pkg.github.com/ekilmer/index.json'.
```

This could be due to a multitude of things, but you should make sure that you are on the same `vcpkg` commit SHA as CI, this repo is updated, and that you are running the most up-to-date build tools.

Digging through the debug output of `vcpkg` and comparing it a CI run will also help to determine the source of difference. Take a look at this section:

```log
[DEBUG] -- Build files have been written to: /Users/ekilmer/src/vcpkg-lifting-ports/vcpkg/buildtrees/detect_compiler/x64-osx-rel-rel
[DEBUG]
[DEBUG] #COMPILER_HASH#40c9eb093940d44cb6e6c8c0a7250ac20ec886ff
[DEBUG] #COMPILER_C_HASH#a1db5d1638032ae8a49d431642a4ca746775e749
[DEBUG] #COMPILER_C_VERSION#12.0.0.12000032
[DEBUG] #COMPILER_C_ID#AppleClang
[DEBUG] #COMPILER_CXX_HASH#a1db5d1638032ae8a49d431642a4ca746775e749
[DEBUG] #COMPILER_CXX_VERSION#12.0.0.12000032
[DEBUG] #COMPILER_CXX_ID#AppleClang
[DEBUG] CMake Warning:
[DEBUG]   Manually-specified variables were not used by the project:
[DEBUG]
[DEBUG]     BUILD_SHARED_LIBS
[DEBUG]     CMAKE_INSTALL_BINDIR
[DEBUG]     CMAKE_INSTALL_LIBDIR
[DEBUG]     VCPKG_CRT_LINKAGE
[DEBUG]     VCPKG_PLATFORM_TOOLSET
[DEBUG]     VCPKG_SET_CHARSET_FLAG
```

or at a particular package that will list everything that is being hashed:

```log
[DEBUG] Detecting compiler hash for triplet x64-osx-rel: 40c9eb093940d44cb6e6c8c0a7250ac20ec886ff
[DEBUG] <abientries for gflags:x64-osx-rel>
[DEBUG]   0001-patch-dir.patch|3c679554b70cba5a5dee554a4f02cfe2bbdf5ea5
[DEBUG]   CONTROL|4466385d3bffb1cbc43efe55180e9151a12d7116
[DEBUG]   cmake|3.18.4
[DEBUG]   features|core
[DEBUG]   fix_cmake_config.patch|6c3f00dcb6091bd3ab95ca452e2f685a4dd75dce
[DEBUG]   portfile.cmake|4b0207c608f1a09352c16fa7c970f12fec1927e1
[DEBUG]   post_build_checks|2
[DEBUG]   triplet|f57366c9c4a491b55f09403f44ae663a8935f5f9-94be8c046f9e0595c199a36690d288f70945643b-40c9eb093940d44cb6e6c8c0a7250ac20ec886ff
[DEBUG]   vcpkg_configure_cmake|ae0a97eff7f218b68bc4ab1b4bd661107893803e
[DEBUG]   vcpkg_copy_pdbs|dbca2886a2490c948893c8250a2b40a3006cf7a9
[DEBUG]   vcpkg_fixup_cmake_targets|799f0da59bbd2e387502be06a30e3d43f2e89b49
[DEBUG]   vcpkg_from_git|f29cbe08f369138581e36c864f9d08465c840e23
[DEBUG]   vcpkg_from_github|70d537ee6afbd1e8d40cc7d4e27a263ea5a81213
[DEBUG]   vcpkg_install_cmake|75d1079d6f563d87d08c8c5f63b359377aa19a6e
[DEBUG] </abientries>
```

In the end, if you still can't get NuGet to work, try [downloading pre-built dependency bundle](#download-pre-built-dependency-bundle) or [building everything yourself](#building-it-all-from-source).
