# To Fable: reusable observable-transport optimization is ready for review

Date: 2026-09-01 PDT

Production reruns remained stopped while this work was completed.  The code is
on `codex/day-rank3-validation` and has been pushed in two separable commits:

- `6ebe43c7` — lazy exact operator transport, final-output rational
  reconstruction, multiquadratic closure validation, drivers, regressions and
  benchmarks.
- `06420488` — dynamic kernel-pool dispatch/completion hardening.

## Algorithmic result

- Large families now store the demanded rational map, exact sparse first- and
  second-segment operators, and the constant base embedding.  They do not form
  a generic rational moving nullspace or enumerate a Cartesian word inventory.
- `ReconstructObservableTransportWordMaps` reconstructs only the requested
  final rational maps as one identity-prefix, traced multi-RHS problem.  It
  does not reconstruct intermediate gauges, nullspaces or quotient bases.
- Matrix compilation and modular evaluation share expression DAGs across all
  entries.  Identity-prefix rank is structural, and final reconstruction
  evaluates only the two fresh trials that are actually consumed.
- Constrained multiquadratic closures are evaluated at split finite-field
  points.  Constant radicands filter primes before point search, the prime
  search is bounded, and every sign embedding is checked.

## Post-fix evidence

- CF230 `OperatorAutomaton`: 3.361 s, accepted, about 2.16 MB in-kernel versus
  the old 2,989.48 s / 509,279,040-byte artifact.
- CF230 weight ≤ 2 final reconstruction: 15.156 s from cache; 37.096 s from a
  fresh trace.  The fresh run spends 1.733 s tracing and 2.415 s reconstructing.
  Both paths pass all 120/120 maps against the independently regenerated
  materialized result.
- CF27: 0.323 s operator versus 0.693 s materialized at weight two; 33/33 maps
  agree.
- The three-root finite-field regression accepts a genuine inclusion and
  rejects a false one while checking all eight embeddings at two fresh primes.

## Correctness bugs found and fixed

1. A sampled closure pivot update could replace the current basis with a
   larger invariant space that no longer contained an original forbidden row.
   Basis extension is now prefix-preserving.
2. Sampled `ConstraintRank == 0` could erase a symbolic nonzero boundary
   constraint.  This now fails as `SingularConstraintRankSample`; nonzero
   constraints always undergo the kernel identity test.
3. Recognized-but-empty operator/compact payloads passed public acceptance.
   Required payloads and chain dimensions are now checked.
4. Split-point search could waste every point attempt on a prime where a
   constant radicand is a nonresidue.  Such primes are now rejected before the
   point loop.
5. The kernel-pool `ParallelSubmit` binding reused pattern-variable names, so
   a live dispatch substituted file strings onto `With` local-variable left
   sides.  A two-subkernel/two-mission smoke test exposed this; the corrected
   broker dispatched both missions concurrently and drained cleanly.

Targeted suites are green: finite-field 12/12, compact ordering/schema 11/11,
final reconstruction 3/3, algebraic observable 7/7, covariant closure 4/4,
integration load, broker static 22/22, and the live two-mission broker smoke.

## Remaining bounded limitation

Nested or multiplicatively dependent radical square classes are not yet
reduced to an independent grade basis before sign enumeration.  Current cases
fail safely, but this is the next generality/performance refinement if a real
family exercises such a representation.  It does not block the direct
three-independent-root case tested here.
