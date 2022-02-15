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
  echo "Usage: ./build_dependencies.sh [--release] [--asan] [--export-dir DIR] [...]"
  echo ""
  echo "Options:"
  echo "  --release"
  echo "     Build only release versions with triplet as detected in"
  echo "     this script"
  echo "  --asan"
  echo "     Build with ASAN triplet as detected in this script"
  echo "  --export-dir <DIR>"
  echo "     Export built dependencies to directory path"
  echo "  [...]"
  echo "     Extra args to pass to 'vcpkg install'. Like LLVM version,"
  echo "     other ports, vcpkg-specific options, etc."
}

RELEASE="false"
ASAN="false"
EXPORT_DIR=""
VCPKG_ARGS=()
while [[ $# -gt 0 ]] ; do
  key="$1"

  case $key in
    -h|--help)
      Help
      exit 0
    ;;
    --release)
      RELEASE="true"
      msg "Building Release-only binaries"
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

triplet=""
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

triplet="${triplet_arch}-${triplet_os}"

# Build-Type triplet
if [[ ${RELEASE} == "true" ]]; then
  msg "Only building release versions"
  triplet="${triplet}-rel"
else
  msg "Building Release and Debug versions"
fi

# ASAN triplet
if [[ ${ASAN} == "true" ]]; then
  msg "Building with asan"
  triplet="${triplet}-asan"
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
vcpkg_dir="${repo_dir:?}/vcpkg"

if [[ -z ${EXPORT_DIR} ]]; then
  # Set default export directory variable. Used for printing end message
  EXPORT_DIR="${vcpkg_dir}"
else
  if [[ -d "${EXPORT_DIR}" ]]; then
    die "Export directory already exists, please delete: '${EXPORT_DIR}'"
  fi
fi

extra_vcpkg_args+=("--triplet=${triplet}" "--host-triplet=${triplet}")

extra_cmake_usage_args+=("-DVCPKG_TARGET_TRIPLET=${triplet}" "-DVCPKG_HOST_TRIPLET=${triplet}")

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
    export CMAKE_C_COMPILER_LAUNCHER="$(which ccache)"
    export CMAKE_CXX_COMPILER_LAUNCHER="$(which ccache)"
  fi

  "${vcpkg_dir}/bootstrap-vcpkg.sh"
)

msg "Building dependencies"
msg "Passing extra args to 'vcpkg install':"
msg " " "${VCPKG_ARGS[@]}"

# Run the vcpkg installation of our packages
(
  cd "${repo_dir}"
  (
    set -x

    "${vcpkg_dir}/vcpkg" install "${extra_vcpkg_args[@]}" '@overlays.txt' '@dependencies.txt' "${VCPKG_ARGS[@]}"

    # This forces everyone to be updated but maybe this is too much trouble to
    # actually rebuild everything that has a mismatching hash.
    # "${vcpkg_dir}/vcpkg" upgrade "${extra_vcpkg_args[@]}" '@overlays.txt' --no-dry-run

    find "${vcpkg_dir}"/installed/*/tools/protobuf/ -type f -exec chmod 755 {} + || true
    find "${EXPORT_DIR}"/installed/*/tools/protobuf/ -type f -exec chmod 755 {} + || true
  )
)

# Don't export if we've already installed to an existing EXPORT_DIR
if [[ ! -d "${EXPORT_DIR}" ]]; then
  tmp_export_dir=temp-export
  set -x
  "${vcpkg_dir}/vcpkg" export --x-all-installed --raw "--output=${tmp_export_dir}"
  mv "${vcpkg_dir}/${tmp_export_dir}" "${EXPORT_DIR}"
  set +x
fi

echo ""
# TODO: See https://github.com/microsoft/vcpkg/issues/1785
#msg "The following packages are now available for your use:"
#if echo "${extra_vcpkg_args[@]}" | grep -w -v -q -- '--x-install-root=' ; then
#  extra_vcpkg_args+=("--x-install-root=${EXPORT_DIR}/installed")
#fi
#set -x
#"${vcpkg_dir}/vcpkg" "${extra_vcpkg_args[@]}" '@overlays.txt' list
#set +x
msg "Set the following in your CMake configure command to use these dependencies!"
msg "  -DVCPKG_ROOT=\"${EXPORT_DIR}\" ${extra_cmake_usage_args[*]}"
msg "or"
msg "  -DCMAKE_TOOLCHAIN_FILE=\"${EXPORT_DIR}/scripts/buildsystems/vcpkg.cmake\" ${extra_cmake_usage_args[*]}"

if [[ "$(uname -m)" = "aarch64" ]]; then
  echo ""
  msg "On aarch64, you also need to set:"
  msg "  export VCPKG_FORCE_SYSTEM_BINARIES=1"
fi
