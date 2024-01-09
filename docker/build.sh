#!/usr/bin/env bash

set -euo pipefail

# Builds base images with all required dependencies to bootstrap vcpkg and
# build vcpkg libraries as well as all lifting-bits tools

# Ubuntu versions to build
UBUNTU_VERSION_MATRIX=( "22.04" "24.04" )

for ubuntu_version in "${UBUNTU_VERSION_MATRIX[@]}"; do
  # Always pull from upstream
  docker pull "ubuntu:${ubuntu_version}"

  # Image identification. "v2" Image version is to identify big changes to the
  # build toolchain like LLVM version
  # Also remember to change the '.github/workflows/vcpkg_docker.yml' variable
  image="vcpkg-builder-ubuntu-v2"

  # Build
  docker build \
      -f Dockerfile.ubuntu.vcpkg \
      --no-cache \
      --build-arg "UBUNTU_VERSION=${ubuntu_version}" \
      -t "${image}:${ubuntu_version}" \
      .
done
