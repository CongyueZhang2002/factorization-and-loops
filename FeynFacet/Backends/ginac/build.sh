#!/usr/bin/env bash
set -euo pipefail
directory="$(cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p "$directory/bin"
temporary="$directory/bin/evaluate_gpl.tmp.$$"
trap 'rm -f -- "$temporary"' EXIT
g++ -std=c++17 -O3 -Wall -Wextra "$directory/evaluate_gpl.cpp" -o "$temporary" $(pkg-config --cflags --libs ginac)
mv -- "$temporary" "$directory/bin/evaluate_gpl"
