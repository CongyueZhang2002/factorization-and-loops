# Prototypes

Code that is **not loaded by the package** and has **no production
caller**, kept because a named future integration needs it and because
deleting it would lose a working implementation.

Created 2026-08-26 in the round-2 review wave, executing Codex review
§4.2 and ChatGPT Pro's conciseness list
(`Exchange/Codex/2026-08-25/11_merged_private_code_review.md`,
`Exchange/Codex/2026-08-25/10_pro_private_code_review.md`) as accepted in
`Exchange/Fable/2026-08-26/01_round1_review_disposition.md` (Stage 1,
item 5).

Rules for this directory:

- nothing here is loaded by `FeynFacet/FeynFacet.m`;
- a test that exercises a prototype `Get`s it explicitly, by a
  repository-relative path, after loading FeynFacet;
- a prototype earns promotion into `FeynFacet/Private/` only with a
  production caller and its own acceptance test — not by being useful in
  principle.

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
and by `Tests/Multiquadratic/t_multiquadratic_gauge_screen.wls` (criteria G6-G9), which
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
returns the raw exponentiation, and `Tests/Multiquadratic/t_multiquadratic_algebra_differential.wls`
holds the neutral algebra to it. `Tests/FiniteField/t_family_row_gauge_finite_field.wls`
is its own adversarial suite. Both now `Get` it from here.

Codex §4.2 asks that its useful modular evaluator be extracted into the
common coefficient provider; when that happens the remainder stays here
as the oracle the provider is differentially tested against.

## `MultiquadraticPerEntryChannels.wl`

Persistent characteristic-zero decomposition of a forcing tensor, one scalar
entry and checkpoint at a time. Each entry is decomposed in its active root
subfield and then lifted to the declared global grade basis; an optional exact
symbolic fallback is local to the failed entry.

It left `FeynFacet/Private/MultiquadraticStripSolve.wl` because it has no
production caller. The direct solver now samples the deferred DAG through
`SplitBranch`; `QuotientGrade` and `CompiledChannel` are its explicit
differential oracles. Keeping a fourth, unused production materializer made
the available paths look less settled than they are. A future consumer that
really needs persistent exact channel artifacts can load this prototype
explicitly and must add a focused acceptance test before promoting it again.
