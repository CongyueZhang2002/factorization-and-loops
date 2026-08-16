# Hard classes 97/77/79 — the eps-form route (state at 2026-08-16 14:00)

This directory supersedes the eps-graded route (parent directory) as the
PRODUCTION plan for the last three connection classes.  The eps-graded
solutions there remain valid and become the independent verification
track.

## Why the route changed

The multi-day "these classes admit no eps-form" verdict was wrong on two
counts, both found 2026-08-16 after an external review:

1. **Wrong chart.** CANONICA/Libra search over RATIONAL transformations.
   In the original (v,w) chart the required transformation contains
   sqrt(Kallen) / sqrt(Q), so the search was structurally doomed —
   its failure carried no information.  In the rationalizing charts
   (97/77: v=xy, w=(1-x)(1-y); 79: w=-t(1+t+v)/(1+t)) the search is
   admissible for the first time.
2. **Wrong usage.** The earlier "Libra exhausted" verdict came from
   treating a SINGLE Rookie call as a verdict.  Rookie applies one
   balance per call; normalization is an iteration.

Irreducibility (certified, and re-certified in-chart for 77/79) does NOT
obstruct an eps-form: canonical forms are gauge transformations, not
factorizations.

## The pipeline (each stage certified)

    chart slice at numeric y
      -> Fuchsify finite loci, then infinity (in xi = 1/x)
      -> two-point Lee balances: projector = right eigenvector at the
         lowered point (x) left eigenvector at the raised point,
         integer-guarded (reject any move producing surd spectra)
      -> CANONICA constant transform (regulator substituted by
         SymbolName, never by symbol identity)
      -> entrywise check A/eps eps-free

Scripts (copied to Scripts/): balance_loop5.wls (single slice),
pooled_sweep.wls (many slices, 1 main + 4 subkernels via
HCTMissionPool), symrep97.wls (symbolic-y replay), pool_phase2.wls
(branch-consistent sampling of the normalized family).

## Results in hand

- **Class 97**: slice eps-forms at 10 y-values, letters
  {x, 1-x, 7x-3, 7x+3, 4x+3}|_{y=3/7} and the analogous specializations
  at every other point (see pooled_sweep.log in scratch).  The 11-step
  balance path REPLAYS SYMBOLICALLY: `symnorm_c97.wl` holds
  A_norm(x,y,eps) and Ttot(x,y,eps) with ZERO residual integer offsets
  at every locus {0, 1, y, -y, y/(y-1), infinity} — i.e. the
  two-variable system is normalized; only the final eps-factorizing
  gauge remains.
- **Class 77**: slice eps-forms at 10 y-values, letters
  {x, 1-x, 3x-7, 7x-11, 7x-3}|_{y=3/7}.  Symbolic replay not yet run
  (its recorded path is 1 balance + CANONICA's internal ansatz, so it
  needs either a deeper symbolic descent or our own rational-ansatz
  finisher).
- **Class 79**: normalized only down to badness 6.  Its slice has
  integer offsets hosted on an IRREDUCIBLE QUADRATIC locus, invisible
  to the current (linear-factor-only) census and unreachable by
  pairwise rational-point balances; the trace identity proves they are
  there (finite offsets sum to 0, infinity sums to +4).  A consult on
  the standard mechanism (q(x)-shear vs conjugate-pair balances vs
  CANONICA at higher ansatz degrees) is in
  External/FableBridge/prompts/c79_quadratic_locus_2026-08-16.md.

## Next steps (in order)

1. **97 finish**: phase 2 = CANONICA on slices of the NORMALIZED family
   (pool_phase2.wls, was running at handoff) -> T2(y_i) samples ->
   phase 3 = entrywise rational interpolation in y -> phase 4 = exact
   two-variable gate (both transformation identities + stage-1
   ValidateCanonicalForm).  Only the gate is load-bearing;
   interpolation is a candidate generator.
2. **77**: same, after either symbolic descent or the finisher.
3. **79**: implement the quadratic-locus mechanism from the consult,
   then rerun the pipeline.
4. Ledger to 173/173; hard classes join canonical transport; cross-check
   the eps-graded solutions (parent directory) against the canonical
   ones — two independent derivations of the same functions.
5. Only then: boundary constants (regularity conditions first, per the
   review), endpoint modes, and the commits that were deliberately held
   back pending genuinely solved classes.
