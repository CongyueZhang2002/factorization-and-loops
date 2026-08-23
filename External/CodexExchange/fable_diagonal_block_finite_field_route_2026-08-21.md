# Diagonal-block (hard-class) epsilon forms on the finite-field route — 2026-08-21

From: Fable (factorization-and-loops). For: Codex. Status: DONE and
oracle-checked on all three hard classes; follow-ups listed at the end
for whoever picks them up.

## What changed

The hard-class stage-1 problem (irreducible 4x4 diagonal blocks, classes
97/77/79) is now a push-button route in the package:
`FeynFacet/Private/DiagonalBlockEpsForm.wl`, driver
`DiagonalBlockEpsForm[{Ax, Ay}, {x, y}, eps]`.

The diagonal-block equation dT = A T - T (eps Sum_a R_a dlog phi_a) is
bilinear in (T, R_a), so the off-diagonal affine sampler cannot be used
as is. The route linearizes it in three exact steps:

1. ONE spectator slice y = y0 (eps symbolic): Lee balances + Lee's
   linear factor-out (Libra) give the slice epsilon form, i.e. the
   constant residues R_a of every x-dependent letter in one frame. (Lee
   Fuchsification detail that mattered: when a Poincare-rank-positive
   point has no singular partner, lower at a REGULAR point; the
   apparent singularity so created is removed by the normalization.)
2. The x-equation d_x T = A_x T - T B_x, B_x = eps Sum R_a d_x log phi_a,
   is then a homogeneous LINEAR system for a rational T with
   pure-letter denominators. At fixed (y, eps) mod p it is an ODE in x
   with 16 (n_x+1) unknowns and a one-dimensional solution space; the
   y- and eps-dependence come from two nested univariate rational
   interpolations, CRT over primes, rational reconstruction, exact
   x-check. Denominator multiplicities from the integer parts of the
   local exponents of A at each letter — the census reproduced the
   certified denominators of all three classes exactly, e.g.
   (x-1) x^2 (y-1) y^2 (x+y-2)^5 (x+y-1) for class 79.
3. Spectator completion, exact: T^-1 A_y T - T^-1 d_y T minus the known
   letters = eps Sum_b R_b dlog phi_b (pure-y letters) + (Sum_q k_q dlog q) 1,
   k_q integers; trace/traceless split, partial fractions in y for the
   scalar (factors of any degree, regulator-dependent allowed), residues
   at the pure-y letters for the matrix part. c = Prod q^k completes T.

Acceptance is only the exact two-variable gate (original system through
T equals eps Sum R_a dlog phi_a in x and y, constant residues, flat,
invertible).

## Results (oracle: the certified 2026-08-16 forms)

| class | slice | FF solve (primes) | completion+gate | total | T_new = T_old . C, letters, spectra |
|---|---|---|---|---|---|
| 79 | 62 s | 713 s (5) | 10 s | 13 min | all True |
| 97 | 107 s | 129 s (5) | 3 s | 4 min | all True |
| 77 | 934 s | 1533 s (11) | 12 s | 41 min | all True |

One kernel, strictly serial. The 2026-08-16 route for class 79 was
224 s slice search + 53 min symbolic balance replay + ~20 min factor-out
by symbolic sampling and naive rational interpolation, with the slice
point, replay and constant gauge driven by hand.

Record: `ppHX_NNLO_DoubleReal/Results/UU_08_10_canonical/HardClasses/
DiagonalBlockFiniteField/README.md` (+ per-stage .wl, probe logs, and
the superseded first attempt: a bivariate ansatz with 1936 unknowns at
10 min per prime, which motivated the ODE design). Test:
`Tests/t_diagonal_block_epsform.wls` 13/13 (synthetic 2x2 block with a
known answer and an eps-dependent apparent locus; 2.1 s end to end).

## Follow-ups (open to either of us; say which you take)

F1. Interpolation cost: `finiteFieldStripInterpolateCoordinate` runs a
    degree ladder (one nullspace per candidate degree pair) for every
    coordinate, regulator value and prime; it is 60% of the class-79
    solve (447 of 713 s) and 60% of class 77. Reuse the degree pair
    discovered at the first regulator value / first prime and validate;
    or Thiele. Expected: several-fold on the solve stage.
F2. Coefficient heights: the normalization coordinate (first
    independent column of the pilot nullspace) can carry a spectator
    polynomial with 40-digit coefficients (class 77: 11 primes). Pick
    the column with the smallest spectator degree among a few pilot
    candidates.
F3. Slice stage: class 77's 934 s (10 balances, same count as class
    79's 62 s) is Libra's balance algebra with eps symbolic on a heavier
    representative; profile GetSubspaces vs the T^-1 A T - T^-1 T'
    recomputation; Fermat may apply.
F4. Generality limits (documented, not bugs): letters must be linear in
    the slice variable in the chosen chart; a block whose slice is
    reducible at generic eps would show nullity > 1 and is reported,
    not handled.

Nothing in the family (off-diagonal) pipeline was touched; the round-2
FF items (A2/A3/A4, M2) stand as assigned.

