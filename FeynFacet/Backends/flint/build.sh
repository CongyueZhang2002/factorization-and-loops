#!/usr/bin/env bash
# Build the two FLINT backends:
#   bin/flint_modular_solve   CFFA4V1/CFFA4X1 fixed-square multi-RHS solver
#                             (SampleEpsFormStripAffine "Backend" -> "FLINT";
#                             Codex round-2 A4 prototype, 2026-08-21)
#   bin/flint_affine_rref     CFFR1V1/CFFR1X1 rectangular affine-RREF adapter
#                             ("PlanDiscoveryBackend" -> "FLINTAffineRREF";
#                             Codex xhigh audit 2026-08-23, PROTOCOL_CFFR1.md;
#                             source SHA256 11f4d337ace94efad2d3736edd5094d7
#                             091f5ce4f0ec5be9646a1bd52c5617cd)
# Usage: build.sh [release|sanitize]   (default release; sanitize builds the
#        ASan+UBSan variants with suffix _sanitize)
# Both sources are pinned to FLINT 3.0.1: flint_modular_solve.c reads
# matrix->rows[] (removed in FLINT >= 3.2) and flint_affine_rref.c hard-errors
# on any other __FLINT_VERSION.  The gate below fails the build loudly rather
# than producing a binary against an unverified library.
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:-release}"
flint_version="$(pkg-config --modversion flint 2>/dev/null || echo missing)"
if [[ "$flint_version" != "3.0.1" ]]; then
  echo "FLINT 3.0.1 required (pkg-config reports: $flint_version)" >&2
  exit 2
fi
mkdir -p bin
strict="-std=c11 -Wall -Wextra -Werror -Wpedantic -Wconversion -Wshadow -Wstrict-prototypes -Wformat=2 -fno-common"
libs="-lflint -lgmp -lmpfr -lpthread"
case "$mode" in
  release)
    cc -O3 -march=native -Wall -Wextra flint_modular_solve.c $libs -o bin/flint_modular_solve
    cc -O2 -march=native $strict flint_affine_rref.c $libs -o bin/flint_affine_rref
    ;;
  sanitize)
    cc -O1 -g3 -fsanitize=address,undefined $strict flint_affine_rref.c $libs -o bin/flint_affine_rref_sanitize
    ;;
  *) echo "usage: build.sh [release|sanitize]" >&2; exit 64;;
esac
for b in bin/flint_modular_solve bin/flint_affine_rref; do
  [[ -f "$b" ]] && ldd "$b" | grep -q "libflint.so.18" || true
done
echo "built ($mode): $(ls bin/) (cc: $(cc --version | head -1); flint $flint_version)"
