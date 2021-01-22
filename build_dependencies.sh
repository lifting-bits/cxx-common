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

function die_if_not_installed {
  if ! type $1 &>/dev/null; then
    die "Please install the package providing [${1}] for your OS"
  fi
}

for pkg in git zip unzip cmake ninja python3 curl tar pkg-config
do
  die_if_not_installed ${pkg}
done

# check if CC is not set or a null string
if [[ ! -v "CC" || -z "${CC}" ]]; then
  if type clang &>/dev/null; then
    export CC="${CC:-$(which clang)}"
    msg "Using default clang as CC=${CC}"
  else
    msg "Using default C comiler"
  fi
else
  msg "Using custom CC=${CC}"
fi

# check if CXX is not set or a null string
if [[ ! -v "CXX" || -z "${CXX}" ]]; then
  if type clang++ &>/dev/null; then
    export CXX="${CXX:-$(which clang++)}"
    msg "Using default clang++ as CXX=${CC}"
  else
    msg "Using default C++ compiler"
  fi
else
  msg "Using custom CXX=${CXX}"
fi

if [[ "$(uname -m)" = "aarch64" ]]; then
  export VCPKG_FORCE_SYSTEM_BINARIES=1
fi

msg "Building dependencies from source"

triplet=""
extra_vcpkg_args=()
extra_cmake_usage_args=()

if [ $# -ge 1 ] && [ "$1" = "--release" ]; then
  msg "Only building release versions"

  os="$(uname -s)"
  arch="$(uname -m)"
  # default to linux on amd64
  triplet_os="linux"
  triplet_arch="x64"

  if [[ "${arch}" = "aarch64" ]]; then
    triplet_arch="arm64"
  elif [[ "${arch}" = "x86_64" ]]; then
    triplet_arch="x64"
  else
    die "Unknown system architecture: ${arch}"
  fi

  if [[ "${os}" = "Linux" ]]; then
    msg "Detected Linux OS"
    triplet_os="linux"
  elif [[ "${os}" = "Darwin" ]]; then
    msg "Detected Darwin OS"
    triplet_os="osx"
  else
    die "Could not detect OS. OS detection required for release-only builds."
  fi

  triplet="${triplet_arch}-${triplet_os}-rel"
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

if [[ "$(uname -m)" = "aarch64" ]]; then
  echo ""
  msg "On aarch64, you also need to set:"
  msg "  export VCPKG_FORCE_SYSTEM_BINARIES=1"
fi
