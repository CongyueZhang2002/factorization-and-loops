#!/usr/bin/env bash
set -euo pipefail
directory="$(cd -- "$(dirname -- "$0")" && pwd)"
mkdir -p "$directory/bin"
temporary="$directory/bin/finite_integrals.tmp.$$"
trap 'rm -f -- "$temporary"' EXIT
g++ -std=c++17 -O3 -fopenmp -Wall -Wextra "$directory/finite_integrals.cpp" -o "$temporary" -lflint -lmpfr -lgmp
mv -- "$temporary" "$directory/bin/finite_integrals"

temporary="$directory/bin/finite_taylor.tmp.$$"
g++ -std=c++17 -O3 -fopenmp -Wall -Wextra -Wno-unused-function "$directory/finite_taylor.cpp" -o "$temporary" -lflint -lmpfr -lgmp
mv -- "$temporary" "$directory/bin/finite_taylor"

temporary="$directory/bin/frobenius_taylor.tmp.$$"
g++ -std=c++17 -O3 -fopenmp -Wall -Wextra -Wno-unused-function "$directory/frobenius_taylor.cpp" -o "$temporary" -lflint -lmpfr -lgmp
mv -- "$temporary" "$directory/bin/frobenius_taylor"
