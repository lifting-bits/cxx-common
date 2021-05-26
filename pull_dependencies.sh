#!/usr/bin/env bash

# Try to pull prebuilt library dependencies using NuGet with your GitHub
# credentials

set -x -euo pipefail

echo "Old and untested..."
exit 1

usage()
{
cat << EOF
usage: pull_dependencies GITHUB_USERNAME GITHUB_TOKEN
  GITHUB_USERNAME   | GitHub username associated with Token
  GITHUB_TOKEN      | GitHub token to pull NuGet packages

WARNING: Will write your token in plaintext at ~/.conig/NuGet/NuGet.config
EOF
}


if [ -z ${1+x} ]; then
  echo "First argument GITHUB_USERNAME variable is unset";
  usage
  exit 1
else
  GITHUB_USERNAME="$1"
fi
if [ -z ${2+x} ]; then
  echo "Second argument GITHUB_USERNAME variable is unset";
  usage
  exit 1
else
  GITHUB_TOKEN="$2"
fi


#### Bootstrap vcpkg
git clone https://github.com/microsoft/vcpkg.git || true
# Thu Nov 12 23:28:59 2020 +0100
# NOTE: Update .github/workflows/ci.yml as well
pushd vcpkg && git fetch && git checkout b518035a33941380c044b00a1b4f8abff764cbdc && popd
./vcpkg/bootstrap-vcpkg.sh


#### Caching Setup

# NOTE: "Source" is specific to what you name the NuGet feed when adding it
export VCPKG_BINARY_SOURCES='clear;nuget,Source,read'

# WARNING
# Password stored in cleartext
# TODO(ekilmer): Parameterize llvm version
mono "$(./vcpkg/vcpkg fetch nuget | tail -n 1)" sources add \
  -source "https://nuget.pkg.github.com/lifting-bits/index.json" \
  -storepasswordincleartext \
  -name "Source" \
  -username "${GITHUB_USERNAME}" \
  -password "${GITHUB_TOKEN}" || true

mono "$(./vcpkg/vcpkg fetch nuget | tail -n 1)" setapikey \
  -source "https://nuget.pkg.github.com/lifting-bits/index.json" \
  "${GITHUB_TOKEN}"

#### Pulling dependencies with correct triplet

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     triplet=x64-linux-rel;;
    Darwin*)    triplet=x64-osx-rel;;
    *)          triplet="UNKNOWN:${unameOut}"
esac
echo Using Triplet: "${triplet}"

# TODO(ekilmer): Parameterize llvm version
./vcpkg/vcpkg install \
  --triplet "${triplet}" \
  --debug \
  llvm-10 \
  @dependencies.txt
