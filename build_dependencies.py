#!/usr/bin/env python3
import argparse
import os
import platform
import shlex
import shutil
import subprocess
import sys
from pathlib import Path


parser = argparse.ArgumentParser(
    prog="build_dependencies.py",
    description="Build cxx-common dependencies using vcpkg.",
    epilog="Please see the README.md file for more information.",
)
parser.add_argument(
    "--verbose",
    action="store_true",
    help="Print more verbose information from vcpkg during package installation",
)
parser.add_argument(
    "--release",
    action="store_true",
    help="Build only release versions with triplet as detected in this script.",
)
parser.add_argument(
    "--target-arch",
    choices=["x64", "arm64"],
    help="Override target triplet architecture for cross-compilation",
    default=None,
)
parser.add_argument(
    "--asan",
    action="store_true",
    help="Build with ASAN triplet as detected in this script",
)
parser.add_argument(
    "--upgrade-ports",
    action="store_true",
    help="Upgrade any outdated packages in the chose install/export directory. WARNING: this could cause long rebuild times if your compiler has changed or your installation directory hasn't been updated in a while.",
)
parser.add_argument(
    "--export-dir",
    type=Path,
    help="Export built dependencies to chosen directory path",
    default=None,
)
parser.add_argument(
    "VCPKG_ARGS",
    nargs="*",
    help="Extra args to pass to 'vcpkg install', like LLVM version, other ports, vcpkg-specific options, etc.",
)
args = parser.parse_args()

VCPKG_ROOT_DIR = Path(
    os.environ.get("VCPKG_ROOT") or Path(__file__).resolve().parent / "vcpkg"
)


def err(msg: str) -> None:
    print(f"[!] {msg}", file=sys.stderr)
    sys.exit(1)


def msg(msg: str) -> None:
    print(f"[+] {msg}")


def err_if_not_installed(bin: str) -> None:
    if shutil.which(bin) is None:
        err(f"Please install the package providing '{bin}' command for your OS")


msg(f"Using VCPKG_ROOT='{VCPKG_ROOT_DIR}'")
if args.release:
    msg("Only building Release binaries")
if args.asan:
    msg("Building ASAN binaries")
if args.upgrade_ports:
    msg("Upgrading any outdated ports")
if args.export_dir:
    msg(f"Exporting to directory: {args.export_dir}")
msg("Passing args to `vcpkg install`:")
msg(f"  {shlex.join(args.VCPKG_ARGS)}")

plat = platform.system()
if plat != "Windows":
    for pkg in ["git", "zip", "unzip", "cmake", "python3", "curl", "tar", "pkg-config"]:
        err_if_not_installed(pkg)

# vcpkg tries to download some pre-built tools but only x86_64 is widely supported
if platform.machine() != "x86_64" and plat == "Linux":
    os.environ["VCPKG_FORCE_SYSTEM_BINARIES"] = "1"

os.environ["VCPKG_DISABLE_METRICS"] = "1"

msg("Building dependencies from source")

# Figure out triplet based on host info
triplet_arch = ""
cpu = platform.machine()
if cpu == "x86_64":
    triplet_arch = "x64"
elif cpu == "aarch64" or cpu.lower() == "arm64":
    triplet_arch = "arm64"
else:
    err(f"Unsupported CPU: {cpu}")

triplet_os = ""
if plat == "Darwin":
    triplet_os = "osx"
elif plat == "Linux":
    triplet_os = "linux"
elif plat == "Windows":
    # Static library linkage and dynamic CRT
    triplet_os = "windows-static-md"
else:
    err(f"Unknown platform: {plat}")

# Only build Release config for host dependencies
host_triplet = f"{triplet_arch}-{triplet_os}-rel"
target_triplet = f"{args.target_arch or triplet_arch}-{triplet_os}"

# Build type for target triplet
if args.release:
    msg("Only building Release versions")
    target_triplet = f"{target_triplet}-rel"
else:
    msg("Building Release and Debug versions")

# ASAN triplet
if args.asan:
    msg("Building with Address Sanitizer")
    target_triplet = f"{target_triplet}-asan"

repo_dir = Path(__file__).parent
vcpkg_info_file = repo_dir / "vcpkg_info.txt"
vcpkg_dir = repo_dir / "vcpkg"

export_dir = vcpkg_dir
if args.export_dir:
    export_dir = Path(args.export_dir)

extra_vcpkg_args = [
    f"--triplet={target_triplet}",
    f"--host-triplet={host_triplet}",
    f"--x-install-root={export_dir}/installed",
]

extra_cmake_usage_args = [
    f"-DVCPKG_TARGET_TRIPLET={target_triplet}",
    f"-DVCPKG_HOST_TRIPLET={host_triplet}",
]

