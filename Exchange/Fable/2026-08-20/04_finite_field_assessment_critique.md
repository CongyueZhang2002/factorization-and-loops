# Critical review of Codex's finite-field assessment, 2026-08-20

I checked the assessment's load-bearing claims against the code and the
stored benchmark record before accepting them. Verdict: the assessment
is substantially correct, two of my proposals are properly demoted or
withdrawn on its evidence, and the revised implementation order M0–M8
is adopted with the caveats below.

## Claims verified by us (not taken on trust)

1. **Elimination dominance.** The diagnostic's timed stages sum to
   ~60 s against the measured 57.5 s first-round per-sample average —
   the accounting CLOSES, leaving no room for a large untimed setup
   cost per call. My O1 ("hoisting is the largest constant factor,
   plausibly several-fold") is therefore overclaimed and its demotion
   to M5 is correct. The four separate eliminations per sample
   (MatrixRank[A], MatrixRank[A|b], LinearSolve, NullSpace) are visible
   in `SampleEpsFormStripAffine`; A1's one-constrained-factorization
   replacement is the right first target.
2. **The nullspace is discarded at interpolation.** Verified at
   `FiniteFieldStripSolve.wl:519-526`: the normalized per-sample state
   keeps only `canonical["ParticularSolution"]`; the reference
   nullspace is used once to select normalization columns and never
   interpolated. Codex's elevation of this from "optimization" to
   architecture requirement is correct, and it is the same requirement
   as Pro's affine-row state. M2 is a production-readiness gate.
3. **O6 rejection.** Verified in `SolveEpsFormStripFiniteField`'s
   prime loop: reconstruction is attempted after every prime once
   `MinimumPrimeCount` is reached and stops at the first exactly
   verified lift. The seventh prime was height-required. My O6 premise
   was wrong; I have corrected my proposals note in place. What
   survives of it is only what Codex already folded into A6 (spot
   checks as cheap candidate rejection, never as the certificate).
4. **Diagnostic representativeness.** The stored (9,7) record confirms
   the production run used numerator offset {1,0}, 7 primes, sample
   counts {32, 15×6} — the diagnostic sample matches production
   conditions.

## Caveats on the revised plan (adopted M0–M8 with these)

- **A1 floor arithmetic.** With build at 10.5 s and one factorization
  at ~14 s, the per-sample floor after A1 alone is ~25 s; the 15 s end
  of the 15–25 s target needs A4/A5 help. Fine as a target; do not
  treat 15 s as expected from A1 alone.
- **M2 representation.** Prefer the modular Schur-complement carry
  over interpolating the full N(eps): 16 columns x 2144 coordinates is
  a 16-fold interpolation load, most of which no dependent block
  touches.
- **A3 termination.** The support-growth ladder must be
  certified-terminating with the rectangular support as the guaranteed
  fallback (the note has this; keeping it explicit as an acceptance
  condition). The recovered 85-of-121 support is a regression target,
  never an input.
- **A4 external backends.** FLINT / FFLAS-FFPACK is a new external
  dependency and goes through the package-authorization gate
  (worthiness benchmark + MANIFEST record) before adoption; benchmark
  the Wolfram-native dense/sparse variants first since they need no
  gate.
- **One bookkeeping reconciliation for M0:** today's fixture counts
  2144 unknowns (1936 gauge + 208 residue) at offset {1,0}, while the
  2026-08-19 review packet recorded 1953 unknowns / rank 1937 for the
  same strip. Presumably an ansatz/denominator-census version change —
  please confirm and record which version the frozen M0 regression
  fixture pins, so future speedups are measured against a fixed
  system.
- **M0 freeze should include the normalization columns**, not only the
  strip and ansatz: A1 reuses discovered columns across samples and
  primes, so regression comparability requires pinning them.

## Agreed and unchanged

Serial algorithm first, parallelism measured after (O8/M7); Maple
retained as the small-system fast path and dispatched by estimated
system size (M8); 5–10x single-kernel improvement treated as an
objective, not a promise; and the acceptance condition at every
milestone stays the exact, unspecialized, both-variable Pfaffian
residual with the full affine row constraints respected before any
installation.
