# cxx-common

Build and installation scripts for C and C++ libraries that are commonly used by Trail of Bits.

## How to build the 'libraries' repository

 * Dependencies can be installed using Travis build script: **./travis.sh <linux|macos> initialize**
 * If you are building recent LLVM versions, you can probably just run **./travis.sh <linux|macos> build**
 * If you are calling pkgman.py directly, always try to use the best compiler available, passing the --c_compiler and -cxx_compiler parameters.
 * When calling the **build** function of the Travis script, you can set your preferred compiler using the standard environment variables: CC and CXX.

Errors are always printed but if you'd rather see the build output in real time, the **--verbose** parameter can be passed to **pkgman.py**.

## Building the llvm35 version

### Prerequisites
 * Ubuntu 14.04
 * Clang-3.5 from the package manager
 * Travis script dependencies (**./travis.sh linux initialize**)

### Build steps
 * Build CMake: **./pkgman.py --c_compiler=clang-3.5 --cxx_compiler=clang++-3.5 --repository_path=/opt/TrailOfBits/libraries --packages=cmake**
 * Update the PATH: **export PATH="/opt/TrailOfBits/libraries/cmake/bin:${PATH}"**
 * Build the remaining packages: **./pkgman.py --llvm_version=352 --c_compiler=clang-3.5 --cxx_compiler=clang++-3.5 --repository_path=/opt/TrailOfBits/libraries --packages=llvm,capstone,gflags,glog,googletest,protobuf,xed**
