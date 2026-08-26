# Prototypes

Code that is **not loaded by the package** and has **no production
caller**, kept because a named future integration needs it and because
deleting it would lose a working implementation.

Created 2026-08-26 in the round-2 review wave, executing Codex review
§4.2 and ChatGPT Pro's conciseness list
(`External/CodexExchange/codex_merged_fable_code_review_2026-08-25.md`,
`.../chatgpt_pro_fable_code_review_2026-08-25.md`) as accepted in
`.../fable_disposition_review_round1_2026-08-26.md` (Stage 1, item 5).

Rules for this directory:

- nothing here is loaded by `FeynFacet/FeynFacet.m`;
- a test that exercises a prototype `Get`s it explicitly, by a
  repository-relative path, after loading FeynFacet;
- a prototype earns promotion into `FeynFacet/Private/` only with a
  production caller and its own acceptance test — not by being useful in
  principle.

## `MultiquadraticInstallableSolution.wl`

A pure, fail-closed adapter from the already reconstructed generic
multiquadratic gauge plus active-support potential certificate to the existing
row-gauge solution ABI (`Gauge`, `Alphabet`, `ResidueMatrices`).  It accepts
either an exact channel residual or fresh provider-backed checks at two unseen
primes and three disjoint images per prime.  It performs no solve and is not a
production speed path; its purpose is to make the remaining installation seam
explicit before the provider-backed sampler API settles.  The acceptance and
refusal cases are in
`Tests/t_multiquadratic_installable_solution_prototype.wls`.

## `MultiquadraticMixedGradeLetters.wl`

Witness-guided mixed-grade letter discovery for the multiquadratic
alphabet: rational parameterization of each polar-census curve, exact
splitting analysis of the grade squares on that curve, the full Galois
norm of a mixed-grade candidate, and the norm-in-alphabet filter.

Extracted verbatim from `FeynFacet/Private/MultiquadraticStripSolve.wl`
(the block that stood at lines 3052-3389 of the `f3738b1` snapshot).
Five symbols move with it: `multiquadraticStripCurveParameterization`,
`multiquadraticStripRationalFunctionSquareRoot`,
`multiquadraticStripGradeSquare`, `multiquadraticStripGradeNorm`,
`multiquadraticStripMixedGradeLetters`. They are used only by each other
and by `Tests/t_multiquadratic_gauge_screen.wls` (criteria G6-G9), which
now loads this file.

**Why it is not production.** The production candidate builder
(`multiquadraticStripCandidateLetters`) emits single-root principal
letters `A ± Sqrt[delta]` only. This generator was written to answer
Codex's Q3 but was never wired in, and Codex §3.2 states the
generalization that must replace it first: reduce a degree-bounded
candidate modulo the ideal `(f, r_i^2 - delta_i)` instead of requiring a
rational parameterization of every divisor curve, impose vanishing at
one prime above `f`, keep candidates whose norm is supported on the
admitted polar set, and group by Galois orbit. That work is round 3
(divisor/Newton-polytope support census), after the coefficient-provider
interfaces are fixed.

It still depends on the package for
`multiquadraticStripPolynomialSquareRoot`,
`multiquadraticStripRationalSquareQ`,
`multiquadraticStripNormInAlphabetQ`,
`multiquadraticStripProductionOptionGate` and
`multiquadraticStripFailure`, so it is loaded inside
`FeynFacet`Private`` and is not standalone.

## `FamilyRowGaugeFiniteField.wl`

The isolated finite-field row-gauge oracle: its own canonical root
order, all `2^r` sign branches, a tagged modular evaluator, and
sparse-support statistics. Moved from `FeynFacet/Private/`, where it sat
without being listed in the package's file list — it was never loaded by
`FeynFacet.m`.

Its remaining value is as a **differential oracle**: it normalizes the
modular square-root sign representative where `MultiquadraticAlgebra.wl`
returns the raw exponentiation, and `Tests/t_multiquadratic_algebra_differential.wls`
holds the neutral algebra to it. `Tests/t_family_row_gauge_finite_field.wls`
is its own adversarial suite. Both now `Get` it from here.

Codex §4.2 asks that its useful modular evaluator be extracted into the
common coefficient provider; when that happens the remainder stays here
as the oracle the provider is differentially tested against.
