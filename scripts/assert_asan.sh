#!/usr/bin/env bash

# Simple script to check whether a (Linux) file was compiled with address
# sanitizer
# Usage:
#   assert_asan.sh <file>

if ! (nm "$1" | grep -q "__asan"); then
  echo "Missing asan $1"
  exit 1
fi
