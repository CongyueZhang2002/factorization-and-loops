# 02 — CF300 `(12,9)` direct-provider image hot-loop profile

> **Recorded:** 2026-08-27 PDT
> **Purpose:** choose the next optimization from a physical image, not from
> source size or a synthetic solver benchmark
> **Disposition:** prioritize a sealed per-provider/per-prime sparse plan;
> native row assembly and wider primes follow only after remeasurement

## Reproducible probe

- Input: `CF300_12_9_input.wl` from the isolated
  `triple_root_2026-08-27_codex` result tree.
- Route: the package's general `SplitBranch` direct coefficient provider,
  deferred bundle, production gauge support and 53 one-forms.
- Prime/regulator image: `2147483423`, `eps = 1`.
- Process scope: one Wolfram main kernel, affinity CPUs 0--15; no family
  result or package artifact was written.
- Probe:
  `/home/maxzhang/factorization-and-loops-codex/Runtime/profile_cf300_image_phases.wls`
- Result:
  `/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_image_profile_20260827/profile_result.wl`
- Source HEAD: `a4eefe1ccf2da247e24ee92aba5bc10e5a82702f` plus the current uncommitted
  Round-B/Codex work.
- `MultiquadraticStripSolve.wl` SHA-256:
  `e52f4ddca9ea18facc44d814a60d1919c37f2cedd373315e2ead87ede84741d3`.

## Measurement

| phase | wall seconds | fraction of sample |
|---|---:|---:|
| complete sample | 182.927 | 100% |
| coefficient evaluation | 171.678 | 93.8% |
| split sparse compile/cache calls | 136.634 | 74.7% |
| split sparse arithmetic | 14.072 | 7.7% |
| row assembly | 8.138 | 4.4% |
| preflight, including rejected candidates | 3.024 | 1.7% |
| normalization | 0.000051 | negligible |

Shape and work counts:

- 2,260 unknowns, 64 equations per accepted point;
- 37 accepted points and 222 attempted points (the expected rank-three
  split-point rejection cost is visible but cheap because preflight occurs
  before large-entry evaluation);
- final matrix `2368 x 2260`;
- 7,400 large-entry evaluations;
- exactly 7,659 sparse compile/cache calls = 207 scalar occurrences for each
  of 37 accepted points;
- only 148 misses and 7,511 hits;
- compiled cache size 20,704,064 bytes;
- zero substitution fallbacks.

One-time construction in this isolated cold process cost 210.279 s for
preparation and 36.947 s for direct-provider census. Those costs must stay
separate from the repeated image loop.

## Diagnosis

The cache is functioning semantically but not computationally. Every one of
the 207 scalar occurrences at every accepted point calls
`multiquadraticStripScreenCompileCached`. Even a hit constructs and hashes a
key containing the complete raw expression, root records, kernel-local root
symbols, variables, and prime. The physical entries are large enough that
7,511 successful lookups cost far more than the modular evaluation they
protect.

This explains the previous 2--4 minute intervals between physical image
solves. It also establishes that neither FLINT elimination nor the exact
all-row residual is the current dominant phase.

## Optimization decision

First build one authenticated split-sparse plan per provider and prime:

1. enumerate unique scalar expressions and their active-root subsets once;
2. compile each unique leaf once;
3. bind positional/integer occurrence maps for `E`, `C`, deferred-bundle
   operands and coefficients, and one-forms;
4. have every point consume the plan directly, with no raw-expression hash or
   compilation call in the hot loop;
5. retain the exact substitution fallback for leaves that could not compile
   and fail closed on prime/provider/root-order mismatches.

The measured upper bound after only this change is roughly
`182.9 - 136.6 = 46.3 s` per image, about 3.95x faster before native code.
The bound is deliberately conservative: plan construction still costs the
148 real misses once per prime.

After remeasurement:

- if sparse arithmetic remains material, batch the compiled plan in a native
  word-size evaluator;
- if row assembly grows above 25% of the optimized image, move its fixed
  xor/product-grade fill to native C/OpenMP;
- then use the same safe native arithmetic for a 61-bit-prime pilot;
- benchmark 2/4/8 image concurrency only after the per-image CPU/thread
  profile is explicit. The current image already uses several cores and
  blind concurrency risks duplicating 20 MB caches and saturating the same
  16-core allowance.

Promotion gate for the first change: exact planned/unplanned channel and
matrix equality on rank 0--3 fixtures and this physical image; no fallback or
typed-failure regression; at least 3x coefficient-phase and 2x complete-image
speedup. If it misses those thresholds, do not retain substantial machinery.
