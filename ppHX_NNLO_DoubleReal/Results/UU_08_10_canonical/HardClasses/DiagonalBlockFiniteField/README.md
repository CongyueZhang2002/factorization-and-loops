# Diagonal-block epsilon forms on the finite-field route (2026-08-21)

Production record for the migration of the finite-field technology to
the hard-class (irreducible diagonal block) stage-1 problem.  Module:
`FeynFacet/Private/DiagonalBlockEpsForm.wl` (driver `DiagonalBlockEpsForm`,
stages `DiagonalBlockSliceEpsForm` -> `SolveDiagonalBlockGaugeFiniteField`
-> `CompleteDiagonalBlockEpsForm` -> `CertifyDiagonalBlockEpsForm`).
Test: `Tests/EpsilonForm/t_diagonal_block_epsform.wls` (synthetic 2x2 block with a
known answer, 13/13).  Probe with oracle comparison against the certified
2026-08-16 forms: `Scripts/Diagnostics/diagonal_block_epsform_probe.wls <class> <dir>`.

## Why the off-diagonal affine solver could not be used directly

The diagonal-block equation  dT = A T - T (eps Sum_a R_a dlog phi_a)  is
bilinear in (T, R_a).  The off-diagonal sampler is affine only because
its diagonal epsilon forms are already known.

## The linearization (three exact steps, one slice)

