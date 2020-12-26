#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build_dependencies.sh [--release] [...]
#   --release   Optional, build only release versions with triplet as detected in this script
#   [...]       Optional, extra args to pass to 'vcpkg install'. Like LLVM version, other ports, etc.

function msg {
  echo "[+]" "$@"
}

function die {
  echo "[!]" "$@"
  exit 1
}

msg "Building dependencies from source"

triplet=""
extra_vcpkg_args=()
extra_cmake_usage_args=()

if [ $# -ge 1 ] && [ "$1" = "--release" ]; then
  msg "Only building release versions"

  uname="$(uname -s)"
  if [ "${uname}" = "Linux" ]; then
    msg "Detected Linux OS"
    triplet="x64-linux-rel"
  elif [ "${uname}" = "Darwin" ]; then
    msg "Detected Darwin OS"
    triplet="x64-osx-rel"
  else
    die "Could not detect OS. OS detection required for release-only builds."
  fi
  extra_vcpkg_args+=("--triplet=${triplet}")
  extra_cmake_usage_args+=("-DVCPKG_TARGET_TRIPLET=${triplet}")
  shift
else
  msg "Building Release and Debug versions"
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vcpkg_info_file="${repo_dir}/vcpkg_info.txt"

# Read vcpkg cloning info
{ read -r vcpkg_repo_url && read -r vcpkg_commit; } <"${vcpkg_info_file}" || die "line ${LINENO}: Could not parse vcpkg info file '${vcpkg_info_file}'"

msg "Using vcpkg repo URL '${vcpkg_repo_url}'"
msg "Using vcpkg commit '${vcpkg_commit}'"

vcpkg_dir="${repo_dir:?}/vcpkg"

if [ ! -d "${vcpkg_dir}" ]; then
  msg "Cloning to '${vcpkg_dir}'"
  git clone https://github.com/microsoft/vcpkg.git "${vcpkg_dir}"
fi

(
  cd "${vcpkg_dir}" && git remote set-url origin "${vcpkg_repo_url}" && git fetch origin && git checkout "${vcpkg_commit}"
)

msg "Boostrapping vcpkg"
(
  set -x
  "${vcpkg_dir}/bootstrap-vcpkg.sh"
)

msg "Building dependencies"
msg "Passing extra args to 'vcpkg install':"
msg " " "$@"
(
  cd "${repo_dir}"
  (
    set -x

    if type clang >/dev/null 2>&1; then
        export CC="${CC:-$(which clang)}"
        export CXX="${CXX:-$(which clang++)}"
    fi

    # TODO: Better way to remove all unspecified packages that we're about to
    # install for specified triplet? Need this because different LLVM versions
    # conflict when installed at the same time
    rm -rf "${vcpkg_dir:?}/installed" || true
    "${vcpkg_dir}/vcpkg" install "${extra_vcpkg_args[@]}" '@overlays.txt' '@dependencies.txt' "$@"
    "${vcpkg_dir}/vcpkg" upgrade "${extra_vcpkg_args[@]}" '@overlays.txt' --no-dry-run

    find "${vcpkg_dir}"/installed/*/tools/protobuf/ -type f -exec chmod 755 {} +
  )
)

echo ""
msg "Set the following in your CMake configure command to use these dependencies!"
msg "  -DVCPKG_ROOT=\"${vcpkg_dir}\" ${extra_cmake_usage_args[*]}"
msg "or"
msg "  -DCMAKE_TOOLCHAIN_FILE=\"${vcpkg_dir}/scripts/buildsystems/vcpkg.cmake\" ${extra_cmake_usage_args[*]}"
