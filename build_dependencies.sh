#!/usr/bin/env bash
set -euo pipefail

function msg {
  echo "[+]" "$@"
}

function die {
  echo "[!]" "$@"
  exit 1
}

function Help
{
  echo "Usage: ./build_dependencies.sh [--release] [--target-arch ARCH] [--asan] [--upgrade-ports] [--export-dir DIR] [...]"
  echo ""
  echo "Options:"
  echo "  --verbose"
  echo "     Print more verbose information from vcpkg during installation"
  echo "  --release"
  echo "     Build only release versions with triplet as detected in"
  echo "     this script"
  echo "  --target-arch <ARCH>"
  echo "     Override target triplet architecture for cross compilation"
  echo "  --asan"
  echo "     Build with ASAN triplet as detected in this script"
  echo "  --upgrade-ports"
  echo "     Upgrade any outdated packages in the chosen install/export"
  echo "     directory. Warning, this could cause long rebuild times if your"
  echo "     compiler has changed or your installation directory hasn't been"
  echo "     updated in a while."
  echo "  --export-dir <DIR>"
  echo "     Export built dependencies to directory path"
  echo "  [...]"
  echo "     Extra args to pass to 'vcpkg install'. Like LLVM version,"
  echo "     other ports, vcpkg-specific options, etc."
}

if [[ -n "${VCPKG_ROOT+unset}" ]]; then
  unset VCPKG_ROOT
fi

RELEASE="false"
ASAN="false"
EXPORT_DIR=""
UPGRADE_PORTS="false"
VCPKG_ARGS=()
while [[ $# -gt 0 ]] ; do
  key="$1"

  case $key in
    -h|--help)
      Help
      exit 0
    ;;
    --verbose)
      VCPKG_ARGS+=("--debug")
    ;;
    --upgrade-ports)
      UPGRADE_PORTS="true"
      msg "Upgrading any outdated ports"
    ;;
    --release)
      RELEASE="true"
      msg "Building Release-only binaries"
    ;;
    --target-arch)
      shift
      TARGET_ARCH=${1}
    ;;
    --asan)
      ASAN="true"
      msg "Building ASAN binaries"
    ;;
    --export-dir)
      EXPORT_DIR=$(python3 -c "import os; import sys; sys.stdout.write(os.path.abspath('${2}'))")
      echo "[+] Exporting to directory ${EXPORT_DIR}"
      shift # past argument
    ;;
    *)
      VCPKG_ARGS+=("$1")
  esac
  shift
done
msg "Passing extra args to 'vcpkg install':"
msg " " "${VCPKG_ARGS[@]}"

function die_if_not_installed {
  if ! type "$1" &>/dev/null; then
    die "Please install the package providing [${1}] command for your OS"
  fi
}

for pkg in git zip unzip cmake python3 curl tar pkg-config
do
  die_if_not_installed ${pkg}
done

# check if CC is not set or a null string
if [[ -z "${CC+unset}" || -z "${CC}" ]]; then
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
if [[ -z "${CXX+unset}" || -z "${CXX}" ]]; then
  if type clang++ &>/dev/null; then
    export CXX="${CXX:-$(which clang++)}"
    msg "Using default clang++ as CXX=${CXX}"
  else
    msg "Using default C++ compiler"
  fi
else
  msg "Using custom CXX=${CXX}"
fi

if [[ "$(uname -m)" = "aarch64" ]]; then
  export VCPKG_FORCE_SYSTEM_BINARIES=1
fi

# Disable metrics upload to Microsoft
export VCPKG_DISABLE_METRICS=1

msg "Building dependencies from source"

target_triplet=""
extra_vcpkg_args=()
extra_cmake_usage_args=()

# System triplet info
os="$(uname -s)"
arch="$(uname -m)"
# default to linux on amd64
triplet_os="linux"
triplet_arch="x64"

if [[ "${arch}" = "aarch64" || "${arch}" = "arm64" ]]; then
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

host_triplet="${triplet_arch}-${triplet_os}-rel"
if [[ -n ${TARGET_ARCH+unset} ]]; then
  triplet_arch=${TARGET_ARCH}
fi
target_triplet="${triplet_arch}-${triplet_os}"

# Build-Type triplet
if [[ ${RELEASE} == "true" ]]; then
  msg "Only building release versions"
  target_triplet="${target_triplet}-rel"
else
  msg "Building Release and Debug versions"
fi

# ASAN triplet
if [[ ${ASAN} == "true" ]]; then
  msg "Building with asan"
  target_triplet="${target_triplet}-asan"
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vcpkg_dir=${repo_dir:?}/vcpkg

