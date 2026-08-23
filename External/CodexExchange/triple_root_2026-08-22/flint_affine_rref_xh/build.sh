#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

mode=${1:-release}
observed_flint=$(pkg-config --modversion flint 2>/dev/null || true)
if [[ "$observed_flint" != "3.0.1" ]]; then
  echo "error: flint_affine_rref requires pkg-config FLINT 3.0.1, got '${observed_flint:-missing}'" >&2
  exit 2
fi

mkdir -p bin
common=(
  -std=c11
  -Wall
  -Wextra
  -Werror
  -Wpedantic
  -Wconversion
  -Wshadow
  -Wstrict-prototypes
  -Wformat=2
  -fno-common
)
libraries=(-lflint -lgmp -lmpfr -lpthread)

case "$mode" in
  release)
    output=bin/flint_affine_rref
    options=(-O3 -march=native -DNDEBUG)
    ;;
  sanitize)
    output=bin/flint_affine_rref_sanitize
    options=(-O1 -g3 -fno-omit-frame-pointer -fsanitize=address,undefined)
    ;;
  *)
    echo "usage: $0 [release|sanitize]" >&2
    exit 2
    ;;
esac

cc "${common[@]}" "${options[@]}" flint_affine_rref.c \
  "${libraries[@]}" -o "$output"

runtime_flint=$(ldd "$output" | awk '/libflint[.]so/{print $1; exit}')
if [[ "$runtime_flint" != "libflint.so.18" ]]; then
  echo "error: unexpected FLINT runtime SONAME '${runtime_flint:-missing}'" >&2
  exit 2
fi

printf 'built %s (%s; FLINT %s; %s)\n' \
  "$output" "$(cc --version | head -1)" "$observed_flint" "$runtime_flint"
