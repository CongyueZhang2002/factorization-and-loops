# GPU31 prototype results — 2026-09-01

## Environment and toolchain

- GPU: NVIDIA GeForce RTX 5080, compute capability 12.0, 16,303 MiB.
- Host/WSL driver stayed at 610.62; no display, kernel, firmware, or WSL driver
  package was installed or replaced.
- Installed from NVIDIA's official Ubuntu 24.04 CUDA repository: nvcc 13.0.88,
  NVVM/PTX compiler, CRT, CUDART and development stubs. The transaction was 12
  packages, 86.9 MB downloaded and 370 MB installed (356 MB under
  `/usr/local/cuda-13.0`).
- The original no-toolkit proof still works through `libcuda.so.1` and embedded
  PTX (`probe_driver.py`). The generic kernel is CUDA C compiled to PTX, then
  loaded through the same Driver API wrapper.

## Exactness

`self_test.py` passed all of the following:

- preserved rank-0 one-image TSV (division, negation, positive power);
- preserved rank-0 two-image TSV;
- preserved rank-3/eight-sheet TSV with all radical grades;
- a synthetic 31-bit-prime batch with 32 records, 32 explicit sheet images,
  1,184 postfix instructions and 1,024 canonical output values, compared
  exactly against the independent CPU postfix/channel reference.

The standalone Montgomery smoke also compared every GPU value exactly with a
CPU reference after independently checking Montgomery multiplication against
ordinary `% p` arithmetic.

## Measurements

All CPU measurements were pinned to one core. GPU memory was bounded; the
largest conservative estimate below was 137.07 MiB. The GPU was shared, so
these are engineering estimates rather than controlled hardware claims.

Specialized Montgomery recurrence, 1,048,576 values x 64 iterations:

| CPU | GPU kernel | GPU end-to-end | raw e2e | two 31-bit primes |
|---:|---:|---:|---:|---:|
| 269.491 ms | 1.734 ms | 3.678 ms | 73.27x | 36.63x |

Generic postfix evaluator, 2,048 programs x 512 images (1,048,576 outputs).
Each round includes multiply/add, a small power and a denominator inversion;
the CPU baseline uses one batch inversion per program/round across all images.

| rounds | instructions | CPU batch | GPU kernel | GPU e2e | raw e2e | two primes | ideal 16c + two primes |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 88,064 | 48.358 ms | 3.014 ms | 4.564 ms | 10.60x | 5.30x | 0.33x |
| 16 | 333,824 | 194.423 ms | 3.917 ms | 5.752 ms | 33.80x | 16.90x | 1.06x |
| 32 | 661,504 | 386.532 ms | 5.967 ms | 8.428 ms | 45.86x | 22.93x | 1.43x |

`GPU e2e` includes allocations and bytecode/input/output transfers, but excludes
the one-time CUDA context startup (246–288 ms in these runs). A persistent
worker is therefore mandatory; starting one process per family would erase the
gain on small batches. The 16-core column is deliberately pessimistic for the
GPU: it divides one-core raw speedup by 32 (16 perfectly scaling CPU cores and
twice as many 31-bit primes).

## Takeover notes

- The backend contains no family identifiers and does not touch live CF303
  scripts. It can be integrated below any producer that emits the neutral ABI.
- GPU canonicalization is implemented, including all eight rank-3 sheets and
  root denominators; it is not merely raw sheet evaluation.
- This prototype compiles complete record programs. It does not yet retain the
  CPU backend's unique-expression DAG reuse, so repeated operands can be
  evaluated more than once. A production adapter should choose between record
  programs and cached DAG slots from a reuse census.
- CUDA errors currently report aggregate singular/bytecode status. Production
  integration should add record/image diagnostics and a persistent worker or
  module cache.
- The results predict no max-core win for small/light records. Around the
  16-round synthetic complexity the GPU reaches parity with an ideal 16-core
  CPU even after the two-prime penalty; at 32 rounds it is about 1.43x ahead.
  Thus long three-root canonicalizations are credible GPU candidates, while
  short transports should remain on the already-running CPU route until a real
  payload census confirms enough work per launch.

## CF303-derived payload probe

The 25.4 MB block-25/14 deferred preparation was compiled against three
rank-three base images (24 sheets) and evaluated without expanding the
radicals. Its Wolfram text uses declared half-integer powers such as
`Delta^(3/2)`; the parser now lowers these exactly to powers of the matching
declared signed root and rejects undeclared fractional powers. An independent
two-sheet test covers both `Delta^(3/2)` and `Delta^(-3/2)`.

| records | terms | distinct source expressions | postfix instructions | host compile | CUDA JIT | CUDA kernels | total GPU evaluation |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 98 | 79 | 4,566,359 | 28.463 s | 315.190 ms | 514.585 ms | 0.861 s |

This is a useful GPU-sized payload, but it changes the next optimization
priority: parsing and recompiling 4.57 million repeated instructions for every
prime costs far more than evaluation. Production work should first cache a
prime-neutral compiled template and preserve the existing unique-expression
DAG (79 expressions here), then keep one CUDA context alive across primes.
Blindly adding more GPU launch machinery before those two changes would only
optimize the sub-second part.