1. **One spectator slice** (y = y0 rational, eps symbolic): Lee balances
   (Libra `GetSubspaces`/`Projector`/`Balance`, Poincare-rank-positive
   points raised first; when a rank-positive point has no singular
   partner the balance lowers at a regular point, Lee's Fuchsification)
   normalize the one-variable system; Lee's linear factor-out step
   (`M_i U = eps U N_i`) gives the slice epsilon form; its residues are
   the constant residues R_a of EVERY letter depending on x, in one
   frame.  Exact slice check; every locus mapped to a letter; apparent
   (regulator-dependent) loci must carry zero residue.
2. **The x-equation**  d_x T = A_x T - T B_x,  B_x = eps Sum_a R_a d_x log
   phi_a, is then a homogeneous LINEAR system for a rational T with
   pure-letter denominators.  Ansatz: T = N(x,y)/Prod phi_a^{m_a} with
   m_a from the integer parts of the local exponents of A at each letter
   (census, exact on all three classes) and numerator degrees from the
   denominator degree plus the growth at infinity (ladder when unknown).
   At fixed (y, eps) modulo a prime this is an ODE in x: 16 (n_x+1)
   unknowns (176 for class 79 instead of 1936 for the bivariate ansatz),
   a one-dimensional solution space (no spectator-polynomial slack),
   milliseconds per solve.  The spectator and regulator dependence are
   recovered by two nested univariate rational interpolations
   (`finiteFieldStripInterpolateCoordinate`), Chinese remaindering over
   primes and rational reconstruction; accepted only after the exact
   x-equation holds.
3. **Spectator completion, exact**: T^-1 A_y T - T^-1 d_y T minus the
   known letters is x-free and equals  eps Sum_b R_b dlog phi_b (pure-y
   letters) + (Sum_q k_q dlog q) 1  with integer k_q.  Trace and
   traceless parts are separated; the scalar part is read from partial
   fractions (q of any degree, regulator-dependent allowed -- class 79
   produced a quartic in y), the traceless residues at the pure-y letters.
   The scalar gauge c = Prod q^{k_q} completes T.

The only acceptance is the two-variable gate (`CertifyDiagonalBlockEpsForm`):
original system through T equals eps Sum_a R_a dlog phi_a entrywise in x
and y, constant residues, flat, invertible.

## Results (oracle = certified 2026-08-16 forms; one kernel)

| class | slice | FF solve (primes) | completion | gate | total | oracle |
|---|---|---|---|---|---|---|
| 79 | 62 s, 10 balances | 713 s (5) = 261 sampling + 447 interpolation + 3 lift | 5 s | 5 s | ~13 min | T_new = T_old . C (C constant, invertible); letters and residue spectra identical; LeafCount 6818 vs 12473 |
| 97 | 107 s, 8 balances | 129 s (5) = 99 + 28 + 1 | 1.5 s | 1.7 s | ~4 min | same three checks True; LeafCount 2733 vs 2653 |
| 77 | 934 s, 10 balances | 1533 s (11) = 609 + 914 + 4 | 6 s | 5 s | ~41 min | same three checks True; LeafCount 6926 vs 6905 |

All three on 2026-08-21 between 03:02 and 04:02 PDT, strictly one
kernel at a time.  Where the time goes now: the nested rational
interpolation (a degree ladder with one nullspace per candidate degree
pair, run for every coordinate, regulator value and prime) and, for
class 77, the coefficient heights of the normalized solution (11 primes;
the normalization coordinate's spectator polynomial carried 40-digit
coefficients).  Both are follow-ups, not obstacles: reuse the discovered
degree pairs across regulator values and primes; choose the
normalization coordinate with the smallest spectator degree.  The class
77 slice (934 s against 62 s for class 79 on the same 10-balance
length) is the Libra balance algebra with eps symbolic on a heavier
representative.

For comparison the 2026-08-16 route for class 79 was: slice search 224 s,
symbolic-y balance replay 53 min, factor-out by 18 symbolic samples +
~17 min naive rational interpolation, gate -- with the chart, the slice
point, the replay and the constant gauge driven by hand.  The new route
needs the chart and nothing else.

## Evidence files

`c<class>_slice.wl`, `c<class>_solve.wl`, `c<class>_completion.wl`,
`c<class>_certified.wl` (stage records; the certified record carries T,
letters, residues, EpsForm and the gate), `probe_c<class>.log`.
`probe_c79_bivariate_superseded.log`: the first (bivariate-ansatz)
attempt, 1936 unknowns and 10 min per prime, seven primes without a
successful lift -- kept as the measurement that motivated the ODE design.

## Lessons

- The oracle files `c*_epsform_two_variable.wl` store the GATED
  epsilon forms under "Ax"/"Ay", not the source system; the probe rebuilds
  the source from `BlockClasses/classes.wl` through the chart.
- `FirstPosition[letters, x]` matches the symbol x INSIDE `-1 + x`;
  index letters by identity at level 1.
- `Return` inside `Do`/`While` exits the loop only (same trap as in the
  strip solver); early exits use flags or `Catch`/`Throw`.
- Nested pure functions: `AllTrue[primes, f[#1, #2, #] &] &` binds every
  slot to the prime; use `Function[{a, b}, ...]`.
- Lee normalization needs integer spectra: a synthetic test with
  residues of irrational eigenvalues is not a valid test.
- **Protected symbol `C`** (caught by the Opus watchdog from the
  `Set::wrsym` line in the probe logs, 2026-08-21 04:10): the probe and
  the test assigned the conjugator to `C`, so the "T_new = T_old . C
  constant" line in `probe_c*.log` was VACUOUS (the letter/spectrum
  checks and the gate were not affected).  Re-run with a plain symbol
  (`Scripts/Diagnostics/diagonal_block_epsform_oracle.wls`, stored certified
  records): all three conjugators are free of x and y and invertible —
  class 79 a scalar function of eps, class 97 a constant matrix times
  1/eps, class 77 a constant rational matrix.  Test re-run 13/13 with
  the real check.  Lesson: never assign to single capital letters
  (`C`, `D`, `E`, `I`, `K`, `N`, `O`) in Wolfram scripts.

## Standardized, automated stage-1 engine (2026-08-21, 09:00-12:10 PDT)

After the user's request ("after test-based performance, standardize and
automate at your best"), the route became a complete stage-1 engine:
`DiagonalBlockEpsForm[{Av, Aw}, {v, w}, eps]` now takes the RAW class
representative and does everything itself, and
`DiagonalBlockClassCampaign[classes, dir]` runs the class ledger in the
`CanonicalizeClasses` record schema (pool of subkernels, optional
CANONICA fallback, optional `ValidateCanonicalForm` re-check).

What the driver does, in order (all exact, the two-variable gate is the
only acceptance):
1. zero block -> identity; 1x1 block -> direct dlog read-off (`ScalarDLog`;
   the coefficient along a curve q = 0 is computed modulo q, so letters
   quadratic in both variables are fine);
