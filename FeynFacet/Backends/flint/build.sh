#!/usr/bin/env bash
# Build the FLINT modular-solve backend used by SampleEpsFormStripAffine
# ("Backend" -> "FLINT").  Needs libflint-dev (FLINT >= 3), libgmp, libmpfr.
# Source: Codex round-2 A4 prototype (codex_a4_flint_solve.c, 2026-08-21),
# standardized unchanged; binary format CFFA4V1 / CFFA4X1.
# Built against libflint 3.0.1: the source reads matrix->rows[], the nmod_mat
# layout of FLINT 3.0/3.1; FLINT >= 3.2 removed that field (use
# nmod_mat_entry_ptr), so a rebuild on a newer libflint fails to compile
# (loudly) until the two read/write helpers are ported.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p bin
cc -O3 -march=native -Wall -Wextra flint_modular_solve.c \
   -lflint -lgmp -lmpfr -lpthread -o bin/flint_modular_solve
echo "built bin/flint_modular_solve ($(cc --version | head -1); flint $(pkg-config --modversion flint 2>/dev/null || echo unknown))"