with vcpkg_info_file.open() as f_vcpkg_info_file:
    vcpkg_repo_url, vcpkg_commit = [x.strip() for x in f_vcpkg_info_file.readlines()][
        :2
    ]
msg(f"Using vcpkg repo URL: {vcpkg_repo_url}")
msg(f"Using vcpkg commit: {vcpkg_commit}")

if not vcpkg_dir.exists():
    msg(f"Cloning vcpkg to {vcpkg_dir}")
    subprocess.check_call(["git", "clone", vcpkg_repo_url])

# Set existing vcpkg directory to correct upstream
subprocess.check_call(
    ["git", "remote", "set-url", "origin", vcpkg_repo_url], cwd=vcpkg_dir
)
subprocess.check_call(["git", "fetch", "origin"], cwd=vcpkg_dir)
subprocess.check_call(["git", "checkout", vcpkg_commit], cwd=vcpkg_dir)

print("")
msg("Bootstrapping vcpkg")
ccache = shutil.which("ccache")
if ccache:
    os.environ["CMAKE_C_COMPILER_LAUNCHER"] = ccache
    os.environ["CMAKE_CXX_COMPILER_LAUNCHER"] = ccache
bootstrap_script = "bootstrap-vcpkg.bat" if plat == "Windows" else "bootstrap-vcpkg.sh"
subprocess.check_call([vcpkg_dir / bootstrap_script])

# Copy required buildsystem scripts to export directory (this is what the
# `vcpkg export` command does).
# See the following `export_integration_files` function for the list of files.
# This should be updated when that is updated.
# https://github.com/microsoft/vcpkg-tool/blob/1533e9db90da0571e29e7ef85c7d5343c7fb7616/src/vcpkg/export.cpp#L259-L279
if export_dir != vcpkg_dir:
    msg("Copying required vcpkg files to export directory")
    export_dir.mkdir(parents=True, exist_ok=True)
    (export_dir / ".vcpkg-root").open("a").close()  # touch
    integration_files = [
        Path("scripts/buildsystems/msbuild/applocal.ps1"),
        Path("scripts/buildsystems/msbuild/vcpkg.targets"),
        Path("scripts/buildsystems/msbuild/vcpkg.props"),
        Path("scripts/buildsystems/msbuild/vcpkg-general.xml"),
        Path("scripts/buildsystems/osx/applocal.py"),
        Path("scripts/buildsystems/vcpkg.cmake"),
        Path("scripts/cmake/vcpkg_get_windows_sdk.cmake"),
    ]
    for f in integration_files:
        (export_dir / f).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(vcpkg_dir / f, export_dir / f)

print("")
msg("Building dependencies")
msg("Passing extra args to `vcpkg install`:")
msg(f"\t{shlex.join(extra_vcpkg_args)}")

overlays = (repo_dir / "overlays.txt").read_text().splitlines()

vcpkg_exe = vcpkg_dir / "vcpkg"
if args.upgrade_ports:
    print("")
    msg("Checking and upgrading outdated ports")
    subprocess.run(
        [
            vcpkg_exe,
            "upgrade",
            *extra_vcpkg_args,
            *overlays,
            "--allow-unsupported",
            *args.VCPKG_ARGS,
        ]
    )

    user_input = input("Confirm? [Y/N] ")
    if user_input.lower() in ("y", "yes"):
        subprocess.check_call(
            [
                vcpkg_exe,
                "upgrade",
                *extra_vcpkg_args,
                *overlays,
                "--no-dry-run",
                "--allow-unsupported",
                *args.VCPKG_ARGS,
            ]
        )
    elif user_input.lower() in ("n", "no"):
        err("Aborting")
    else:
        err(f"Error: Input {user_input} unrecognised.")

    # Exit after upgrading
    exit(0)

dependencies = (repo_dir / "dependencies.txt").read_text().splitlines()
subprocess.check_call(
    [
        vcpkg_exe,
        "install",
        *extra_vcpkg_args,
        *overlays,
        *dependencies,
        *args.VCPKG_ARGS,
    ]
)

print("")
msg("Investigate the following directory to discover all packages available to you:")
msg(f"  {export_dir / 'installed' / 'vcpkg'}")
print("")
msg("Set the following in your CMake configure command to use these dependencies!")
msg(
    f"  -DCMAKE_TOOLCHAIN_FILE=\"{export_dir / 'scripts' / 'buildsystems' / 'vcpkg.cmake'}\" {shlex.join(extra_cmake_usage_args)}"
)

print("")
if plat != "Darwin" and (cpu == "aarch64" or cpu.lower == "arm64"):
    msg("On ARM, you also need to set environment variable:")
    if plat == "Windows":
        msg("  $Env:VCPKG_FORCE_SYSTEM_BINARIES = 1")
    else:
        msg("  export VCPKG_FORCE_SYSTEM_BINARIES=1")