2. frame ladder: slice in v, slice in w, then SHEARED frames (u, s) with
   w = s + lambda u, lambda in {1,-1,2,-2,3}, accepted whenever every
   letter is linear in the slice variable after the shear -- a shear
   along a root direction of a letter's quadratic part linearizes it
   (class 23: w -> s - v linearizes v - w + v w + w^2), and along a
   generic line an irreducible connection keeps its monodromy, so the
   x-equation has a one-dimensional solution space even when a coordinate
   slice is reducible (class 9: A_v proportional to 1);
3. per frame: Lee slice (fast failure `ExponentsNotInteger` when an
   exponent has a half-integer part -- the signal for a chart; regular-
   point balances for Fuchsification AND normalization when no singular
   partner exists; stall guard), FF ODE solve (`SolutionSpaceDegenerate`
   is a verdict, not a ladder step), exact completion, gate in the
   ORIGINAL variables (sheared frames are mapped back);
4. chart retry (the CanonicalBlocks rule: exactly one irreducible
   quadratic among the poles): both signs of the conic (`q = t^2` and
   `-q = t^2`, `canonicalBlocksBuildChart`) and the matching catalog
   charts (`TransportChartCatalog`: Kallen1/2/3, Q4a/b, Bilinear115),
   ordered by "pulled-back alphabet linear in a variable" -- class 115
   needs `1 - 4 v w = t^2`, not `4 v w - 1 = t^2`; the record then
   carries the chart as the ledger does.
5. interpolation degrees are learned once and reused across regulator
   values and primes (one nullspace per coordinate instead of a ladder).

### Engine benchmark, identical inputs (ledger frame), 1 main + 4 subkernels, BEFORE the standardization fixes

| dim | classes | CANONICA certified | CANONICA total s (median) | FF certified | FF total s (median) |
|---|---|---|---|---|---|
| 1 | 90 | 87 | 1.4 (0.01) | 86 | 17.5 (0.19) |
| 2 | 71 | 70 | 319.3 (1.66) | 54 | 164.0 (1.24) |
| 3 | 6 | 4 | 1872.8 (28.0) | 6 | 208.7 (13.2) |
| 4 | 3 | 2 | 931.9 (23.3) | 3 | 125.7 (21.2) |

Totals over the 170 common classes (hard classes 77/79/97 excluded):
CANONICA 3125 s, 163/170 (refuses 16/68/84/115 in under a second; caps
out at 3x300 s on 26/33/118); finite field 516 s, 149/170 at that point
(21 instant failures: 13 reducible slice directions, 7 normalization
stalls, 1 scalar with a bi-quadratic letter).  Those 21 are the defects
fixed by items 1-4 above; every one of them certifies now (retry log in
`EngineBenchmark/retry/`).  `Scripts/Diagnostics/benchmark_diagonal_block_engines.wls`,
`Scripts/Diagnostics/summarize_engine_benchmark.wls`, records in `EngineBenchmark/`.

### Final automatic campaign, all 173 classes from the raw (v,w) representatives

`Scripts/Diagnostics/diagonal_block_class_campaign.wls`, 1 main + 4 subkernels, no
ledger hints, no fallback: **173/173 certified** (172 in 1843 s wall;
class 77 alone afterwards with a 2 h cap: 2950 s = slice 1547 + solve
1378 + gate 12).  Methods: 89 `ScalarDLog`, 83 `SliceResiduesFiniteFieldAffine`,
1 `ZeroBlock`; frames: 58 plain slices, 1 shear, 24 automatic charts.
Per dimension: dim 1 90 classes in < 1 s total; dim 2 71 classes 167 s
(max 12 s); dim 3 6 classes 117 s (max 54 s); dim 4 6 classes 1030 s +
2950 s.  Every record also passes `ValidateCanonicalForm`.

Oracle against the 2026-08 ledger (`Scripts/Diagnostics/diagonal_block_class_oracle.wls`):
170/172 per-letter residue spectra identical and T_ledger^-1 T_new a
constant invertible matrix on all 169 classes with the same variables;
the two "mismatches" (79, 97, and 77 once rerun) are chart artifacts --
the driver picked the conic t-chart, the ledger the Kallen (x,y) chart.
`Scripts/Diagnostics/diagonal_block_cross_chart_oracle.wls` solves the root
identity for t(x,y) (t = x - 1 or 1 - y), pulls the new forms back to
(x,y) and finds letters and spectra IDENTICAL to the ledger for all
three.  Records: `ClassFormsFF/` (173 ledger-schema records,
`campaign_summary.wl`, logs).

