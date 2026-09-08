# CF300 (12,9): witness-guided letter discovery and the numerator degree, 2026-08-25

Method record and measured verdict for the second half of Codex's Q3
recipe (`Exchange/Fable/2026-08-24/01_cf300_12_9_state_and_reply/`).
Everything here is a MEASUREMENT; nothing is a proof of impossibility
beyond the stated bounds.

## HEADLINE (read this first)

**The obstruction is REPAIRED, and it was not a missing letter.**
With the alphabet and the merged gauge denominator both unchanged, and
the gauge NUMERATOR degree raised to three above the denominator degree
(`"DegreeOffset" -> {3, 3}`, support 169, 2920 unknowns), the complete
affine gauge system of CF300 (12,9) is **CONSISTENT (defect 0) at two
independent images**. The measured ladder:

| DegreeOffset | numerator degrees | support | unknowns | image 1 | image 2 | verdict |
|---|---|---|---|---|---|---|
| {0,0} | {9,9} | 100 | 1816 | defect 1 | defect 1 | obstruction |
| {1,1} | {10,10} | 121 | 2152 | defect 1 | - | obstruction |
| {2,0} | {11,9} | 120 | 2136 | defect 1 | defect 1 | obstruction |
| {0,2} | {9,11} | 120 | 2136 | defect 1 | defect 1 | obstruction |
| {2,2} | {11,11} | 144 | 2520 | defect 1 | defect 1 | obstruction |
| **{3,3}** | **{12,12}** | **169** | **2920** | **defect 0** | **defect 0** | **CONSISTENT** |
| {5,5} | {14,14} | 225 | 3816 | defect 0 | - | consistent |

Primes 2147483423 / 2147483399, eps 1/13 and 3/17. The nullity is 104 at
every row of that table, so the added numerator directions add rank
one-for-one and the repair is not an artifact of over-parameterization;
at {3,3} there are 2976 rows against rank 2816, i.e. 160 independent
left-null directions available to expose an inconsistency, and none
does. **{3,3} is minimal**: the offset is needed in BOTH variables
(neither {2,0} nor {0,2} helps) and {2,2} is still inconsistent.

Interpretation: the gauge carries a pole AT INFINITY of order three -
its numerator degree exceeds its denominator degree - which Codex's Q2
lists explicitly among the pole sources a letter-norm denominator family
cannot produce.

### Why the earlier "support growth is useless" reading was wrong

The 2026-08-25 census enlargement (`../gauge_screen_2026-08-25/`) grew
the DENOMINATOR to degrees {13,12} and kept the support rectangular at
the denominator degree. That is a DIFFERENT function space, not a
superset: writing `x^p y^q r_g / Q_merged` over
`Q_enlarged = Q_merged R` (with `deg R = (4,3)`) needs numerator degree
up to `(p+4, q+3)`, well outside the enlarged rectangle. Raising the
denominator and raising the numerator above the denominator are
independent moves, and only the second one repairs this block.

### What this means for the campaign

Run this block with `"DegreeOffset" -> {3, 3}` (or `{4,4}` for margin);
alphabet and denominator stay as they are. The compile cost is driven by
the ALPHABET (54 letters), not by the support, so the extra 1104
unknowns cost only assembly and modular solve time, not compile time.
The gauge screen at that ansatz costs 87 s per image.

## What was already established (2026-08-25, `../gauge_screen_2026-08-25/`)

* The residue-only integrability screen is CONSISTENT for this block
  (defect 0, diagonal connections measured flat), so the alphabet can
  carry the residues.
* The FULL affine gauge system nevertheless carries a stable defect 1
  (nullity 104) at two independent images, both under the corrected
  merged denominator (degrees {9,9}, support 100, 1816 unknowns) and
  under the complete polar census at full multiplicity (degrees {13,12},
  support 182, 3128 unknowns).
* Therefore denominator and support growth are measured useless, and the
  missing object is a LETTER or something outside the ansatz entirely.

## What was measured here

Engine additions used (`FeynFacet/Private/MultiquadraticStripSolve.wl`):
`multiquadraticStripGaugeAnsatz`, `multiquadraticStripGaugeScreen`,
`multiquadraticStripGaugeScreenImages`,
`multiquadraticStripMixedGradeLetters`.

### 1. The gauge screen, promoted into the engine

Reproduced the measured obstruction from the prepared ansatz with no
symbolic compile: matrix {1856, 1816}, rank 1712, augmented rank 1713,
**defect 1**, nullity 104, **left nullity 144**, 58 accepted points,
49-51 s per image at prime 2147483423, eps = 1/13. The left witness `w`
verifies exactly: `A^T w = 0 (mod p)` and `b . w = 852991654 != 0`,
support 1713 of 1856 rows.

### 2. Decomposition data of the polar divisor (exact, symbolic)

Each rational polar factor is parameterized and every grade square is
tested for being a square in the residue field:

| factor | verdict | split grades | ramified grades |
|---|---|---|---|
| `x` | Split (COMPLETELY) | {0,1,2,3} | none |
| `y` | Split (COMPLETELY) | {0,1,2,3} | none |
| `-1+x` | Inert | {0} | - |
| `1+x` | Inert | {0} | - |
| `-1+x+y` | Split in the `Sqrt[1-4xy]` subfield | {0,2} | none |
| `1+x+y` | Split in the `Sqrt[1-4xy]` subfield | {0,2} | none |
| `-1+4xy` | Ramified (branch divisor of `r2`) | {0,2,3} | {2,3} |
| `1-2x+x^2+2y+2xy+y^2` | not linear in either variable | - | - |

