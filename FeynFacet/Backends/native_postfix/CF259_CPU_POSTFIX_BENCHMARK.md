# CF259 native CPU versus CUDA postfix benchmark

Date: 2026-09-02

## Result

An optimized native CPU evaluator is faster than the existing CUDA evaluator
on the exact cached CF259 connection workload.  At 16 OpenMP threads, the
median complete warm CPU call is **0.358141 s**, compared with **1.125818 s**
for the matching CUDA kernels and **1.248582 s** for the CUDA evaluator wall
time excluding context creation.  Thus the measured 16-thread CPU route is
**3.144x faster than the GPU kernel interval** and **3.486x faster than the
GPU evaluator wall interval**.

Every one of the 25 reported CPU evaluations was byte-identical to the CUDA
reference: 388,784 uint32 values, or 1,555,136 compared bytes per evaluation.

## Exact workload and semantics

- Cached input: `Runtime/2026-09-01_observable_transport_triple_final/cf259_dlog_gpu/programs.pkl`
- Prime: 2,147,483,647
- 946 unique connection programs evaluated at 88 images (11 points times all
  8 sheets of the rank-3 multiquadratic cover)
- 88,832,667 postfix instructions: 25,518,530 `MUL`, 24,891,657 `INPUT`,
  16,269,071 `POW`, 10,917,924 `CONST`, 5,690,728 `ADD`, 4,599,377 `SUB`,
  472,743 `INV`, and 472,637 `NEG`
- 4,418 output records, each assembled from its cached two-factor term
- The same 8-channel root-sheet canonicalization as `ff31_channels`
- Montgomery arithmetic with R = 2^32 and the same `CONST`, `INPUT`, `ADD`,
  `SUB`, `MUL`, `POW`, `INV`, and `NEG` meanings as the CUDA implementation

The exporter invokes the existing `GPUBackend.evaluate` and appends its raw
ordinary-residue result to the benchmark payload.  The C++ process compares
its final output directly against that reference with `memcmp`; the separate
shell check `tail -c 1555136 .cf259_cpu_payload.bin | cmp - .cf259_cpu_last_output.bin`
also succeeds.

## Warm scaling

Each row is the median of five complete calls.  Ranges are the five observed
call-wall times.  Calls were pinned with `taskset -c 0-15`,
`OMP_PROC_BIND=close`, and `OMP_PLACES=cores`; the evaluator reported the exact
CPU list shown.

| Threads | CPUs | Median call (s) | Five-run range (s) | Speedup vs 1 thread | vs GPU kernel | vs GPU evaluator wall |
|---:|:---|---:|---:|---:|---:|---:|
| 1 | 0 | 3.968600 | 3.911290–4.154020 | 1.000x | 0.284x | 0.315x |
| 2 | 0–1 | 2.036020 | 2.016240–2.045970 | 1.949x | 0.553x | 0.613x |
| 4 | 0–3 | 0.974871 | 0.953774–1.007890 | 4.071x | 1.155x | 1.281x |
| 8 | 0–7 | 0.480181 | 0.479468–0.495731 | 8.265x | 2.345x | 2.600x |
| 16 | 0–15 | 0.358141 | 0.354038–0.378028 | 11.081x | 3.144x | 3.486x |

The 16-thread median phase times were 0.357880 s for expression evaluation,
0.000070821 s for assembly, and 0.000097542 s for root-channel
canonicalization.  The postfix programs, not the two final stages, dominate.

## Cold/setup measurements

- C++ compilation (`g++ 13.3.0`, `-O3 -march=native -fopenmp`): 0.80 s,
  127,496 KiB peak RSS.
- CPU process payload read: 0.128 s in the final sweep (0.128–0.238 s across
  recorded processes).  This is a process-cold read with a warm OS page cache;
  the system cache was not disrupted merely to force physical cold I/O.
- CPU benchmark peak RSS: 357,052 KiB.
- One-time Python pickle read: 0.446094 s; request construction: 0.003993 s;
  packing the 88.8 million two-word instructions into one-word instructions:
  3.509621 s.
- CUDA context creation: 0.369159 s; upload: 0.075347 s; kernel interval:
  1.125818 s; download: 0.001391 s.  Context plus evaluation wall time was
  1.617741 s.
- The exporter, including pickle load, packed-payload creation, one CUDA
  reference evaluation, and a 357,975,140-byte payload write, took 7.989746 s
  and 1,434,384 KiB peak RSS.

Host: Intel Core Ultra 7 265K, 20 single-threaded logical CPUs visible in
WSL2; benchmark limited to CPUs 0–15.  Device: NVIDIA GeForce RTX 5080.

## Why the CPU route wins here

The evaluator traverses each program once while operating on all 88 images.
This amortizes opcode dispatch across the image batch and allows one
Montgomery batch inversion per `INV` opcode instead of 88 independent field
exponentiations.  Programs are scheduled in descending instruction-count
order with dynamic OpenMP allocation.  Instructions are packed into one
uint32.  The root-channel transform is an exact 8-point Walsh-Hadamard
transform instead of 64 signed additions per base/record.  These are
mathematical/evaluation-layout gains, not relaxed validation.

The comparison is output-apples-to-apples, but it is not an instruction-for-
instruction hardware comparison: the current CUDA kernel assigns one thread
to each program-image pair and therefore does not share inversions across the
88 images.  A redesigned CUDA kernel that cooperates across image lanes could
recover part of that gap.  The evidence nevertheless says that the native CPU
route is the better production candidate for this cached workload as the two
implementations stand.

## GPU suitability beyond this benchmark

This payload is already the cached deferred postfix representation consumed
by the GPU.  The benchmark performs no symbolic expansion and does not
materialize rational expressions.  However, its programs were compiled from
the already-produced `EpsFormX`/`EpsFormY`; it therefore measures finite-field
evaluation of the final connection, **not** the upstream symbolic construction
or canonicalization that produced that connection.

Stages with genuine GPU-shaped parallelism are evaluations of many independent
entries at many independent finite-field points and all root sheets.  CF259,
CF300, and CF303 all provide that point × sheet × program concurrency, so
postfix evaluation during modular sampling, replay, or residue extraction can
plausibly use a GPU when the batch is large.  The present measurement also
shows that concurrency alone is insufficient: across-image batch inversion
and CPU vectorization beat the existing one-thread-per-image GPU kernel.

Record assembly and root-channel projection are parallel but are far too small
here to justify a separate GPU route.  Dense RREF/multi-RHS solving is the
FLINT stage and is not represented by this benchmark; it has matrix-level
dependencies and should remain with FLINT unless a separately benchmarked
finite-field GPU linear-algebra implementation wins.  CRT accumulation and
rational reconstruction are likewise separate integer stages; their
coordinate parallelism does not make them part of the postfix GPU result.
Finally, symbolic `Together`, factorization, Maple normalization, and gauge
construction are not accelerated by this evaluator.  They become GPU-eligible
only after being reformulated as independent pointwise finite-field programs.

## Reproduction artifacts

- `export_cf259_cpu_benchmark.py`: exact fixture exporter and CUDA-reference generator
- `cf259_cpu_postfix_benchmark.cpp`: optimized OpenMP evaluator
- `run_cf259_cpu_benchmark.sh`: pinned build/export/five-repeat sweep
- `cf259_cpu_postfix_export.json`: exporter and CUDA timing record
- `cf259_cpu_postfix_benchmark_results.jsonl`: final CPU raw timings

The 358 MB generated payload, compiled binary, and last-output file are local
scratch artifacts and are intentionally excluded from version control.