### Remaining cost and follow-ups

- The Libra slice with eps symbolic is now the dominant cost on the
  hard classes (class 77: 1547 of 2950 s).  Idea: run the balance SEARCH
  modulo a prime at numeric regulator values (two values separate the
  a + b eps eigenvalue structure) and replay the recorded path once.
- Class 77 still needs 11 primes (normalization coordinate heights).
- Per-class time caps: the campaign default is 1800 s; the hard classes
  need up to 3000 s in this topology.
- Genuinely reducible blocks (all residues commuting) have no frame with
  a one-dimensional solution space; they are reported `NotCertified`
  and should be split, or handed to the CANONICA fallback.
- Test: `Tests/EpsilonForm/t_diagonal_block_epsform.wls` 20/20 (synthetic KZ block,
  zero block, scalar block with a bi-quadratic letter, reducible slice
  direction solved in another frame).

## NumericalEps slice engine (eps specialized to 1/101, exact over Q(x)) + canonical residue frame (2026-08-21, 13:00-15:30 PDT)

The Libra slice with eps symbolic was the last big cost (class 77:
1547 s).  Two observations remove it (`DiagonalBlockSliceEpsForm`,
option `"Engine" -> "NumericalEps"`, the default; `"Symbolic"` keeps the old
engine; `Tests/EpsilonForm/t_diagonal_block_epsform.wls` checks both agree):

1. **The slice only has to deliver the residue tuple up to one constant
   conjugation.**  Two normalized Fuchsian forms of the same
   one-variable system at a fixed generic regulator value e differ by a
   rational gauge with no integer exponent shifts, i.e. a constant
   matrix.  So the whole Lee chain runs at eps = e = 1/101 in Q(x): the
   integer part of an exponent a + b e is Round[lambda], the eps part
   (lambda - a)/e (half-integers show up as non-integers and trigger the
   chart retry immediately); Lee's factor-out step is unnecessary
   (R_a = M_a(e)/e); Libra's conventions were read from its source
   (Left/raise = column eigenvectors with negative integer part, Right/
   lower = row eigenvectors with positive integer part, P = u^T (v u^T)^-1
   v, Balance = I - P + P (x-x2)/(x-x1)); Poincare-rank-positive points
   still use Libra's `GetSubspaces`, whose rank-positive branch never
   touches the regulator.  Measured: class 79 slice 62 s -> 1.5 s, class
   77 1547 s -> 1.8 s (13-14 balances).
2. **The frame must be canonicalized, or the heights explode.**  The
   numeric chain leaves powers of 101 in the residues (100-200 digit
   entries), T inherits them, and the solve needed > 20 primes (class 77
   failed the conic chart).  `diagonalBlockCanonicalFrame` conjugates
   the tuple into the frame spanned by eigenvectors of SIMPLE eigenvalues
   of the residues (canonical up to scale; echelon bases of
   multi-dimensional eigenspaces only as filler -- they are not frame-
   covariant and were measured to make things worse) and fixes the
   scales by a spanning tree of nonzero entries.  Result: integer
   residue matrices with 1-2 digit entries for all three hard classes
   (e.g. class 79: R_x = {{1,1,0,1},{0,-2,0,0},{0,0,-2,0},{0,0,0,-2}}),
   and the solve lifts after 2 primes.

**Final campaign, 173 classes from the raw (v,w) representatives, 1
main + 4 subkernels: 173/173 certified in 204.5 s wall** (dim 1: 90
classes < 1 s; dim 2: 71 classes 130 s, max 6.4 s; dim 3: 6 classes 43
s, max 14.5 s; dim 4: 6 classes 388 s, max 180 s = class 77), versus
1843 s + 2950 s with the symbolic slice this morning and 3125 s for
CANONICA's 163/170 on the easy classes alone.  Oracle: spectra identical
and constant conjugation on all 170 same-variable classes; the three
hard classes identical to the Kallen-chart ledger after the cross-chart
pullback (`diagonal_block_cross_chart_oracle`: MATCH True, both root
signs).  Records: `ClassFormsFF_numeric/` (173 records, logs).  Test
23/23.

Note on process: a 20-minute "loop" I reported during this work was a
misread of a silent finite-field solve (the campaign log only shows
Libra's chatter from the slice); the killed run was healthy.
