# Rationalized coefficient variables (rewrite item 4, option 1)

## Rev. 2 (2026-08-11): the trace is emitted in physical variables

Everything below rev. 1 is retained as the record of the step that
removed the `Cancel` wall.  It is superseded on one point: the root
variables must not reach the trace.

Measured reason (WORKLOG 2026-08-11, split race at gluon scale):
FireFly probes the black box in the variables it is handed, so
`x -> rx^2` doubles the effective degree in `x`.  The reconstructed
values are even in the root variables, but FireFly cannot know that;
gluon column 1 consumed ~12 core-hours at 587k probes without
converging, against ~63 s / 480k probes for the pre-rewrite
single-column probe that reconstructed in `{CA, CF, Epsilon, x, y}`
(Codex/ppHX_NNLO_DoubleReal/FiniteFieldReconstruction/
Overnight_2026-08-09).

Rev. 2 keeps the rev. 1 substitution as a *transient lift* and adds the
descend, ported from the 2026-08-08 study
(`Codex/Documentation/HadronicCoefficientSimplification_2026-08-08/
scripts/NNLOInvariantRootRing.wl`):

1. Per additive entry - never per output - lift with
   `finiteFieldRationalize`, divide the declared distribution and
   Laurent factors, `Cancel` (all as in rev. 1).
2. Descend each root family back to its invariant
   (`finiteFieldDescendEntries`).  An entry whose root powers are
   already even is restored structurally, with no rational algebra at
   all - the measured norm on NLO UU, TT and the NNLO ghost grid.  An
   entry that is not even is written `N = Ne + r No`,
   `D = De + r Do`; the branch flip `r -> -r` leaves `N/D` invariant
   exactly when `Ne Do - No De = 0`, and then `N/D = Ne/De`.  The
   `Cancel@Together` zero certification runs on that small combination
   only.  Entries that fail alone are merged by *exactly equal
   denominator* and retried, then as one remainder; a survivor is a
   labeled hard failure (`CoefficientSimplification::rootdescend`).
3. The declared scale and the strong coupling leave the trace through
   the existing signature mechanism, not through the rational part:
   each entry's degree in them is read off structurally with the card's
   `KinematicMassDimensions` (`coefficientMassDimension`), so the
   monomial is exact and the emitted rational part is scale-free.  An
   entry that is not homogeneous simply keeps the variable - the
   emission stays exact, only the variable count grows.
4. `finiteFieldAssembleResult` no longer collapses roots; it certifies
   that no root variable reached the reconstruction
   (`finiteFieldCertifyRootFree`, still reported through
   `CoefficientSimplification::rootparity`), and
   `HadronicNormalization["RootDescend"]` records which roots were
   eliminated, the achieved trace variables, the per-output scale
   powers and the descend telemetry.
5. Zero-content outputs are never written: an expression file exists
   only once a nonzero contribution reaches it.

Acceptance for rev. 2 is the rev. 1 ladder (items 1-4 below) plus the
NLO shared-vs-one-by-one comparison and a timed NNLO column subset;
the test is `Tests/Core/t_physical_variable_coefficients.wls` (renamed from
`t_rationalized_coefficients.wls`, assertion F now checks the descend
provenance and that no root variable is a trace variable).

## Decision (user, 2026-08-10)

Square-root substitution variables, confined to the finite-field
coefficient stage. Cards, `Distributions.wl`, collinear factorization,
reduction, and all stored artifacts are untouched.

## Why this deletes the wall

The blocker (WORKLOG 16:00): after hadronic substitution a master
coefficient contains half-integer powers of monomials in
{xa, xb, s, x, y}; the current PositiveMonomialRoots machinery lifts
fraction roots to root variables and then needs one giant
`Cancel[Together[...]]` of the multi-MB rational to make the result
root-free before it can go to the trace. That Cancel is the wall.

Under direct substitution the Cancel is not accelerated - it is
*removed*:

- Ratracer/FireFly evaluate the input expression modularly; the
  reconstruction is independent of whether the input was canceled.
  An uncanceled rational in substitution variables is a perfectly
  valid trace input.
- Root-freeness (evenness in each root variable) is a property of the
  *reconstructed* coefficients, which are small; verify it there, not
  on the megabyte inputs.
- Positivity certification collapses to bookkeeping: substituting
  xa = xia^2 with xia > 0 IS the positive branch that the card
  assumptions (0 < xa < 1, s > 0, x > 0, y > 0) select. No
  FullSimplify calls remain on the hot path.

## Substitution set

Applied AFTER hadronic substitution and the dimensionless map, at the
point where the current code root-lifts:

    xa -> xia^2,  xb -> xib^2,  zh only if roots of zh appear
    s  -> 2 sq^2          (the s/2 combinations of the frame vectors
                           then have rational square roots)
    x  -> rx^2,   y -> ry^2

with the general rewrite of half-integer powers
`base^(k/2) -> (rationalized base)^k` for every base that is a
monomial in the substituted quantities times an exact rational
constant. A leftover constant root (e.g. Sqrt[2] if a base carries an
odd power of 2) is exact and non-rational: route it through the
EXISTING signature mechanism (`finiteFieldSignatureModule` already
separates non-rational factors), never approximate or "simplify" it.
A base that is NOT such a monomial (polynomial in substituted
quantities under a root) is a hard, labeled failure - measurement on
NLO/TT/ghost data says it does not occur; if NNLO produces one, that
is a physics finding to surface, not to patch around.

## Implementation surface (all in Simplification.wl)

Replace, inside `finiteFieldPrepareReductionCoefficient` and
`finiteFieldNormalizeTarget`, the sequence
{validateCoefficientBranchGrammar -> coefficientPositiveRootLift ->
finiteFieldCancel -> finiteFieldCertifiedPowerExpand ->
root-free check} by:

1. `finiteFieldRationalize[expression, context]`: the substitution
   rewrite above; returns an expression rational in the extended
   variable set plus signature-safe constant roots. No Cancel, no
   TimeConstrained, no FullSimplify.
2. The declared Laurent/distribution factor handling is unchanged in
   meaning but divides in substitution variables (the declared
   valuation monomial rationalizes trivially).
3. The trace variables gain {xia, xib, sq, rx, ry, ...} as needed;
   `finiteFieldRationalQ` accepts them as ordinary symbols already.
4. Post-reconstruction check (`finiteFieldAssembleResult`): every
   reconstructed coefficient must be EVEN in each root variable;
   collapse xia^2 -> xa etc. back to the physical variables before the
   result is assembled, so the artifact format and all downstream
   consumers (assembly, golden tests) are unchanged. An odd power
   surviving reconstruction is a labeled hard failure.
5. `HadronicNormalization` in the result records the substitution set
   used ("RootSubstitutions").

The old grammar/lift machinery stays in place for
`SimplifyHardCoefficients` (public export, separate API decision) but
is no longer on the finite-field path.

## Acceptance (hard, exact)

1. NLO UU: `Tests/Reconstruction/t_nlo_coefficient_golden.wls` passes UNCHANGED -
   the new path must reproduce the stored reference CoefficientResult
   exactly (identical masters, exact coefficient equality).
2. TT: fresh coefficient run over `TT_08_10_1` equals the stored
   2026-08-10 TT baseline CoefficientResult exactly (same comparison).
3. Ghost: fresh run over `UU_Ghost_08_10_shared` equals its stored
   CoefficientResult exactly.
4. The full suite (10 tests) stays green.
5. Then, supervised: the NNLO gluon set (45k targets) - the run that
   the old path could not complete. Success criteria: completion,
   exact-data validation, 347 masters, and per-stage wall time
   recorded in WORKLOG.
