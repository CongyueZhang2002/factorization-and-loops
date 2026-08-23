# Candidate dependency manifest: FLINT modular solve backend

Status: **external prototype only; package integration not authorized or
performed**.

## Identity

- Dependency: FLINT (`libflint` / `libflint-dev`)
- Installed distribution version used: `3.0.1-3.1build1`, amd64
- Runtime SONAME: `libflint.so.18`
- Upstream license for the library: LGPL-2.1+
- Platform measured: x86-64 Linux under WSL
- Direct runtime libraries observed by `ldd`: `libflint.so.18`,
  `libmpfr.so.6`, `libgmp.so.10`, `libm.so.6`, `libc.so.6`
- Prototype API: `nmod_mat_solve`, `nmod_mat_mul`, `nmod_mat_equal`,
  `flint_set_num_threads`

## Prototype artifacts

- Source: `codex_ff_round2_2026-08-21/codex_a4_flint_solve.c`
- Source SHA-256:
  `05884dad1c794d4905b8a7030fc3e88f60781ac9cfe14046cc98baadd5c3c644`
- Local binary SHA-256:
  `84ed33f2bba73910fc97b9d7e559c34f9961df82a35a0df063b69ff2d001ccd3`
- Result record SHA-256:
  `3609d0a7d2e4e27723746c9fac485050717d517e766a2b7d4faa71e3a888b206`
- Build command:
  `cc -O3 -march=native -Wall -Wextra codex_a4_flint_solve.c -lflint -lgmp -lmpfr -lpthread -o codex_a4_flint_solve`

The binary format is versioned (`CFFA4V1` input, `CFFA4X1` output),
little-endian, and stores the square matrix and all right-hand sides as
unsigned 64-bit row-major words. The helper solves all 17 right-hand sides in
one call, verifies `A.X == B` inside FLINT, and writes the solution for an
independent Wolfram `SameQ` check.

## Worthiness benchmark

Frozen fixture: CF254 `(9,7)`, actual sampled constrained core
`2144 x 2144`, 17 right-hand sides, 1,825,840 nonzeros. Conversion,
37,065,512-byte file transfer, FLINT input, solve, FLINT verification,
solution output, and Wolfram import are counted.

| prime | Wolfram sparse | Wolfram dense packed | FLINT 1 thread, total | FLINT 4 threads, total | exact solution check |
|---|---:|---:|---:|---:|---|
| 31-bit `2147483423` | 13.413 s | 14.072 s | 1.248 s | **0.555 s** | both FLINT results `SameQ` to both Wolfram results |
| 61-bit `2305843009213693951` | 19.003 s | 20.093 s | 1.658 s | **0.650 s** | both FLINT results `SameQ` to both Wolfram results |

The four-thread end-to-end gains versus Wolfram sparse are 24.2x at 31 bits
and 29.2x at 61 bits. Disk conversion/transfer is about 0.10 seconds, so the
result is comfortably above a dependency-worthiness threshold.

## Integration gates still required

1. Explicit package-dependency authorization.
2. A portable build/detection policy and supported-platform matrix.
3. A package MANIFEST entry derived from, but not replaced by, this candidate.
4. A hard prime-width guard: the current packed O2 Wolfram evaluator assumes
   products below `2^62` and must not feed 61-bit primes without an unpacked,
   compiled `mulmod`, or backend-native evaluation path.
5. Typed fallback to the Wolfram sparse backend when FLINT is absent or a
   sampled constrained core is singular.
6. CI tests at representative 31- and 61-bit primes, including exceptional
   samples and all-original-row residual checks.

