# Deferred construction and chart-performance goals

## Eliminate repeated exact work

- [🟢] Compile an algebraic deferred bundle only once when the modular
  nonzero census is inconclusive.  Reuse the same preparation and intern
  cache for exact materialization; preserve the existing bundle and
  materialized result ABIs.

- [🟢] Prove the adaptive path on nonzero, algebraically inconclusive,
  typed-refusal, and exact-fingerprint fixtures.  The focused bundle suite
  passes 47 assertions with no failures.

- [ ] Revisit cold operand compilation only with a materially different
  algorithm.  A pure parallel-descriptor prototype preserved the bundle
  exactly but improved the physical CF303 `(21,18)` compile only from
  144.3 s to 142.1 s (1.015x), so its roughly 200 lines were rejected and
  removed.

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

- [🟡] Parallelize exact chart-to-source gauge substitution entry by entry.
  CF300 `(12,9)` measured 34.6 s for the finite-field solve but 1,108.8 s
  for four independent source-gauge substitutions.  Commit `7423612`
  sends one exact entry per helper, retains the largest entry locally,
  honors the strip deadline, and passed 65 focused assertions plus an
  actual TaskBroker run (`Parallel`, two helpers, three tasks, exact result).
  A hard-family wall-time comparison is in progress.

- [🟢] Eliminate redundant deferred-bundle pullback only when the exact
  materialized BBar is cryptographically bound to that bundle.  Commit
  `58df9d1` mints one semantic certificate, rejects a mutated BBar, and
  lets rational-chart routes consume the already-materialized forcing while
  chartless direct-MQ fallback retains the bundle.  This targets measured
  silent pullbacks of about 9 minutes on CF300 `(12,7)` and 10 minutes on
  CF303 `(21,18)`; 158 focused construction, compatibility, deadline, and
  resume assertions passed.

- [🟢] Replace CF259 `(21,16)` source-frame provider compilation with a
  chart-first deferred DAG.  The old measured path was 2,450.9 s
  (2,330.6 s bundle compile plus 106.4 s materialization).  The final
  physical path writes the chart-deferred strip in 19 s and materializes it
  in the rational chart in 16.1 s: about 35 s total, a roughly 70x reduction.
  Chartable blocks also skip the unused source-frame nonzero census.

- [🟢] Replace the chartless compiler's linear factor-equivalence scan with
  an exact multiquadratic grade-channel key modulo sign.  Exact keys preserve
  first-occurrence numbering; the old semantic scan remains only when grade
  reduction cannot form a key.  Production bundles omit occurrence-level
  audit records while retaining every factor, orbit norm, and global pole
  bound consumed by the solver.

- [🟢] Reject the tempting raw chart-assembly shortcut on physical evidence.
  It assembled CF259 `(21,16)` in 2.5 s but produced a 4.24-million-leaf
  intermediate whose final exact `Together` was still running after 38 s,
  already slower than the complete 16.1 s factored chart route.  The current
  operand factorization is therefore useful preconditioning, not removable
  bookkeeping.

- [ ] Allow an unresolved strip with a matching authenticated input seal to
  resume from its persisted input instead of rebuilding the block equation.
  Base compatibility on the construction ABI and mathematical source
  fingerprint, not an unrelated whole-driver hash.

- [ ] Promote compiler parallelism only after serial/parallel bundle content
  and fingerprints agree exactly and the physical wall reduction is at least
  1.5x without unacceptable peak memory.
