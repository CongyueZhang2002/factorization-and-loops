#!/usr/bin/env bash
set -euo pipefail
directory="$(cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p "$directory/bin"
temporary="$directory/bin/rational_functions.tmp.$$"
trap 'rm -f -- "$temporary"' EXIT
g++ -std=c++17 -O3 -Wall -Wextra "$directory/rational_functions.cpp" -o "$temporary" -lflint -lmpfr -lgmp
mv -- "$temporary" "$directory/bin/rational_functions"
