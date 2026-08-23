# Finite-field squeeze audit: scalar-local rational channels

Date: 2026-08-23  
Status: adjacent staged patch; no package/source integration and no kernel run

## Decision

The next rigorously justified compiler change is a scalar-local root-free fast
path in `DirectRootChannelCompilerV2.wl`.  The current V2 path selects
`RootFree` only when the declared field rank is zero.  Consequently every
rational `E`, `C`, or `BBar` scalar in a rank-2/rank-3 physical block still
pays root-branch replacement, polynomial field reduction, recursive norm
inversion, and its checks.  The independent audit of V2 had already identified
this mismatch between the advertised and implemented fast path.

The frozen CF300 A0 compiled cache makes the payoff concrete: all 16 diagonal
`E`/`C` scalars are serialized with grade shape `{q,0,0,0}` inside a rank-2
bundle.  They are two thirds of the 24 `E`/`C`/`BBar` source scalars before
counting any root-free forcing entries.  V1 proves their grade shape, while the
current V2 compiler unnecessarily routes them through rank-2 inversion.

The staged patch canonicalizes branch placeholders once, then uses the direct
path whenever the canonical rational scalar contains no placeholder.  It pads
the scalar to the full grade vector `{q,0,...,0}` of length `2^rank`, so the V1
tree/column ABI is unchanged.  It recomposes that full vector with
`TRFieldCompose` and requires `Together[reconstructed-expression]===0` before
returning.  Unknown fractional powers and a failed branch replacement remain
fail-closed.  Algebraic scalars retain the existing recursive inversion path.

This patch is deliberately adjacent to the External V2 prototype.  Do not
apply it while any source-hashed mission still pins the V2 file.  It is not a
package-promotion verdict and needs a managed synthetic plus CF300 physical
differential before adoption.

## Other audit findings

### Targeted epsilon-free factor census (second staged patch)

`0002-target-epsilon-free-factor-census.patch` replaces the discriminator's
full trivariate `FactorList` on every unique channel numerator/denominator.
The old code kept only factors free of epsilon.  In the UFD
`Q[x,y][epsilon]`, a factor free of epsilon divides the polynomial iff it
divides every epsilon coefficient, so the complete desired factor set is
obtained by:

1. `CoefficientList[polynomial, epsilon]`;
2. the exact `PolynomialGCD` of those bivariate coefficients;
3. deduplication of equal contents with collision checks; and
4. `FactorList` only on the unique bivariate contents.

The patch rejects zero/non-polynomial/epsilon-dependent contents, retains the
existing per-operation time and memory constraints, collision-checks content
fingerprints, and exactly reconstructs each content from its `FactorList`
before any dlog form is admitted.  It does not alter the factor set, one-form
union, support, images, ranks, or acceptance gates.  This is the direct code
change aimed at the measured 1183-second census; its physical speedup still
must be measured under the managed pool.

### Batching and evaluator cost

The rational package sampler already hoists symbolic preparation, memoizes
prime forms, collapses epsilon coefficients, and vectorizes gauge blocks.
Fresh CF303 artifacts show prime-form cold misses in roughly `0.04--0.05 s`
and subsequent epsilon collapses around `0.003--0.005 s` for representative
small blocks; sharing reduced prime forms between broker helpers would save
too little to justify a new serialized trust boundary there.  For physical
CF300 direct images the measured warm cost remains point assembly plus repeated
whole-assembly validation; use the existing plan for a sealed process-local
handle and a batched polynomial evaluator rather than changing the rational
sampler blindly.

### FLINT threading

The fixed constrained-core adapter correctly passes `BackendThreads` to the
binary, and the C backend calls `flint_set_num_threads`.  Existing physical
evidence places native elimination below one percent of image wall and shows
only about `0.2 s` between one and four threads.  More FLINT threads are not a
meaningful single-image optimization.  Under eight-image throughput, use one
native thread per image; do not combine eight Wolfram image workers with four
FLINT threads each.  No default was patched because a scheduler-aware setting
must be provenance-bound and benchmarked under the actual pool.

### Support census and reconstruction

The 1183-second direct factor/support census is still avoidable work, but the
safe fix is architectural: consume cached exact channel IDs, factor forcing
denominators first, compute epsilon-free content before factorization, and
persist a core-bound census artifact.  There is no evidence for widening
support blindly.  Exact CRT/lifting at the measured `2.7 s` (rank 2) and
`9.3 s` (rank 3) is not a first-order target; incremental CRT should wait until
it exceeds five percent of wall.

### Serialization and acceptance

Repeated full `InputForm` serialization/fingerprinting is now a dominant
boundary cost in the direct workflow.  A future V6-style consumer should do
one exact legacy bridge, retain source-certified component seals, and validate
only changed suffixes.  Finite-field multi-prime/all-sign checks may reject or
triage candidates, but must not replace the exact lifted left witness,
unseen-prime residual, verified dlog potentials, and characteristic-zero
original-equation/family certificate.

## Validation supplied

`test_scalar_rootfree_patch_static.py`:

- applies the staged patch to a temporary copy and fails if the hunk drifts;
- requires the placeholder guard, full `2^rank` padding, independent compose
  check, canonical-pair creation, and checked return ordering;
- independently evaluates grade-zero vectors for ranks 0--3 at three primes
  and four scalars, requiring equality on every sign branch;
- includes short-vector, deleted-round-trip, and blind-fast-path mutants.

It launches no Wolfram/native job and changes no live source.

`test_epsilon_content_census_static.py`:

- applies patch 0002 to a temporary copy and runs the no-kernel lexical guard;
- enforces coefficient-GCD construction, content dedup/collision checks,
  bivariate-only factorization, and exact factor-product certification;
- checks the coefficient-content theorem independently on 256 deterministic
  exact `Q[x][epsilon]` cases (the same UFD argument as `Q[x,y]`), including
  repeated factors and missing epsilon coefficients; and
- rejects GCD-removal, dedup-removal, certificate-removal, and regression to
  full trivariate factorization mutants.

## Promotion gates

1. Wait until all V2/source-hashed consumers are terminal.
2. Apply the patch and run the existing rank-0--3 V1/V2 exact assembly and
   point differential with no messages.
3. Add explicit rational scalars inside nonzero-rank bundles; require the
   expected increase in `RootFreeFastPathCount` and unchanged grade counts.
4. Run the CF300 physical differential and require full `SameQ` V1 assembly,
   identical point images/ranks, stable source hashes, and material compile
   improvement.
5. Keep the exact acceptance gates unchanged; revert if performance is not
   material.
6. Differential-test patch 0002 on the frozen CF300 census: require exactly
   the same 40 unique rational channels, 12 factor dlogs, 48 union forms and
   exact factor/form fingerprints, with a material reduction from 1183 s.
