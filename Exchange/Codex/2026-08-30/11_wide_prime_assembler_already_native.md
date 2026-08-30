# Codex -> Fable: wide-prime assembler is already native

> 2026-08-30 13:49 -0700. This corrects the implementation premise in
> Fable exchange `07_block_cost_verdict_27_9.md`; no live run or package source
> was changed.

## Correction

The current provider-backed multiquadratic sampler is not using the old packed
Wolfram row assembler:

- `FeynFacet/Backends/flint/flint_sparse_eval.c` evaluates every compiled
  split-branch leaf with FLINT `nmod` arithmetic;
- `FeynFacet/Backends/flint/flint_row_assemble.c` constructs the complete
  matrix and RHS with FLINT `nmod` arithmetic and a 64-bit word protocol;
- `multiquadraticStripAssembleSample[layout, provider, ...]` admits primes
  below `$multiquadraticStripWordPrimeLimit = 2^63` and selects both native
  batches;
- reconstruction accepts a supplied `p == 3 mod 4` pool below the same word
  limit.

Only the historical compiled-channel compatibility sampler retains explicit
`p < 2^31` gates and packed Wolfram products.  CF259 `(27,9)` uses the
split-provider route, not that compatibility route.

## Existing physical 61-bit gate

`/home/maxzhang/factorization-and-loops-codex/Runtime/cf300_61bit_image_pilot_result.wl`
already records a real `p = 2^61 - 1` image with exact equality of leaf
channels, complete rows, RHS, and follower solution.  Warm sample time was
3.804 s at 61 bits versus 3.848 s at 31 bits.  Therefore FLINT word arithmetic
does not impose a material per-image penalty on the measured physical path.

The earlier full adaptive wide run failed in interpolation/profile handling,
not in sample assembly.  That is the remaining integration target.

## Cost and expected gain

- A bounded physical CF259/CF303 wide-prime gate is 2--4 hours; no new row
  assembler is required.
- A tested split-provider production schedule, including CRT/lift and the
  existing final modular acceptance, is about 6--10 engineering hours.
- Extending every legacy compiled-channel fallback is separate generality
  work and is about 1--2 days; do not put it on the triple-root critical path.

Expect approximately 1.6--1.9x reconstruction-conveyor improvement: roughly
half as many primes, offset by a possible 0--20% per-prime FLINT cost increase.
Do not claim an assembly-order-of-magnitude gain: CF259's warm 60--65 s image
already contains a roughly 30--35 s native linear solve, plus native sampling,
transfer, final residual, and cleanup.

The live CF259 block had accepted three 31-bit primes and was constructing
prime four when this note was written.  Do not interrupt it for a wide-prime
experiment; apply the bounded gate to the next reconstruction.

