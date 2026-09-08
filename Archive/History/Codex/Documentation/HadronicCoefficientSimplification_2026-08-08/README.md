# Hadronic-coefficient simplification study

This directory records the simplification calculations performed on 7--8
August 2026 for the `pp -> h X` NLO and NNLO coefficients.  It distinguishes
three algebraic locations:

1. amplitude-pair coefficients before Kira substitution;
2. complete Kira-target coefficients before Kira substitution;
3. final master-integral coefficients after Kira substitution.

The main report is
`report/Hadronic_Coefficient_Simplification_Study.pdf`; its editable LaTeX
source is retained beside it.  `tables/performance.csv` contains every quoted
measurement, with the size metric named explicitly.  `METHOD_CATALOGUE.md`
records the tested orderings, mathematical action, advantages, disadvantages,
and measured outcome.  `SIMPLIFICATION_CONTRACT.md` records the maintained
card declarations and exact acceptance criteria.  `ARTIFACT_INDEX.md` maps each claim to the original
calculation artifact.  `report/RENDER_QA.md` records the final LaTeX and visual
inspection.

The directory deliberately does not duplicate multi-gigabyte coefficient
files.  Compact manifests, scripts, and earlier written records are copied
under `records/` and `scripts/`; large data are named by their original
absolute path in the artifact index.

## Main conclusions

- For NLO UU and TT, simplify complete target coefficients first, compose the
  master coefficients with the Kira rules, and then perform one bounded
  master-level cleanup.
- For NNLO UU, do not form a monolithic master coefficient.  Remove hadronic
  variables and certified positive roots entry by entry, store exact
  numerator-denominator pairs, merge only exactly equal denominators, and keep
  the smaller of the raw sum and its cancelled form.
- The TT calculation required a correction in BMHV dimensional bookkeeping.
  The dimension shift acts on the evanescent tensor integral, not on
  loop-independent factors inherited from the original Dirac trace.
- The maintained simplifier contains no `pp -> h X` fraction names,
  distribution product, Laurent valuation, invariant chamber, scale, or
  dimensionless coordinate.  The card declares those quantities.  Historical
  benchmark scripts remain process-specific because they reproduce the
  measurements in this record; they are not the maintained interface.
- NLO and NNLO use one exact kernel.  Assembled coefficients and lists of
  additive contributions differ only in scheduling; both undergo the same
  distribution, fraction-root, branch, forbidden-variable, and dimensionless
  normalization checks.
- The measured post-IBP coefficient work suggests roughly 6--10 hours on
  eight kernels for all 342 NNLO master coefficients, excluding analytic
  master integration, endpoint expansion, distribution reconstruction, and
  the remaining fixed-order ingredients.  No measured basis exists for a
  finish-time estimate of the complete exact NNLO hard function.
