#!/usr/bin/env bash

set -euo pipefail

# Builds base images with all required dependencies to bootstrap vcpkg and
# build vcpkg libraries as well as all lifting-bits tools

# Also remember to change the '.github/workflows/vcpkg_docker_amd64.yml' variable
IMAGE_VER=v2

# Ubuntu versions to build
UBUNTU_VERSION_MATRIX=( "jammy" )

for version in "${UBUNTU_VERSION_MATRIX[@]}"; do
  # Always pull from upstream
  docker pull "ubuntu:${version}"

  # Image identification
  tag="vcpkg-builder-ubuntu-${IMAGE_VER}:${version}"

  # Build
  docker build \
      -f Dockerfile.ubuntu.vcpkg \
      --no-cache \
      --build-arg "DISTRO_VERSION=${version}" \
      -t "${tag}" \
      .
done
