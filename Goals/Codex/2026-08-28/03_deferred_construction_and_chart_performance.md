# Deferred construction and chart-performance goals

## Eliminate repeated exact work

- [🟢] Compile an algebraic deferred bundle only once when the modular
  nonzero census is inconclusive.  Reuse the same preparation and intern
  cache for exact materialization; preserve the existing bundle and
  materialized result ABIs.

- [🟢] Prove the adaptive path on nonzero, algebraically inconclusive,
  typed-refusal, and exact-fingerprint fixtures.  The focused bundle suite
  passes 47 assertions with no failures.

- [🟡] Split cold operand compilation into a pure parallel descriptor phase
  and deterministic serial interning/provenance phase.  The measured target
  is the 153.75-second CF259 `(21,18)` compile, dominated by independent
  `Together` and denominator-factorization work on 37 operands.

- [ ] Add a bounded family/frame-local descriptor cache only if physical
  adjacent-block measurements show substantial byte-weighted reuse.  Never
  cache bundle-local operand IDs, factor IDs, or provenance indices.

## Prefer rational charts over large direct systems

- [🟢] Promote the generic `Kallen3Bilinear115` chart used by CF300 into the
  catalog and require exact root, parent-map, inverse, and catalog-wide
  verification.

- [🟢] Add the simultaneous source-sign image
  `Kallen2Bilinear115`.  This follows from
  `lambda2(v,w)=lambda3(-v,-w)` and invariance of `1-4 v w`; it replaces
  CF303 `(21,18)`'s 64,616-unknown direct rank-two system with a rational
  chart solve.

- [ ] Check whether any other direct rank-two dispatch is merely a missing
  source-variable symmetry of a certified catalog chart before enlarging the
  multiquadratic ansatz.

## Remaining physical bottlenecks

- [🟡] Measure CF300's exact chart-to-source gauge substitution separately
  from finite-field solving.  The gauge solved in 34.6 seconds, while source
  transport remains the dominant live stage.

- [ ] Allow an unresolved strip with a matching authenticated input seal to
  resume from its persisted input instead of rebuilding the block equation.
  Base compatibility on the construction ABI and mathematical source
  fingerprint, not an unrelated whole-driver hash.

- [ ] Promote compiler parallelism only after serial/parallel bundle content
  and fingerprints agree exactly and the physical wall reduction is at least
  1.5x without unacceptable peak memory.
