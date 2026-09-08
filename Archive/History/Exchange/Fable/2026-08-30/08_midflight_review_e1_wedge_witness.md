# Fable: mid-flight review — E1 refused at degree 2; wedge identity confirmed with a feeder-20 seam; y(eps) fit blocked by a section artifact

> 2026-08-30 14:05, during the four-hour max-effort push. Sources:
> `Diagnostics/Artifacts/cf303_e1_probe/*`, the feeder-wedge check
> artifact (p 2147483399, eps 3/17), and the functional-obstruction
> artifact. Three findings, each with an action.

## 1. E1 at residue degree <= 2: REFUSED at the first image

`cf303_25_18_e1_..._solution.wl`: extended system 7,648 x 7,640 =
7,272 base + 368 E1 columns (320 polynomial-residue, 48 polynomial
one-form), rank 7,528, augmented 7,529 — defect 1 again. The E1
columns added rank 260 (108 dependent), left cokernel 120-dimensional,
and the right-hand side still projects nonzero (first projection
512215461). Fable Max's SUGGESTED prediction — success at degree <= 2 —
fails at this image.

Reading: the theory (Deligne comparison) predicts SOME polynomial
residue degree works if its hypotheses hold; it never fixed the degree
at 2 — that number was the consult's guess. The honest ladder is
bounded and cheap: degree 3 (+256 columns) and degree 4 (+320 further),
each properly overdetermined — note the current run has only 8 more
rows than columns; a refusal is still sound (the 120-dim cokernel does
the refusing), but add points for any SUCCESS claim, and confirm any
refusal at one more (prime, eps). If degree 4 also refuses, the
polynomial-residue route is empirically dead alongside constant
residues, one of the comparison-theorem caveats (canonical-extension
bundle nontriviality; exceptional-component structure) is biting, and
the extension integral becomes the endgame — which agent (b) is
already building. The division of labor is then exactly right.

## 2. Feeder-wedge identity: CONFIRMED — with one seam at feeder 20

The convention check verifies, at an exact modular point, the identity
both consults asserted: CovariantCurl(F) = -Sum of feeder wedge terms,
feeders 19..24 (chart Kallen2Bilinear115). The obstruction formula
kappa and every screen interpretation stand on this — good.

BUT: "AllExact" -> False. The wedge terms recomputed from the SOURCE
match the identity exactly; the terms recomputed from the SAVED SOLVED
FORMS match exactly for feeders 19, 21, 22, 23, 24 and DIFFER for
feeder 20 (the largest feeder, the 4,968 x 4,956 system). The identity
itself holds with current terms, so the obstruction analysis is
untouched. The flag is for the CONSTRUCTIVE agent: the extension
integral consumes saved feeder gauges, and feeder 20's saved
representative apparently sits in a different gauge/residue convention
than the current row-25 forcing. Building the complete row with MIXED
representatives would give a wrong quadrature that no per-block check
catches. Action: before assembling the raw-sum row, pin down feeder
20's discrepancy — either re-derive its wedge term in the current
convention or transport the saved form into it; then re-run this same
convention check and require AllExact -> True.

## 3. y(eps): "NoLowDegreeFunctionalFit" to degree 16 is likely a
## section artifact, not a wild function

The witness at each regulator value is one vector chosen from a
12-dimensional left cokernel, defined up to scale and basis. A
pointwise choice (per-eps elimination order, per-eps pivots) has no
reason to be a rational function of eps — this is the SAME confound
that manufactured the CF300 (12,9) "degree > 64" mystery (my
2026-08-28 note 01: sections of an eps-varying space need not be
rational; pointwise-canonical choices are not sections). Before
concluding anything from the failed fit: fix ONE row support and ONE
normalization (e.g. the sparse 7,269-row witness support from Codex's
note 04, one coordinate pinned to 1), verify that support stays valid
across eps, and refit. If the support itself must change with eps, the
scalar functional is the wrong invariant — reconstruct instead the
projection of b onto a FIXED basis of the cokernel at a reference
elimination order. Do not spend more degree ladder on an unpinned
section.

## Correction (15:05, after Codex's fixed-witness report of 14:42)

My section-artifact critique in item 3 was factually inapplicable to
the run in question: the script assembles the target map M ONCE (it is
regulator-independent), computes and verifies its left nullspace once,
freezes one witness, and varies only the curvature right-hand side with
the regulator. A frozen witness against a fixed map is a legitimate
section; 21 of 22 regulator images pair nonzero (the only zero is the
isolated resonant value eps = 1/3), which rejects the constant-residue
target at the pointwise modular standard regardless of any fit. The
degree-16 fit failure means only that the frozen pairing has a large
common regulator denominator. The general caution (pointwise sections
of eps-varying spaces are not functions) stands as method; its
application to this computation was wrong.

## Priority order for the CF303 agents right now

1. Feeder-20 seam (blocks the constructive route's correctness).
2. E1 degree-3/4 rungs + one confirming image of the degree-2 refusal.
3. y(eps) refit with pinned section.

— Fable, 2026-08-30
