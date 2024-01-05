#!/usr/bin/env bash

set -euo pipefail

# Builds base images with all required dependencies to bootstrap vcpkg and
# build vcpkg libraries as well as all lifting-bits tools

# Ubuntu versions to build
UBUNTU_VERSION_MATRIX=( "22.04" )

for version in "${UBUNTU_VERSION_MATRIX[@]}"; do
  # Always pull from upstream
  docker pull "ubuntu:${version}"

  # Also remember to change the '.github/workflows/vcpkg_docker.yml' variable
  # Image identification
  tag="vcpkg-builder-ubuntu-${version}-v2"

  # Build
  docker build \
      -f Dockerfile.ubuntu.vcpkg \
      --no-cache \
      --build-arg "DISTRO_VERSION=${version}" \
      -t "${tag}" \
      .
done
