# Finite-field milestone assignment, 2026-08-20

Division of labor (user-directed): **Codex explores M1 and M2; Fable
owns M0 and standardizes every proven result into the package.**
Exploration means prototypes demonstrated on the frozen fixture;
standardization means the package implementation, schema, tests, and
certification — done on our side once your prototype's mathematics and
measured gain are established.

## M0 — done now (Fable)

- Instrumentation gap closed: `SampleEpsFormStripAffine` now records
  `SetupSeconds` (the previously untimed outer symbolic setup:
  alphabet, dlog table, residue layout, factor census, ansatz) and
  `PeakMemoryBytes`, alongside the existing Preprocessing/Sampling/
  Rank/AugmentedRank/LinearSolve/Nullspace timers. Unit test green.
- Regression oracle frozen:
  `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/BenchmarkStripBackends/frozen_M0/`
  — the (9,7) fixture plus the exactly verified 2026-08-20 result
  (offset {1,0}, 7 primes, {32, 15x6} samples, wall 7254 s). This is
  the system of record for every speedup claim.
- Open bookkeeping item for you: reconcile this fixture's 2144
  unknowns (1936 gauge + 208 residue, rank 2128, nullity 16) with the
  2026-08-19 packet's 1953/1937 for the same coupling — presumably an
  ansatz version change; please confirm so the fixture README can
  state it.

## M1 — Codex explores: the A1 constrained multi-RHS solve

Your proposal, your code. Deliverable for hand-off to standardization:

1. A working prototype (script or notebook-free .wl is fine) that, on
   the frozen fixture at one prime: discovers the normalization
   columns on a pilot sample, then solves every later sample as ONE
   factorization of the constrained system with nullity+1 right-hand
   sides, with per-sample residual checks against all original rows
   and the discard-and-replace rule for rank-losing samples.
2. Measured per-sample stage table on the frozen fixture (the new
   SetupSeconds/PeakMemoryBytes fields included), against the M0
   baseline ~60 s.
3. The exact end-to-end (9,7) solve reproduced through the prototype
   path with the both-variable Pfaffian residual identically zero.

## M2 — Codex explores: the affine-row state

Your correctness finding (verified on our side at
`FiniteFieldStripSolve.wl:519-526`: only ParticularSolution is
interpolated; the normalized nullspace is discarded). Deliverable:

1. A concrete representation decision with measurements: interpolate
   p(eps) and N(eps) fully, versus the modular Schur-complement carry
   into dependent blocks (we lean Schur — 16 x 2144 coordinate
   functions is a 16-fold interpolation load — but decide on data).
2. A demonstration on a real dependent pair — CF265's blocks below the
   CF254 embedding, or CF231's remaining row — showing a later block
   consuming the carried affine state, with the exact residual zero
   for the pair.
3. The installation contract: what
   `InstallEpsFormStripSolution`'s replacement receives (affine state
   in, constraints out), so we can standardize the seam.

## Standardization (Fable, after each exploration lands)

We port the proven algorithm into `FiniteFieldStripSolve.wl` /
`FiniteFieldEpsForm.wl` behind the existing public seams, keep the
frozen-fixture regression green, extend the unit tests, and re-certify
whatever records the change touches. Please deliver prototypes as
exact source files in the exchange per house convention; we will not
re-derive from prose.

Acceptance at every step, unchanged: exact, unspecialized,
both-variable Pfaffian residuals identically zero; affine row
constraints respected before installation.
