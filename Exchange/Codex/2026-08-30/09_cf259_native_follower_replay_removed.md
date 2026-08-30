# CF259 native follower replay removed

## Decision

Per the user's production-validation policy, native constrained regulator
images no longer repeat an all-original-row Wolfram matrix product inside the
block.  `flint_modular_solve` already verifies its fixed multi-RHS core before
returning success.  The independent acceptance of the reconstructed
off-diagonal block remains the existing fresh-point, all-provider-equation
finite-field residual (two fresh primes and three fresh images per prime in
the reconstruction hardening contract).  No replacement intermediate check
was added.

## Real CF259 evidence

The `(27,9)` system has 11,008 equations, 10,888 unknowns, rank 10,819 and
nullity 69, hence 70 right-hand sides.  The removed Wolfram replay attempted
an 11,008 by 10,888 matrix times a 10,888 by 70 solution matrix: about 8.39
billion modular products for every regulator image.  In the terminated run,
both images remained single-core in this replay for more than 10 minutes,
using about 15.6 GB and 11.1 GB respectively.

The same saved real payload under the new code completed successfully in
122.17 s:

- sample assembly: 69.41 s;
- eight-thread FLINT core solve: 33.13 s;
- Wolfram all-row replay: 0 s;
- backend: `FLINT`;
- result: `OK`, method `NativeConstrainedCoreVerified`.

This is at least a fivefold cold-image end-to-end improvement; the deleted
stage itself improves from more than 600 s to zero.

## Code and validation

- Commit: `043bb2d Remove native follower all-row replay` (pushed to `main`).
- Main implementation:
  `FeynFacet/Private/MultiquadraticStripSolve.wl`.
- Focused tests:
  - constrained affine plan: 26/0;
  - follower image wave: 12/0;
  - regulator reconstruction: 18/0;
  - reconstruction hardening: 12/0.
- The hardening suite explicitly confirms that fresh validation keys are
  disjoint from training keys, all fresh provider residuals vanish for a good
  reconstruction, and a corrupted reconstructed coordinate is rejected.

## Live continuation

CF259 was relaunched alone in
`factorization-and-loops-codex/Runtime/2026-08-30_triple_root_pool_v69` with
8 Wolfram subkernels and 16 dynamically allocated native-core tokens.  It
accepted all 17 banked sector-27 strips by mathematical checkpoint identity
and is solving only `(27,9)`.  CF300 is already complete and is not running.