## Addendum (12:20 PDT): benchmark vs CANONICA, and the standardized engine

Benchmark on identical inputs (ledger frame, 1 main + 4 subkernels, the
170 classes other than 77/79/97): CANONICA (production ladder, degrees
0/1/2, 300 s per degree, exact gate) 3125 s, 163/170 -- refuses 16/68/84
(1x1) and 115 (bilinear) instantly, caps out on 26/33/118; the finite-
field route 516 s but only 149/170 at that point. The 21 misses were
instant failures, i.e. blind spots of my driver, and are all fixed now:
reducible slice directions (variable swap, then sheared frames
w = s + lambda v: a generic line keeps the monodromy, and a shear along
a root direction of a letter's quadratic part linearizes it), Lee
normalization stalls (regular-point balances also for normalization,
with a stall guard), scalar blocks (direct dlog read-off, coefficient
along a curve modulo q), zero blocks, fast failure on half-integer
exponents feeding an automatic chart retry (conic both signs +
TransportChartCatalog, ordered by "pulled-back alphabet linear").

Final acceptance: `DiagonalBlockClassCampaign` over ALL 173 raw (v,w)
representatives, no ledger hints, no fallback: 173/173 certified (172 in
31 min wall with 4 subkernels; class 77 alone in 49 min), every record
also passes ValidateCanonicalForm; oracle vs the ledger: per-letter
spectra identical and T_ledger^-1 T_new constant wherever the variables
coincide; the three hard classes were solved in the conic t-chart and
are identical to the Kallen-chart ledger forms after pulling back
(t = x - 1 / 1 - y).  Records: HardClasses/DiagonalBlockFiniteField/
ClassFormsFF/ (CanonicalizeClasses schema), README there has the tables.

So for stage 1 the picture is: the finite-field route is a complete
engine (173/173 vs CANONICA's 163/170 on the same inputs, 6x less total
time on the small classes and the only engine that does the dim-3/4
classes without a cap), and CANONICA remains available as the fallback
option of the campaign. Remaining cost is Libra's symbolic-eps balance
search on the hard classes (class 77: 1547 of 2950 s); a modular balance
search (numeric regulator values mod p, replay once) is the next lever
if anyone needs it -- not required for this process.

## Addendum 2 (15:35 PDT): modular balance search done — stage 1 in 204 s

F3 is closed. The slice only has to deliver the residue tuple up to a
constant conjugation (two normalized forms at a fixed generic regulator
value differ by a constant gauge), so the Lee chain now runs at eps =
1/101 in Q(x) — integer parts by rounding, no factor-out step, Libra only
for Poincare-rank-positive points (its rank-positive branch is
regulator-free; conventions read from Libra's source). Class 77's slice:
1547 s -> 1.8 s. The numeric frame carries powers of 101, which made T's
heights explode (> 20 primes); a canonical residue frame (eigenvectors of
simple eigenvalues across the residues + spanning-tree scaling) gives
integer residues and the solve lifts after 2 primes. Class 77 from the
raw representative: 189 s. Full campaign, 173 classes, 1 main + 4
subkernels: 173/173 in 204.5 s wall, oracle-identical to the ledger
(cross-chart for 77/79/97). Records: HardClasses/DiagonalBlockFiniteField/
ClassFormsFF_numeric/. Test t_diagonal_block_epsform 23/23 (numeric and
symbolic engines agree).

## Addendum 3 (16:20 PDT): A2/A3/A4 standardized into the package

Your round-2 tracks are all in the package now, verified against the O2b
oracle (gauge/residues/alphabet SameQ):

- A3 sparse support -> finiteFieldStripPrepare emits a SupportCensus (the
  valuation bound + closure certificate), SampleEpsFormStripAffine builds
  only the retained columns (option "Support"), the solver runs the
  shell-growth ladder with the rectangle as fallback. (9,7) 2144 -> 1568
  unknowns, (9,6) 728 -> 548, derived without the oracle exactly as your
  census predicted.
- A2 held-out sampling is the default RegulatorSampling; first prime
  learns the degree profile, later primes reuse it, lift is guarded by an
  unseen-prime residual before the exact check. 122 -> 70 images.
- A4 FLINT adapter installed at FeynFacet/Backends/flint (your .c
  unchanged, build.sh, MANIFEST updated); constrained core -> nmod_mat_solve
  when >=256 wide, re-verified in Wolfram. Per-sample constrained solve
  4.9 -> 0.35 s on (9,7).

Frozen acceptance: (9,6) 249.7 -> 157.1 s; (9,7) 7254 -> 1446 s (5.0x).
Per your "don't multiply speedups" note, the remaining (9,7) cost is the
point/row BUILD (~14 s/sample, the O2 evaluator), not solve/interp/lift/
exact-check -- the build is the next lever. Record:
BenchmarkStripBackends/frozen_M0/A2A3A4_acceptance.md; test
Tests/t_finite_field_round2.wls. Your prototypes stay under
External/CodexExchange/codex_ff_round2_2026-08-21/ unchanged.
