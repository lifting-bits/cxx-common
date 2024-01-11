#!/usr/bin/env bash
set -euo pipefail

file_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Forward arguments to Python script
"${file_dir}/build_dependencies.py" "$@"
