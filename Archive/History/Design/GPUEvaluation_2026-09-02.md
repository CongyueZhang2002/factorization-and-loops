# GPU evaluation for FeynFacet: decision note (2026-09-02)

Question (overhaul goal 6): should any hot path of the package move to
the RTX 5080?  Rule: only on a measured hot path where the GPU wins.

## What was measured (Codex, 2026-09-01/02, Development/2026-09-01/gpu31_deferred_backend in the Codex tree)

Workload: finite-field evaluation of the CF259 connection (47 masters,
rank-3 root cover, 946 postfix programs at 88 images = 11 points x 8
sheets, 88.8 million postfix instructions per prime), i.e. the stage that
produces the common dlog residues of a triple-root family.

| route | per-evaluation time | notes |
|---|---:|---|
| CUDA kernel (one thread per program-image pair) | 1.126 s kernel, 1.249 s wall | plus 0.37 s context creation once |
| OpenMP CPU evaluator, 16 threads | 0.358 s | batch inversion shared across the 88 images, packed one-word instructions |
| OpenMP CPU evaluator, 8 threads | 0.480 s | |
| OpenMP CPU evaluator, 1 thread | 3.969 s | |

End-to-end common-dlog computation of CF259 (13 CRT primes + one fresh
prime, FLINT RREF and multi-RHS solve unchanged): native CPU 10.03 s vs
CUDA 20.52 s. Both produce byte-identical residues and letters.

Synthetic scaling (2,048 programs x 512 images): the GPU is 5-23x faster
than ONE core, which is 0.3-1.4x of an ideal 16-core CPU after charging
the two-31-bit-primes-per-61-bit-prime penalty; parity is reached only
around the heaviest synthetic rounds.

## Decision

No GPU path is added to the package in this overhaul.

- The measured hot finite-field stage is served better by the CPU
  evaluator as both implementations stand (3.1x), because the win came
  from the evaluation layout (one traversal per program over all images,
  one batch inversion per INV opcode), not from raw parallelism.
- A competitive CUDA kernel would need a cooperative-lane redesign
  (sharing inversions across image lanes); that is a research project
  whose expected gain over the CPU route on these payload sizes is at
  most a small factor, while the pipeline's remaining cost is elsewhere
  (symbolic construction, rational reconstruction, FLINT linear algebra).
- No Python GPU stack is installed (no cupy, torch or numba); only the
  raw driver API through ctypes plus nvcc 13.0. Integrating that into
  production adds an environment dependency for no measured gain.

## When to revisit

Revisit if a census shows a batch with (programs x images) well above
10^6 per launch and long programs (hundreds of instructions), for example
a rank-3 canonicalization campaign over many families at once, or the
stage-4 numerical evaluation of the assembled hard function at many
kinematic points. Measure the CPU evaluator first at 16 threads; the GPU
must beat it by more than 2x end-to-end to justify the dependency.

## Where the CPU evaluator should live

The OpenMP evaluator (`postfix_native.cpp`, family-neutral, C ABI) is a
candidate for `FeynFacet/Backends/flint/` beside the existing FLINT
adapters, behind the same request/response protocol discipline
(PROTOCOL_*.md). Adoption is tracked in the overhaul plan under goal 6.
