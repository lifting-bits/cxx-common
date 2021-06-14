# VCPKG Ports for lifting-bits C/C++ projects

Curated dependencies that are compatible with the [lifting-bits](https://github.com/lifting-bits) tools.

# Pre-built

Every [release](https://github.com/lifting-bits/cxx-common/releases), we publish compressed archives of the pre-built dependencies built by [vcpkg](https://github.com/microsoft/vcpkg).

We only officially support and test the libraries built for the OSes that appear in CI, which includes Ubuntu 18.04, 20.04, and Mac OS 10.15, 11.0.

To use the dependencies, just download the compressed file and decompress it. The resulting directory _does not require_ installation of anything other than a recent version of CMake to use with a project.

Many of the lifting-bits tools have support for using the vcpkg binaries written into their `CMakeLists.txt` files and will tell you how to pass the path.

For example:

```bash
curl -LO https://github.com/lifting-bits/cxx-common/releases/latest/download/vcpkg_ubuntu-20.04_llvm-10_amd64.tar.xz
tar -xJf vcpkg_ubuntu-20.04_llvm-10_amd64.tar.xz
```

Will produce a directory, and then you'll have to set the following during your CMake configure command to use these dependencies!

```text
-DCMAKE_TOOLCHAIN_FILE="<path_to_unpacked_dir>/scripts/buildsystems/vcpkg.cmake" -DVCPKG_TARGET_TRIPLET=x64-linux-rel
```

or (if supported by the project's `CMakeLists.txt`)

```text
-DVCPKG_ROOT="<path_to_unpacked_dir>"
```

# Building from source

If you aren't running a supported operating system, or you just want to build it for fun, you can build everything from source using the `./build_dependencies.sh` script.

By default, the script will install the dependencies listed in `dependencies.txt`, which doesn't include an LLVM version, so passing an `llvm-10` string as an argument will actually be passed to `vcpkg install`. Any other strings are also passed to the `vcpkg install` command.

```bash
./build_dependencies.sh llvm-10
```

You can pass `--help` to the script to look at all options.

Note that vcpkg will use binary caching to store built dependency packages (usually at `~/.cache/vcpkg` or manually set with environment variable `VCPKG_DEFAULT_BINARY_CACHE`) so that upon reinstallation/building (re-running the script) you won't have to rebuild everything from scratch, unless the package itself has been updated, you are using a different vcpkg triplet, or any of the vcpkg scripts have changed (updated vcpkg repo). If you'd like to turn off binary caching (not recommended), then you can either pass `--no-binarycaching` to the build script after the main options listed in `--help` or add `-binarycaching` to the `VCPKG_FEATURE_FLAGS` environment variable.

**ATTENTION**: If you are having issues or want to start with a fresh installation directory, pass the `--clean` option to clear the installation directories and, if specified, the export directory.

## Export Directories (recommended)

By default, vcpkg will install all of your dependencies to its own in-repo `installed` directory. Passing `--export-dir <DIR>` to the `./build_dependencies.sh` script, you can store the required dependencies in a separate directory. Otherwise, the built dependencies will be stored within the vcpkg repo directory itself. It is preferred to create a new export directory to keep track of different LLVM versions, since they cannot coexist within the same export (read: installation) directory.

```bash
./build_dependencies.sh --export-dir vcpkg-llvm-10-install llvm-10
```

will build all of the dependencies listed in `dependencies.txt` _and_ LLVM 10 and install into a local directory named `vcpkg-llvm-10-install`.

### Installing additional packages

**NOTE** If you download the pre-built binaries, this does not apply.

To install more packages to an existing vcpkg installation, just run the script without specifying any extra build configuration arguments, unless you have an export directory, and list the packages you'd like to install or add them to `dependencies.txt`:

```bash
./build_dependencies.sh --export-dir vcpkg-llvm-10-install fmt
```

will install `fmt` into a local directory named `vcpkg-llvm-10-install` with whatever triplet is found within that vcpkg export directory. If multiple triplets are found in the export directory, the script will build `fmt` for each of those triplets.

## Updating

Updating dependencies is the same as installing them from source. Just run the script again (without any packages listed) and make sure to point it to your exported directory, if necessary. Do not specify anything regarding the triplet, like `--release` or `--asan`---the triplet(s) are detected automatically.

## Debug and Release Builds

To build both debug and release versions with llvm-10, just run the following

```bash
./build_dependencies.sh llvm-10
```

The script will be verbose about what it is doing and will clone the correct version of vcpkg (found in `vcpkg_info.txt`) and build everything in the `vcpkg` directory in the root of this repo.

At the end it will print how to use the library.

## Just release builds

If you don't want to compile a debug version of the tools, just pass `--release` to the script.

```bash
./build_dependencies.sh --release llvm-10
```

## Address Sanitizer

:warning: **Not tested on all vcpkg packages.** Open an issue if a tool's dependency cannot be built with sanitizers.

There is experimental support for compiling dependencies with address sanitizer using the `*-asan` suffix for OSX and Linux triplets.

These dependencies can be built with the script by passing `--asan` to the script, and it should work whether building only Release or both Debug and Release:

```bash
./build_dependencies.sh [--release] --asan llvm-10
```

Just because your dependencies were built with a sanitizer, you'll still need to manually add support for sanitizer usage within your own project. A quick and dirty way involves specifying the extra compilation flags during the build process:

```bash
CXXFLAGS="-fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -Wl,-undefined,dynamic_lookup" \
  CFLAGS="-fsanitize=address -fno-omit-frame-pointer -fno-optimize-sibling-calls -ffunction-sections -fdata-sections -Wl,-undefined,dynamic_lookup" \
  LDFLAGS="-fsanitize=address -Wl,-undefined,dynamic_lookup" \
  cmake \
  -DVCPKG_ROOT="<path_to_vcpkg>" \
  -DVCPKG_TARGET_TRIPLET=x64-linux-rel-asan \
  ..
```

**NOTE:** it is important to specify the `VCPKG_TARGET_TRIPLET` based on what platform and build configuration was used while compiling your dependencies with the sanitizers.

# Dependency Versioning

The version of each dependency is influenced by the git checkout of vcpkg, contained in `vcpkg_info.txt`. Currently, the only way to upgrade is to push the commit in that file up, **_or_** to create (likely copy) a port definition for the required version and place it in our local `ports` ([overlay](https://github.com/microsoft/vcpkg/blob/master/docs/specifications/ports-overlay.md)) directory. While we do support multiple LLVM versions, it is not easy or well-supported (yet) to have different versions installed simultaneously; you should remove the unwanted version before installing another, which is why the `./build_dependencies.sh` script always reinstalls packages to ensure we are starting from nothing.

See [here](https://github.com/microsoft/vcpkg/blob/master/docs/examples/packaging-github-repos.md) for how to package a new library.

# LICENSING

This repo is under the Apache-2.0 LICENSE, unless where specified. See below.

The LLVM version port directories (ports/llvm-{9,10,11}) were initially copied from the upstream [vcpkg](https://github.com/microsoft/vcpkg) repo as a starting point. Eventually, we plan to submit the relevant patches for upstream when we have thoroughly tested these changes. More info can be found in the respective `LICENSE` and `NOTICE` files in those directories.
