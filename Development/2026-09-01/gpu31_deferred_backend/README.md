# GPU31 deferred evaluator

Isolated, family-neutral prototype for exact finite-field evaluation on CUDA.
It reads the existing neutral `DeferredASTRequestV1` request and
`BlockEquationDeferredV1` preparation, compiles each output record to postfix
bytecode, evaluates every explicit root sheet on the GPU, performs the
root-grade/Walsh canonicalization on the GPU, and writes `DAGO1V1` rows.
Nothing here is imported by or integrated into the package.

## Build and test

The Makefile deliberately fixes nvcc to one compilation thread.

```sh
make -j1
taskset -c 0 make -j1 check
```

Exact evaluator use:

```sh
./deferred_gpu.py INPUT.wl REQUEST.txt OUTPUT.bin
```

The default launch chunk is at most 1,000,000 `(program,image)` threads. The
conservative accounting assumes the full 128-byte postfix stack is local
memory, keeping tests well below 512 MiB. `ptxas` actually reports an 8-byte
stack frame for `ff31_eval` on `sm_120`.

## Neutral bytecode

The instruction set has eight operations:

```
CONST INPUT ADD SUB MUL POW INV NEG
```

Values stay in 32-bit Montgomery form (`R=2^32`) until the channel kernel
converts them back to ordinary residues. `INPUT` addresses `x`, `y`, `eps`,
then up to three explicit signed root-sheet inputs. The host authenticates
each supplied root value and its declared square before launching CUDA.

The accepted expression grammar mirrors the native scratch backend's
fail-closed grammar: integers, the three request symbols (qualified contexts
allowed), `+ - * /`, parentheses, signed integer powers, and only the declared
`Sqrt[...]` generators. Primes must be odd and below `2^31`.

## Benchmarks

```sh
taskset -c 0 ./nvcc_smoke 1048576 64
taskset -c 0 ./benchmark_postfix 2048 512 4
taskset -c 0 ./benchmark_postfix 2048 512 16
taskset -c 0 ./benchmark_postfix 2048 512 32
```

`benchmark_postfix` compares exact GPU output with a one-core vector CPU
reference that uses batch inversion across images. Its `two_prime_speedup`
divides raw speedup by two to conservatively account for replacing one 61-bit
prime with two 31-bit primes. `ideal16c_two_prime_speedup` additionally assumes
perfect 16-core CPU scaling.

See `RESULTS.md` for measured results, scope, and takeover notes.
