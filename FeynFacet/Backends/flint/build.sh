#!/usr/bin/env bash
# Build the eight native backends:
#   bin/flint_modular_solve   CFFA4V1/CFFA4X1 fixed-square multi-RHS solver
#                             (ComputeOffDiagonalBlockFiniteFieldImage "Backend" -> "FLINT";
#                             Codex round-2 A4 prototype, 2026-08-21)
#   bin/flint_affine_rref     CFFR1V1/CFFR1X1 rectangular affine-RREF adapter
#                             ("PlanDiscoveryBackend" -> "FLINTAffineRREF";
#                             PROTOCOL_CFFR1.md)
#   bin/flint_sparse_eval     MQSE1P2/MQSE1Q1/MQSE1X1 batched factored-sparse
#                             rational evaluator for split branches
#   bin/flint_row_assemble    MQRA1V1/MQRA1X1 multiquadratic row assembler
#   bin/flint_regulator_interpolate
#                             FFRI1V1/FFRI1X1 batched rational-in-regulator
#                             interpolation (PROTOCOL_FFRI1.md)
#   bin/flint_mpoly_gcd       FFMG1P1/FFMG1Q1/FFMG1G1 exact integer
#                             multivariate GCD and numerator cofactor
#                             (PROTOCOL_FFMG1.md)
#   bin/flint_deferred_ast_eval
#                             DAGO1V1 exact modular evaluator for preserved
#                             BlockEquationDeferredV1 term forests
#   bin/flint_deferred_path_jet
#                             DAPJ1V1 selected-sheet truncated path-jet
#                             evaluator for the same preserved term forests
# Usage: build.sh [release|sanitize]   (default release; sanitize builds the
#        ASan+UBSan variants with suffix _sanitize)
# The native adapters are pinned to FLINT 3.0.1: flint_modular_solve.c reads
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
    cc -O3 -march=native $strict flint_sparse_eval.c $libs -o bin/flint_sparse_eval
    cc -O3 -march=native $strict flint_row_assemble.c $libs -o bin/flint_row_assemble
    cc -O3 -march=native $strict -fopenmp flint_regulator_interpolate.c $libs -o bin/flint_regulator_interpolate
    cc -O3 -march=native $strict flint_mpoly_gcd.c $libs -o bin/flint_mpoly_gcd
    cc -O3 -march=native $strict -fopenmp flint_deferred_ast_eval.c -o bin/flint_deferred_ast_eval
    cc -O3 -march=native $strict -fopenmp flint_deferred_path_jet.c -o bin/flint_deferred_path_jet
    ;;
  sanitize)
    cc -O1 -g3 -fsanitize=address,undefined $strict flint_affine_rref.c $libs -o bin/flint_affine_rref_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict flint_sparse_eval.c $libs -o bin/flint_sparse_eval_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict flint_row_assemble.c $libs -o bin/flint_row_assemble_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict -fopenmp flint_regulator_interpolate.c $libs -o bin/flint_regulator_interpolate_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict flint_mpoly_gcd.c $libs -o bin/flint_mpoly_gcd_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict -fopenmp flint_deferred_ast_eval.c -o bin/flint_deferred_ast_eval_sanitize
    cc -O1 -g3 -fsanitize=address,undefined $strict -fopenmp flint_deferred_path_jet.c -o bin/flint_deferred_path_jet_sanitize
    ;;
  *) echo "usage: build.sh [release|sanitize]" >&2; exit 64;;
esac
for b in bin/flint_modular_solve bin/flint_affine_rref bin/flint_sparse_eval bin/flint_row_assemble bin/flint_regulator_interpolate bin/flint_mpoly_gcd bin/flint_deferred_ast_eval bin/flint_deferred_path_jet; do
  [[ -f "$b" ]] && ldd "$b" | grep -q "libflint.so.18" || true
done
echo "built ($mode): $(ls bin/) (cc: $(cc --version | head -1); flint $flint_version)"
