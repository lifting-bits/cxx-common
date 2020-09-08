# cxx-common

[![Build Status](https://img.shields.io/github/workflow/status/trailofbits/cxx-common/CI%20CD/master)](https://github.com/trailofbits/cxx-common/actions?query=workflow%3A%22CI%20CD%22)

Build and installation scripts for C and C++ libraries that are commonly used by Trail of Bits.

# Docker Builds

This project includes a Dockerfile that is automatically built and pushed to DockerHub and Github Package Registry. Both registries *should* have identical packages, but some architectures (currently, AArch64) packages are updated manually and may be out of sync between registries.

Quick Package Repository Links:
* [GitHub Package Repository](https://github.com/trailofbits/cxx-common/packages)
* [DockerHub Package Repository](https://hub.docker.com/r/trailofbits/cxx-common/tags)

Binary build artifacts are also automatically published with each passing CI build on [Github Actions](https://github.com/trailofbits/cxx-common/actions).

## Using the Docker Build

Docker images are parameterized by LLVM version, OS, and architecture. Not all LLVM/OS/Architecture combinations packages are pre-built.

Supported LLVM Versions: 4.0.1 through current
Supported Architectures: amd64, aarch64
Supported OSes: Ubuntu 16.04, Ubuntu 18.04; Other Linux distributions likely also work but are untested. Windows and MacOS are supported via manual (that is, non-Docker) builds.

For example, to fetch the cxx-common image using LLVM 8.0 for Ubuntu 18.04 on AMD64, you'd use:

```sh
# for DockerHub Packages
docker pull trailofbits/cxx-common:llvm800-ubuntu18.04-amd64
```

or
```sh
# for GitHub Package Repository packages
docker pull docker.pkg.github.com/trailofbits/cxx-common/llvm800-ubuntu18.04-amd64:latest
```

## Building The Docker Image Yourself

The Dockerfile can be built locally. It is parameterized by LLVM version and OS release. Currently same-architecture builds are expected (i.e., build amd64 images on amd64 and build aarch64 images on aarch64). Some examples below:

Building cxx-common for LLVM 8 on Ubuntu 18.04 on AArch64 (ARM v8 64-bit):
```sh
docker build . -t cxx-common:llvm800-ubuntu18.04-aarch64 -f Dockerfile --build-arg UBUNTU_BASE=arm64v8/ubuntu:18.04 --build-arg LLVM_VERSION=800
```

Building cxx-common for LLVM 4.0.1 on Ubuntu 16.04 for AMD64 (x86-64):
```sh
docker build . -t cxx-common:llvm401-ubuntu16.04-amd64 -f Dockerfile --build-arg UBUNTU_BASE=ubuntu:16.04 --build-arg LLVM_VERSION=401
```

# Manual (non-Docker) Builds

There may be cases where Dockerized builds are not desired or not possible. The project can be also built manually.

## macOS/Linux prerequisites

When building LLVM < 5.x on Linux you will need the 'xlocale.h' include header from the **libc6-dev** package. This file was deprecated in Ubuntu > 16.04.x, so if you are building on a recent distribution, you should probably build version 5.0.1 or better.

1. LZMA (liblzma-dev on Ubuntu)
2. Python LZMA module (pip install backports.lzma)

## How to build the 'libraries' repository

 * Dependencies can be installed using Travis build script: **./travis.sh <linux|macos> initialize**
 * If you are building recent LLVM versions, you can probably just run **./travis.sh <linux|macos> build**
 * If you are calling pkgman.py directly, always try to use the best compiler available, passing the --c_compiler and -cxx_compiler parameters.
 * When calling the **build** function of the Travis script, you can set your preferred compiler using the standard environment variables: CC and CXX.

Errors are always printed but if you'd rather see the build output in real time, the **--verbose** parameter can be passed to **pkgman.py**.

## Windows support

Note that only LLVM 5.0.1 is known to work right now; when running the script on Windows, the --llvm_version parameter defaults to 501.

### Prerequisites
1. Python 2.7 (x64): https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi (add to PATH)
2. Visual Studio 2017: https://www.visualstudio.com/thank-you-downloading-visual-studio/?sku=Community&rel=15
3. LLVM 5.0.1 x64 for Visual Studio: http://releases.llvm.org/5.0.1/LLVM-5.0.1-win64.exe (do NOT add to PATH)
4. 7-Zip (x64): https://www.7-zip.org/a/7z1805-x64.exe

## Building the llvm35 version

### Prerequisites
 * Ubuntu 14.04 or OS X with Homebrew
 * Clang-3.5 or newer
 * Travis script dependencies (**./travis.sh linux initialize** or **./travis.sh osx initialize**)

### Build steps
### Automatically

```bash
./travish.sh linux build
```

or

```bash
./travis.sh osx build
```

### Manually

First, define the `TRAILOFBITS_LIBRARIES` environment variable. You can change the path used. You should create
the directory referenced by this variable, and whatever directory you specify, it should end in `.../libraries`.

```bash
export TRAILOFBITS_LIBRARIES=/opt/trailofbits/libraries
```

Then, bootstrap CMake. This gets you a reasonably up-to-date version of the CMake build system.

```bash
./pkgman.py --c_compiler=clang --cxx_compiler=clang++ --repository_path="${TRAILOFBITS_LIBRARIES}" --packages=cmake
```

Next up, update your `PATH`:

```bash
export PATH="${TRAILOFBITS_LIBRARIES}/cmake/bin:${PATH}"
```

Now that you've got a good enough CMake, built the rest of the packages.

```bash
./pkgman.py --llvm_version=900 --c_compiler=clang --cxx_compiler=clang++ --repository_path="${TRAILOFBITS_LIBRARIES}" --packages=z3,llvm,google,xed,capnproto
```

You're all set!
