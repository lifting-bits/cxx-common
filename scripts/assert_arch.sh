#!/usr/bin/env bash

# Simple script to check whether a file was compiled with the chosen
# architecture. Only supports checking binaries that are from the same
# executable file format as the host (i.e., does not support checking linux
# binaries on macOS)
#
# Usage:
#   assert_arch.sh <arch> <binary>
#
# Example (run in parent directory):
#   find ./vcpkg/installed/arm64-osx-rel -type f \( -name "*.a" -o -name "*.dylib" -o -executable \) -exec ./scripts/assert_arch.sh arm64 {} \;
#   find ./vcpkg/installed/arm64-linux-rel -type f \( -name "*.a" -o -name "*.so" -o -executable \) -exec ./scripts/assert_arch.sh aarch64 {} \;

if [ $# -ne 2 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
  echo "Usage: assert_arch.sh <arch> <binary>"
  echo "macOS uses 'arm64' and Linux uses 'aarch64'"
  exit 1
fi

# TODO: Would be nice if we could choose our tool based on the executable
# format
if [ "$(uname)" = "Darwin" ] ; then
  arch=$(lipo -archs "$2" 2> /dev/null)
else
  # Assume Linux binutils, grep, sed, sort, uniq are available
  arch=$(objdump -f "$2" 2> /dev/null | perl -ne 's/^architecture: ([a-zA-Z0-9_-]+)/$1/ && print' | sort | uniq)
fi

# Do the check
if [ -n "${arch}" ] && ! (echo "${arch}" | grep -q "$1"); then
  echo "$2: Incorrect arch found: '${arch}'"
  exit 1
fi
