# VCPKG Ports for lifting-bits C/C++ projects

Curated dependencies that are compatible with the [lifting-bits](https://github.com/lifting-bits) tools.

## Pre-built

Every [release](https://github.com/lifting-bits/cxx-common/releases), we publish compressed archives of the pre-built dependencies built by [vcpkg](https://github.com/microsoft/vcpkg) with the CMake `Release` build type.

We only officially support and test the libraries built for the OSs that appear in CI. If an OS or architecture is not listed in a release, please open an issue so that we can track potential support.

To use the dependencies, just download the compressed file and decompress it. The resulting directory _does not require_ installation of anything other than a C++ compiler and recent version of CMake to use with a project.

For example:

```bash
curl -LO https://github.com/lifting-bits/cxx-common/releases/latest/download/vcpkg_ubuntu-20.04_llvm-15_amd64.tar.xz
tar -xJf vcpkg_ubuntu-20.04_llvm-15_amd64.tar.xz
```

Will produce a directory, and then you'll have to set the following during your CMake configure command to use these dependencies!

```text
-DCMAKE_TOOLCHAIN_FILE="<...>/vcpkg_ubuntu-20.04_llvm-15_amd64/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-linux-rel
```

Replace `x64-linux-rel` with `x64-osx-rel` if using the macOS pre-built download.

## Building from source

If you aren't running a supported operating system, or you want to have dependencies with a build type other than `Release`, you can build everything from source using the `./build_dependencies.sh` script (pass `--help` to see available options).

By default, the script will install the dependencies listed in [`dependencies.txt`](./dependencies.txt), which doesn't include an LLVM version, so passing an `llvm-15` string as an argument will actually be passed to [`vcpkg install`](https://github.com/microsoft/vcpkg/blob/master/docs/examples/installing-and-using-packages.md#install). Any other strings not matching the script's own options are also passed to the `vcpkg install` command. Furthermore, without specifying any other build script options, vcpkg determine determine the best triplet for your operating system, which means building _both_ `Debug` and `Release` build types (see the [vcpkg triplet docs](https://github.com/microsoft/vcpkg/blob/master/docs/users/triplets.md) for more info).

You can customize the features that a particular package is built with by specifying the feature name between brackets, i.e. `llvm-15[target-all]` (build all target backends), to ensure non-default features are also installed along with all default features. The list of features can be found in the target port's `vcpkg.json` file. Please read the [vcpkg docs](https://github.com/microsoft/vcpkg/blob/master/docs/users/selecting-library-features.md#installing-additional-features) for more information about specifying additional features.

```bash
./build_dependencies.sh llvm-15
```

Note that vcpkg will use binary caching to store built dependency packages (usually at `~/.cache/vcpkg` or manually set with environment variable `VCPKG_DEFAULT_BINARY_CACHE`) so that upon reinstallation/rebuilding (re-running the script) you likely won't have to rebuild everything from scratch, unless the package itself has been updated, you are using a different vcpkg triplet, your compiler has been changed/update, or any of the vcpkg scripts have changed (updated vcpkg repo). If you'd like to turn off [binary caching](https://github.com/microsoft/vcpkg/blob/master/docs/users/binarycaching.md) (not recommended), then you can either pass `--no-binarycaching` to the build script after the main options listed in or add `-binarycaching` to the `VCPKG_FEATURE_FLAGS` environment variable.

**ATTENTION**: If you are having issues it is best to start fresh. Delete all of the created `vcpkg` directory. If you have binary caching on and nothing has changed, then you should be able to quickly reuse your previously built dependencies.

### Export Directories

Passing `--export-dir <DIR>` to the `./build_dependencies.sh` script, you can install the chosen dependencies in a separate directory. Otherwise, the built dependencies will be stored within the vcpkg repo directory itself (`vcpkg/installed` relative path if in the root of this repo). Separate export directories are required to keep track of different LLVM versions, since they cannot coexist within the same export (read: installation) directory.

```bash
./build_dependencies.sh --export-dir vcpkg-llvm-15-install llvm-15
```

will build all of the dependencies listed in `dependencies.txt` _and_ LLVM 15 and install into a local directory named `vcpkg-llvm-15-install`.

Furthermore, you are able to install additional dependencies into an existing exported directory created by this script by setting the `--export-dir <path>` to the same path:

```bash
./build_dependencies.sh --release --export-dir "<...>/vcpkg_ubuntu-20.04_llvm-15_amd64" spdlog
```

When reusing the pre-built export directory downloaded from GitHub, you must specify `--release` (see the 'Debug and Release Builds' section below) to build only release binaries. You cannot use dependencies from different triplets.

### Debug and Release Builds

To build both debug and release versions with llvm-15, just run the following

```bash
./build_dependencies.sh llvm-15
```

The script will be verbose about what it is doing and will clone the correct version of vcpkg (found in `vcpkg_info.txt`) and build everything in the `vcpkg` directory in the root of this repo.

At the end it will print how to use the library:

```bash
$ ./build_dependencies.sh --export-dir example-export-dir
...
[+] Set the following in your CMake configure command to use these dependencies!
[+]   -DCMAKE_TOOLCHAIN_FILE="/Users/ekilmer/src/cxx-common/vcpkg/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-osx -DVCPKG_HOST_TRIPLET=x64-osx
```

## Just release builds

If you don't want to compile a debug version of the tools, just pass `--release` to the script.

```bash
$ ./build_dependencies.sh --release llvm-15
...
[+] Set the following in your CMake configure command to use these dependencies!
[+]   -DCMAKE_TOOLCHAIN_FILE="/Users/ekilmer/src/cxx-common/vcpkg/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-osx-rel -DVCPKG_HOST_TRIPLET=x64-osx-rel
```

### Address Sanitizer

:warning: **Not tested on all vcpkg packages.** Open an issue if a tool's dependency cannot be built with sanitizers.

There is experimental support for compiling dependencies with address sanitizer using the `*-asan` suffix for `osx` and `linux` triplets.

These dependencies can be built with the script by passing `--asan` to the script, and it should work whether building only Release or both Debug and Release:

```bash
./build_dependencies.sh [--release] --asan llvm-15
```

Just because your dependencies were built with a sanitizer, you'll still need to manually add support for sanitizer usage within your own project. A quick and dirty way involves specifying the extra compilation flags during CMake configure:

```bash
$ cmake \
  -DVCPKG_ROOT="<path_to_vcpkg>" \
  -DVCPKG_TARGET_TRIPLET=x64-linux-rel-asan \
  -DCMAKE_CXX_FLAGS="-fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls -ffunction-sections -fdata-sections" \
  -DCMAKE_C_FLAGS="-fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls -ffunction-sections -fdata-sections" \
  -DCMAKE_EXE_LINKER_FLAGS="-fsanitize=address" \
  -DCMAKE_SHARED_LINKER_FLAGS="-fsanitize=address" \
  -DCMAKE_STATIC_LINKER_FLAGS="-fsanitize=address" \
  -DCMAKE_MODULE_LINKER_FLAGS="-fsanitize=address" \
  ...
```

**NOTE:** it is important to specify the `VCPKG_TARGET_TRIPLET` based on what platform and build configuration was used while compiling your dependencies with the sanitizers (look for the usage message that the script outputs at the end).

## Dependency Versioning

The version of each dependency is influenced by the git checkout of vcpkg, contained in `vcpkg_info.txt`. Currently, the only way to upgrade is to push the commit in that file up, **_or_** to create (likely copy) a port definition for the required version and place it in our local `ports` ([overlay](https://github.com/microsoft/vcpkg/blob/master/docs/specifications/ports-overlay.md)) directory. While we do support multiple LLVM versions, it is not easy or well-supported (yet) to have different versions installed simultaneously.

See [the vcpkg docs](https://github.com/microsoft/vcpkg/blob/master/docs/examples/packaging-github-repos.md) for how to package a new library.

### Updating Dependencies

Installing additional dependencies will not update any existing dependencies by default. We do not update/upgrade by default because this could cause unexpected rebuilds that could potentially take hours (in the case of LLVM). To update dependencies, pass the `--upgrade-ports` option to the build script along with the respective options affecting vcpkg triplet selection (like `--release`).

## Useful manual vcpkg commands

Sometimes it is useful to run vcpkg commands manually for testing a single package. Ideally, someone who wants to do this would read the [vcpkg documentation](https://github.com/microsoft/vcpkg/tree/master/docs), but below we list some commonly used commands. Inspecting the output of the build script will also show all of the vcpkg commands executed.

The following commands should be run from the root of this repo, and they do not apply if you have downloaded pre-built packages.

### Installing

Remember, you must know the triplet you would like to build with if you are using an existing installation after running the build script.

```sh
./vcpkg/vcpkg install --triplet=x64-osx-rel @overlays.txt --debug grpc --x-install-root=<...>/installed
```

This command will 
* `install` the `grpc` package
* using the `x64-osx-rel` triplet to only build x86-64 Release builds for Mac
* in the context of `@overlays.txt`, which sets up vcpkg package paths using normal vcpkg commands (look at the file if you're interested)
* tell vcpkg to print out `--debug` information
* and use the `install-root` of `<...>/installed` where `<...>` is a path to your export directory or the local `vcpkg` repo.

### Uninstalling

Remember, you must know the triplet you would like to build with if you are using an existing installation after running the build script.

```sh
./vcpkg/vcpkg remove --triplet=x64-osx-rel @overlays.txt --debug grpc --x-install-root=<...>/installed
```

This command will do similar things as the above command, except it will `remove` the package from the installation directory instead of installing.

## LICENSING

This repo is under the Apache-2.0 LICENSE, unless where specified. See below.

The LLVM version port directories (ports/llvm-{15,16}) were initially copied from the upstream [vcpkg](https://github.com/microsoft/vcpkg) repo as a starting point. Eventually, we plan to submit the relevant patches for upstream when we have thoroughly tested these changes. More info can be found in the respective `LICENSE` and `NOTICE` files in those directories.
