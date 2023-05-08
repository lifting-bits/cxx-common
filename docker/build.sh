#!/usr/bin/env bash

set -euo pipefail

# Builds base images with all required dependencies to bootstrap vcpkg and
# build vcpkg libraries as well as all lifting-bits tools

# Ubuntu versions to build
UBUNTU_VERSION_MATRIX=( "focal" "jammy" )

for version in "${UBUNTU_VERSION_MATRIX[@]}"; do
  # Always pull from upstream
  docker pull "ubuntu:${version}"

  # Image identification
  tag="vcpkg-builder-ubuntu-v2:${version}"

  # Build
  docker build \
      -f Dockerfile.ubuntu.vcpkg \
      --no-cache \
      --build-arg "DISTRO_VERSION=${version}" \
      -t "${tag}" \
      .
done