if [[ -z ${EXPORT_DIR} ]]; then
  # Set default export directory variable. Used for printing end message
  EXPORT_DIR=${vcpkg_dir}
fi

extra_vcpkg_args+=("--triplet=${target_triplet}" "--host-triplet=${host_triplet}" "--x-install-root=${EXPORT_DIR}/installed")

extra_cmake_usage_args+=("-DVCPKG_TARGET_TRIPLET=${target_triplet}" "-DVCPKG_HOST_TRIPLET=${host_triplet}")

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vcpkg_info_file="${repo_dir}/vcpkg_info.txt"

# Read vcpkg cloning info
{ read -r vcpkg_repo_url && read -r vcpkg_commit; } <"${vcpkg_info_file}" || die "line ${LINENO}: Could not parse vcpkg info file '${vcpkg_info_file}'"

msg "Using vcpkg repo URL '${vcpkg_repo_url}'"
msg "Using vcpkg commit '${vcpkg_commit}'"

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
  if command -v ccache &> /dev/null
  then
    export "CMAKE_C_COMPILER_LAUNCHER=$(which ccache)"
    export "CMAKE_CXX_COMPILER_LAUNCHER=$(which ccache)"
  fi

  "${vcpkg_dir}/bootstrap-vcpkg.sh"
)

# Copy required buildsystem scripts to export directory (this is what the
# `vcpkg export` command does).
# See the following `export_integration_files` function for the list of files.
# This should be updated when that is updated.
# https://github.com/microsoft/vcpkg-tool/blob/1533e9db90da0571e29e7ef85c7d5343c7fb7616/src/vcpkg/export.cpp#L259-L279
if [[ "${EXPORT_DIR}" != "${vcpkg_dir}" ]]; then
  msg "Copying required vcpkg files to export directory"
  mkdir -p "${EXPORT_DIR}"
  touch "${EXPORT_DIR}/.vcpkg-root"
  integration_files=(
    "scripts/buildsystems/msbuild/applocal.ps1"
    "scripts/buildsystems/msbuild/vcpkg.targets"
    "scripts/buildsystems/msbuild/vcpkg.props"
    "scripts/buildsystems/msbuild/vcpkg-general.xml"
    "scripts/buildsystems/osx/applocal.py"
    "scripts/buildsystems/vcpkg.cmake"
    "scripts/cmake/vcpkg_get_windows_sdk.cmake"
  )
  for f in "${integration_files[@]}"
  do
    cmake -E copy_if_different "${vcpkg_dir}/${f}" "${EXPORT_DIR}/${f}"
  done
fi

msg "Building dependencies"
msg "Passing extra args to 'vcpkg install':"
msg " " "${VCPKG_ARGS[@]}"

overlays=()
if [ -f "${repo_dir}/overlays.txt" ] ; then
  readarray -t overlays < <(cat "${repo_dir}/overlays.txt")
fi

# Check if we should upgrade ports
if [[ ${UPGRADE_PORTS} == "true" ]]; then
  echo ""
  msg "Checking and upgrading outdated ports"
  (
    cd "${repo_dir}"
    (
      set -x
      # shellcheck disable=SC2046
      "${vcpkg_dir}/vcpkg" upgrade "${extra_vcpkg_args[@]}" "${overlays[@]}" --no-dry-run --allow-unsupported
    )
  ) || exit 1
fi

deps=()
if [ -f "${repo_dir}/dependencies.txt" ] ; then
  readarray -t deps < <(cat "${repo_dir}/dependencies.txt")
fi

# Run the vcpkg installation of our packages
(
  cd "${repo_dir}"
  (
    set -x

    "${vcpkg_dir}/vcpkg" install "${extra_vcpkg_args[@]}" "${overlays[@]}" "${deps[@]}" "${VCPKG_ARGS[@]}"
  )
) || exit 1

echo ""
msg "Investigate the following directory to discover all packages available to you:"
msg "  ${EXPORT_DIR}/installed/vcpkg"
echo ""
msg "Set the following in your CMake configure command to use these dependencies!"
msg "  -DCMAKE_TOOLCHAIN_FILE=\"${EXPORT_DIR}/scripts/buildsystems/vcpkg.cmake\" ${extra_cmake_usage_args[*]}"

if [[ "$(uname -m)" = "aarch64" ]]; then
  echo ""
  msg "On aarch64, you also need to set:"
  msg "  export VCPKG_FORCE_SYSTEM_BINARIES=1"
fi