The last one is the branch divisor of `r1` (it is the root square
itself, and equals `(1+x+y)^2 - 4x`); it is ramified rather than split,
and its letter is `r1`, whose dlog `dlog(delta_1)/2` is already in the
alphabet. So the affine polar divisor is fully accounted for.

This table is consistent with the four repair letters found in the
2026-08-24 post-mortem: their norms are `-4y`, `-4xy`, `4y(1+x+y)` and
`4x^2y^2`, whose irreducible factors are exactly `x`, `y`, `1+x+y` -
every one of them a factor marked Split. No repair norm touches either
factor marked Inert.

### 3. Mixed-grade potentials, solved exactly and linearly

For each split factor the condition "P = Sum_g P_g(x,y) r_g vanishes at
one prime above it" is a LINEAR system in the coefficients of the P_g
(substitute the square roots for the split roots on the parameterized
curve, keep the others symbolic, reduce `r_a^2 -> delta_a`, demand every
surviving coefficient vanish identically along the curve). The exact
solution space is computed, extended by the deterministic +-1
combinations of pairs of basis vectors, and filtered by the full Galois
norm factoring into the polar census - the same certificate the
single-root algebraic letters carry.

Bounds actually run: coefficient degree **0 to 3** per grade component,
**8 census factors** (the channel-denominator census UNION the strip's
own polar alphabet), pair combinations, 40 solutions per prime.
**980 solution-space points were tested**; 434 were rejected as trivial
(divisible by the factor, or single-grade with an alphabet-factorizable
coefficient); **29 mixed-grade letters** passed the norm certificate, of
which **19 were one-forms not already textually present in the 54-letter
alphabet**.

### 4. Witness scoring - the measured NEGATIVE

All 19 were offered to the same gauge-system assembly as candidate
residue columns and scored in one pass:

* **0 of 19 pierce the witness** (`w . C_k = 0` for every candidate).
* **0 of 19 carry a new column direction**: every candidate's
  `RankContribution` is **0**, i.e. `rank([A | C_k]) = rank(A)`.
* **0 of 172 subsets** (all 171 pairs, plus the full 19-element set)
  reach defect 0. The defect stays 1 with all 19 added at once.

The rank-contribution measurement is the substantive one, and it says
more than the failure to repair. It means every mixed-grade letter this
construction produces has a dlog that already lies in the LINEAR SPAN of
the 54 one-forms the alphabet has. Over the measured polar divisor and
up to coefficient degree 3, **the alphabet is closed**: the construction
generates no new logarithmic direction at all, so it cannot repair
anything, and the negative is not a near miss.

## Verdict, with its exact bounds

MEASURED NEGATIVE. No mixed-grade potential
`P = P0 + P1 r1 + P2 r2 + P12 r1 r2` with grade components of degree at
most 3, whose full Galois norm factors into the 8-factor polar census of
this block, yields a one-form outside the span of the current 54-letter
alphabet - let alone one that repairs the gauge defect. The obstruction
at CF300 (12,9) is therefore NOT a missing mixed-grade letter over the
affine polar divisor.

### How the letter negative and the numerator-degree repair fit together

They agree. The letter search says the alphabet's logarithmic span is
already closed over the affine polar divisor, so nothing was missing
there; the numerator-degree scan then finds the missing directions in
the GAUGE function space instead, at infinity. The screen measures the
ANSATZ, not the alphabet alone - that is exactly why its typed
obstruction carries an ansatz descriptor, and criterion G4 of
`Tests/t_multiquadratic_gauge_screen.wls` is the controlled version of
the same distinction on a synthetic block.

The letter negative still stands with its stated bounds, and it is what
made the numerator-degree hypothesis worth spending an image on.

## What the letter negative does not cover

1. **Coefficient degree above 3**, and combinations of more than two
   basis vectors of a solution space.
2. **Divisors outside the measured polar census** - a letter whose norm
   carries an irreducible factor that no channel denominator, `E`, `C`
   or root square exhibits.
3. Letters whose polar divisor lies at infinity rather than in the
   affine plane.

## What the numerator-degree repair does not yet establish

The gauge screen measures the affine system at sampled points at two
images. Consistency there is a strong necessary condition for the full
route, not the certificate. Still to run at `"DegreeOffset" -> {3,3}`:
the compile, the modular solve, the held-out prime, the branch
certificate and the exact channel residual - i.e. the ordinary
`solveEpsFormStripMultiquadratic` path, which will now no longer be
gated off by the screen.

## Files

* `cf300_129_discovery.wls` / `.log` / `_result.wl` - the
  witness-guided mixed-grade letter discovery: driver, full output with
  per-candidate scores, and the record (ansatz, census factors,
  decomposition table, candidate letters with norms, image-1 measurement
  with all candidate scores and subset defects).
* `cf300_129_numerator_degree.wls` / `.log` / `_result.wl` - the
  numerator-degree ladder confirmed at two images, and
  `_scan.log` - the first scan ({1,1}, {3,3}, {5,5}) at one image.
* `../gauge_screen_2026-08-25/channelForcing.wl`,
  `denominator_census.wl`, `census_factors.txt` - the measured channel
  decomposition these runs read instead of re-preparing the block.

## Cost

Letters 126-136 s; mixed-grade generator 14 s; one screened image 51 s
at 1816 unknowns, 87 s at 2920, 149 s at 3816. The letter discovery is
about 3.5 minutes end to end and the numerator-degree ladder about 11
minutes, against the ~7900 s compile of a single ansatz that they screen.
