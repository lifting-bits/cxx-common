ATTENTION: This repo was recently updated to use [`vcpkg`](https://github.com/microsoft/vcpkg) for managing dependencies.

Until all of the `lifting-bits` tools are updated to mention something about `vcpkg`, you can find the original way to install dependencies in the [`old`](./old) directory.

# VCPKG Ports Registry for common C/C++ packages

Curated dependencies that are compatible with the [lifting-bits](https://github.com/lifting-bits) tools.

# Pre-built

Every [release](https://github.com/trailofbits/cxx-common/releases), we publish compressed archives of the pre-built dependencies built by [vcpkg](https://github.com/microsoft/vcpkg).

We only officially support and test the libraries built for the OSes that appear in CI, which includes Ubuntu 18.04, 20.04, and Mac OS 10.15, 11.0.

To use the dependencies, just download the compressed file and decompress it. The resulting directory _does not require_ installation of anything other than a recent version of CMake to use with a project.

Many of the lifting-bits tools have support for using the vcpkg binaries written into their `CMakeLists.txt` files and will tell you how to pass the path.

For example:

```bash
curl -LO https://github.com/trailofbits/cxx-common/releases/latest/download/vcpkg_ubuntu-20.04_llvm-10_amd64.tar.xz
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

## Debug and Release

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

## Additional Packages

Just add another package name to the script
```bash
./build_dependencies.sh --release llvm-10 fmt
```
or add it to `dependencies.txt`.

# Dependency Versioning

The version of each dependency is influenced by the git checkout of vcpkg, contained in `vcpkg_info.txt`. Currently, the only way to upgrade is to push the commit in that file up, **_or_** to create (likely copy) a port definition for the required version and place it in our local `ports` ([overlay](https://github.com/microsoft/vcpkg/blob/master/docs/specifications/ports-overlay.md)) directory.

See [here](https://github.com/microsoft/vcpkg/blob/master/docs/examples/packaging-github-repos.md) for how to package a new library.

# LICENSING

This repo is under the Apache-2.0 LICENSE, unless where specified. See below.

The LLVM version port directories (ports/llvm-{9,10,11}) were initially copied from the upstream [vcpkg](https://github.com/microsoft/vcpkg) repo as a starting point. Eventually, we plan to submit the relevant patches for upstream when we have thoroughly tested these changes. More info can be found in the respective `LICENSE` and `NOTICE` files in those directories.
